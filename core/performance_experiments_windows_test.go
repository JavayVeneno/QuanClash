//go:build windows && !cgo

package main

import (
	"bytes"
	"crypto/sha256"
	"debug/buildinfo"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"sync"
	"testing"
	"time"
)

type experimentSnapshot struct {
	Bytes int `json:"encoded_bytes"`
	TCP   int `json:"tcp_connections"`
	UDP   int `json:"udp_connections"`
}

func decodeExperimentSnapshot(value any) (experimentSnapshot, error) {
	text, ok := value.(string)
	if !ok {
		return experimentSnapshot{}, fmt.Errorf("connection snapshot is not a string")
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal([]byte(text), &fields); err != nil {
		return experimentSnapshot{}, fmt.Errorf("invalid connection snapshot: %w", err)
	}
	encoded, present := fields["connections"]
	if !present {
		return experimentSnapshot{}, fmt.Errorf("connection snapshot lacks connections")
	}
	var connections []struct {
		ID       string `json:"id"`
		Metadata struct {
			Network string `json:"network"`
		} `json:"metadata"`
	}
	if err := json.Unmarshal(encoded, &connections); err != nil {
		return experimentSnapshot{}, err
	}
	result := experimentSnapshot{Bytes: len(text)}
	ids := make(map[string]bool, len(connections))
	for _, connection := range connections {
		if connection.ID == "" || ids[connection.ID] {
			return result, fmt.Errorf("missing or duplicate connection id")
		}
		ids[connection.ID] = true
		switch connection.Metadata.Network {
		case "tcp":
			result.TCP++
		case "udp":
			result.UDP++
		default:
			return result, fmt.Errorf("unverified connection network")
		}
	}
	return result, nil
}

func (ipc *baselineIPC) snapshot() (experimentSnapshot, error) {
	value, err := ipc.call(getConnectionsMethod, nil)
	if err != nil {
		return experimentSnapshot{}, err
	}
	return decodeExperimentSnapshot(value)
}

type experimentPolls struct {
	Count      int     `json:"successful_polls"`
	TotalBytes uint64  `json:"total_encoded_bytes"`
	MaxBytes   int     `json:"max_encoded_bytes"`
	P50Ms      float64 `json:"snapshot_rtt_p50_ms"`
	P95Ms      float64 `json:"snapshot_rtt_p95_ms"`
	IntervalMs float64 `json:"delay_after_response_ms"`
}

// Completion-relative polling matches ConnectionsView's one-second delay.
// It never overlaps requests, and stop waits for the in-flight read to finish.
func startExperimentPoller(interval time.Duration, read func() (experimentSnapshot, error)) func() (experimentPolls, error) {
	stop := make(chan struct{})
	finished := make(chan struct{})
	var once sync.Once
	var result experimentPolls
	var failure error
	go func() {
		defer close(finished)
		result.IntervalMs = float64(interval) / float64(time.Millisecond)
		latencies := newBaselineLatencies()
		defer func() {
			sort.Float64s(latencies.values)
			result.P50Ms = baselinePercentile(latencies.values, .5)
			result.P95Ms = baselinePercentile(latencies.values, .95)
		}()
		if interval <= 0 {
			failure = fmt.Errorf("invalid polling interval")
			return
		}
		for {
			select {
			case <-stop:
				return
			default:
			}
			start := time.Now()
			snapshot, err := read()
			if err != nil {
				failure = err
				return
			}
			latencies.add(time.Since(start))
			result.Count++
			result.TotalBytes += uint64(snapshot.Bytes)
			if snapshot.Bytes > result.MaxBytes {
				result.MaxBytes = snapshot.Bytes
			}
			timer := time.NewTimer(interval)
			select {
			case <-stop:
				timer.Stop()
				return
			case <-timer.C:
			}
		}
	}()
	return func() (experimentPolls, error) {
		once.Do(func() { close(stop) })
		<-finished
		return result, failure
	}
}

type experimentStage struct {
	Pair            int                `json:"pair,omitempty"`
	Order           int                `json:"order,omitempty"`
	Cycle           int                `json:"cycle,omitempty"`
	QuietSeconds    int                `json:"quiet_seconds,omitempty"`
	Inspection      bool               `json:"inspection_enabled"`
	Metrics         baselineStage      `json:"metrics"`
	Snapshot        experimentSnapshot `json:"snapshot_after_stage"`
	Polls           experimentPolls    `json:"polls"`
	UpstreamQueries uint64             `json:"upstream_queries_in_load,omitempty"`
}

type experimentReport struct {
	SchemaVersion   int               `json:"schema_version"`
	Experiment      string            `json:"experiment"`
	RecordedAt      string            `json:"recorded_at"`
	Platform        string            `json:"platform"`
	HostProcessor   string            `json:"host_processor"`
	LogicalCPUs     int               `json:"logical_cpus"`
	HarnessGo       string            `json:"harness_go_version"`
	CoreSHA256      string            `json:"core_sha256"`
	CoreBuildInfo   any               `json:"core_build_info"`
	WrapperRevision string            `json:"wrapper_revision_at_measurement"`
	WrapperDirty    bool              `json:"wrapper_dirty_at_measurement"`
	MihomoRevision  string            `json:"mihomo_revision_at_measurement"`
	MihomoDirty     bool              `json:"mihomo_dirty_at_measurement"`
	ConfigTemplate  string            `json:"config_template"`
	Parameters      map[string]any    `json:"parameters"`
	Limitations     []string          `json:"limitations"`
	Stages          []experimentStage `json:"stages"`
}

func prepareExperiment(t *testing.T, name string) (string, string, experimentReport) {
	t.Helper()
	if os.Getenv("QUANCLASH_PERF_EXPERIMENTS") != "1" {
		t.Skip("opt-in: set QUANCLASH_PERF_EXPERIMENTS=1, QUANCLASH_CORE_PERF and QUANCLASH_PERF_REPORT_PREFIX")
	}
	corePath, prefix := os.Getenv("QUANCLASH_CORE_PERF"), os.Getenv("QUANCLASH_PERF_REPORT_PREFIX")
	if corePath == "" || prefix == "" {
		t.Fatal("experiment core and new report prefix are required")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	output := prefix + "-" + name + ".json"
	if _, err := os.Stat(output); err == nil || !os.IsNotExist(err) {
		t.Fatal("report exists or cannot be inspected; choose a new prefix")
	}
	file, err := os.Open(corePath)
	if err != nil {
		t.Fatal(err)
	}
	hash := sha256.New()
	_, hashErr := io.Copy(hash, file)
	closeErr := file.Close()
	if hashErr != nil || closeErr != nil {
		t.Fatalf("hash artifact: %v / %v", hashErr, closeErr)
	}
	buildInfo, err := buildinfo.ReadFile(corePath)
	if err != nil {
		t.Fatal(err)
	}
	gitValue := func(args ...string) string {
		t.Helper()
		value, err := exec.Command("git", args...).Output()
		if err != nil {
			t.Fatal(err)
		}
		return string(bytes.TrimSpace(value))
	}
	report := experimentReport{
		SchemaVersion: 1, Experiment: name, RecordedAt: time.Now().UTC().Format(time.RFC3339),
		Platform: runtime.GOOS + "/" + runtime.GOARCH, HostProcessor: os.Getenv("PROCESSOR_IDENTIFIER"),
		LogicalCPUs: runtime.NumCPU(), HarnessGo: runtime.Version(), CoreSHA256: hex.EncodeToString(hash.Sum(nil)),
		CoreBuildInfo: buildInfo, ConfigTemplate: baselineConfig, Parameters: make(map[string]any),
		WrapperRevision: gitValue("rev-parse", "HEAD"), WrapperDirty: gitValue("status", "--porcelain") != "",
		MihomoRevision: gitValue("-C", "Clash.Meta", "rev-parse", "HEAD"), MihomoDirty: gitValue("-C", "Clash.Meta", "status", "--porcelain") != "",
		Limitations: []string{
			"Loopback DIRECT forwarding only; no system proxy/DNS/routes/TUN/helper or other-process changes.",
			"Child OS CPU/RSS only; harness, echo servers, Flutter and actual GUI decode/layout excluded.",
			"Working-set samples are not live heap; no GC forcing, cache flush or connection close action.",
			"Host background load remains uncontrolled; result is exploratory, not an optimization claim.",
			"A finite retention test cannot prove long-run bounded memory or absence of leaks.",
		},
	}
	return corePath, output, report
}

func writeExperiment(t *testing.T, path string, report experimentReport) {
	t.Helper()
	if t.Failed() {
		t.Fatal("refusing a successful report for failed stages")
	}
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		t.Fatal(err)
	}
	_, writeErr := file.Write(append(data, '\n'))
	closeErr := file.Close()
	if writeErr != nil || closeErr != nil {
		t.Fatalf("write report: %v / %v", writeErr, closeErr)
	}
	t.Logf("complete report: %s", path)
}

func experimentChild(t *testing.T, corePath string) (*baselineIPC, func() (baselineProcessSample, error), string, string, string, string, func() uint64) {
	t.Helper()
	tcp, udp := baselineEchoServers(t)
	upstream, count := baselineDNSUpstream(t)
	proxyAddress, dnsAddress := unusedSmokeTCPAddress(t), unusedSmokeTCPAddress(t)
	_, port, _ := net.SplitHostPort(proxyAddress)
	ipc, sample := startBaselineCore(t, corePath, fmt.Sprintf(baselineConfig, port, dnsAddress, upstream, upstream))
	return ipc, sample, proxyAddress, dnsAddress, tcp, udp, func() uint64 { return count.Load() }
}

func TestDesktopCoreInspectionExperiment(t *testing.T) {
	corePath, output, report := prepareExperiment(t, "inspection")
	report.Parameters = map[string]any{
		"pairs": 3, "tracked_tcp_connections": 128, "foreground_payload_bytes": 65536,
		"stage_seconds": 8, "warmup_seconds": 1, "poll_delay_after_response_ms": 1000,
		"workload_concurrency": 1, "order": "off/on, on/off, off/on; fresh child each stage",
	}
	report.Limitations = append(report.Limitations,
		"128 established connections, one foreground worker; not a concurrent saturation workload.",
		"Core snapshot IPC/JSON measured, not Dart model decoding or widget rendering.")
	for pair := 1; pair <= 3; pair++ {
		for order := 1; order <= 2; order++ {
			inspection := (pair+order)%2 == 1
			if !t.Run(fmt.Sprintf("pair-%d/order-%d/poll-%t", pair, order, inspection), func(t *testing.T) {
				ipc, sample, proxy, _, tcp, _, _ := experimentChild(t, corePath)
				operations := make([]func() (uint64, error), 0, 128)
				for i := 0; i < 128; i++ {
					operation := baselineTCPOperation(t, proxy, tcp, false)
					if _, err := operation(); err != nil {
						t.Fatal(err)
					}
					operations = append(operations, operation)
				}
				sequence := 0
				operation := func() (uint64, error) {
					current := operations[sequence%len(operations)]
					sequence++
					return current()
				}
				until := time.Now().Add(time.Second)
				for time.Now().Before(until) {
					if _, err := operation(); err != nil {
						t.Fatal(err)
					}
				}
				read := func() (experimentSnapshot, error) {
					snapshot, err := ipc.snapshot()
					if err == nil && (snapshot.TCP != 128 || snapshot.UDP != 0) {
						err = fmt.Errorf("inspection requires 128 live TCP connections: %+v", snapshot)
					}
					return snapshot, err
				}
				if _, err := read(); err != nil {
					t.Fatal(err)
				}
				var stop func() (experimentPolls, error)
				if inspection {
					stop = startExperimentPoller(time.Second, read)
					t.Cleanup(func() { _, _ = stop() })
				}
				metrics, err := runBaselineStage("tcp-128", 8*time.Second, 0, sample, operation)
				var polls experimentPolls
				if stop != nil {
					var pollErr error
					polls, pollErr = stop()
					if pollErr != nil || polls.Count < 6 {
						t.Fatalf("polling failed or too few observations: %+v, %v", polls, pollErr)
					}
				}
				if err != nil {
					t.Fatal(err)
				}
				snapshot, err := read()
				if err != nil {
					t.Fatal(err)
				}
				metrics.ActiveConnections = snapshot.TCP + snapshot.UDP
				report.Stages = append(report.Stages, experimentStage{Pair: pair, Order: order, Inspection: inspection, Metrics: metrics, Snapshot: snapshot, Polls: polls})
				t.Logf("poll=%t cpu=%.2f%% RSS=%.2fMiB payload=%.2fMiB/s RTTp95=%.3fms snapshots=%d max=%dB snapshotP95=%.3fms",
					inspection, metrics.CPUCorePercent, float64(metrics.RSSP50Bytes)/(1024*1024), metrics.PayloadMiBPerSec, metrics.LatencyP95Ms, polls.Count, polls.MaxBytes, polls.P95Ms)
			}) {
				return
			}
		}
	}
	writeExperiment(t, output, report)
}

func TestDesktopCoreRetentionExperiment(t *testing.T) {
	corePath, output, report := prepareExperiment(t, "retention")
	report.Parameters = map[string]any{
		"cycles": 3, "load_seconds": 10, "quiet_seconds_per_cycle": 70,
		"load_min_interval_ms": 20, "udp_flows_per_cycle": 16,
		"udp_timeout_seconds_in_current_source": 60, "quiet_observation_interval_seconds": 10,
		"mixed_operation": "one new 32B TCP echo + one rotating 1200B UDP echo + one unique UDP DNS query",
	}
	ipc, sample, proxy, dnsAddress, tcp, udp, upstreamCount := experimentChild(t, corePath)
	for cycle := 1; cycle <= 3; cycle++ {
		if !t.Run(fmt.Sprintf("cycle-%d/load", cycle), func(t *testing.T) {
			churn := baselineTCPOperation(t, proxy, tcp, true)
			dns := baselineDNSOperation(t, dnsAddress, "udp", fmt.Sprintf("cycle-%d", cycle))
			udpOperations := make([]func() (uint64, error), 0, 16)
			for i := 0; i < 16; i++ {
				udpOperations = append(udpOperations, baselineUDPOperation(t, proxy, udp))
			}
			sequence := 0
			operation := func() (uint64, error) {
				up, err := churn()
				if err != nil {
					return 0, err
				}
				down, err := udpOperations[sequence%len(udpOperations)]()
				sequence++
				if err != nil {
					return 0, err
				}
				_, err = dns()
				return up + down, err
			}
			queriesBefore := upstreamCount()
			metrics, err := runBaselineStage("mixed-load", 10*time.Second, 20*time.Millisecond, sample, operation)
			if err != nil {
				t.Fatal(err)
			}
			queries := upstreamCount() - queriesBefore
			if queries < metrics.Operations {
				t.Fatal("retention DNS workload did not reach upstream for each operation")
			}
			snapshot, err := ipc.snapshot()
			if err != nil || snapshot.UDP != 16 {
				t.Fatalf("expected 16 active UDP flows: %+v, %v", snapshot, err)
			}
			metrics.ActiveConnections = snapshot.TCP + snapshot.UDP
			report.Stages = append(report.Stages, experimentStage{Cycle: cycle, Metrics: metrics, Snapshot: snapshot, UpstreamQueries: queries})
			t.Logf("mixed operations=%d RSS=%.2fMiB active TCP/UDP=%d/%d", metrics.Operations, float64(metrics.RSSP50Bytes)/(1024*1024), snapshot.TCP, snapshot.UDP)
		}) {
			return
		}
		// All load clients have closed through subtest cleanup. Do not force-close
		// tracked flows; observe actual expiry past the current 60s UDP deadline.
		for quiet := 10; quiet <= 70; quiet += 10 {
			metrics, err := runBaselineStage("quiet", 10*time.Second, 0, sample, nil)
			if err != nil {
				t.Fatal(err)
			}
			snapshot, err := ipc.snapshot()
			if err != nil || snapshot.TCP != 0 || snapshot.UDP > 16 {
				t.Fatalf("invalid quiet-state connections: %+v, %v", snapshot, err)
			}
			metrics.ActiveConnections = snapshot.TCP + snapshot.UDP
			report.Stages = append(report.Stages, experimentStage{Cycle: cycle, QuietSeconds: quiet, Metrics: metrics, Snapshot: snapshot})
			t.Logf("cycle=%d quiet=%ds RSSend=%.2fMiB active UDP=%d", cycle, quiet, float64(metrics.RSSEndBytes)/(1024*1024), snapshot.UDP)
			if quiet == 70 && snapshot.UDP != 0 {
				t.Fatal("UDP tracked flows did not expire after 70s quiet")
			}
		}
	}
	if ipc.invoke(t, stopListenerMethod, nil) != true || ipc.invoke(t, shutdownMethod, nil) != true {
		t.Fatal("retention child shutdown failed")
	}
	writeExperiment(t, output, report)
}

func TestExperimentSnapshotValidation(t *testing.T) {
	for _, value := range []any{nil, true, "", "{}", "null", `{"connections":{}}`, `{"connections":[{}]}`,
		`{"connections":[{"id":"x","metadata":{"network":"other"}}]}`,
		`{"connections":[{"id":"x","metadata":{"network":"tcp"}},{"id":"x","metadata":{"network":"udp"}}]}`} {
		if _, err := decodeExperimentSnapshot(value); err == nil {
			t.Fatalf("accepted invalid snapshot: %v", value)
		}
	}
	for _, value := range []string{`{"connections":null}`, `{"connections":[]}`} {
		if result, err := decodeExperimentSnapshot(value); err != nil || result.TCP != 0 || result.UDP != 0 {
			t.Fatalf("rejected empty core snapshot: %+v, %v", result, err)
		}
	}
	result, err := decodeExperimentSnapshot(`{"connections":[{"id":"x","metadata":{"network":"tcp"}},{"id":"y","metadata":{"network":"udp"}}]}`)
	if err != nil || result.TCP != 1 || result.UDP != 1 || result.Bytes == 0 {
		t.Fatalf("incorrect snapshot accounting: %+v, %v", result, err)
	}
}

func TestExperimentPollerStopsAndPropagatesFailure(t *testing.T) {
	called := make(chan struct{}, 1)
	stop := startExperimentPoller(time.Hour, func() (experimentSnapshot, error) {
		called <- struct{}{}
		return experimentSnapshot{Bytes: 123}, nil
	})
	select {
	case <-called:
	case <-time.After(time.Second):
		t.Fatal("poller did not start")
	}
	result, err := stop()
	if err != nil || result.Count != 1 || result.TotalBytes != 123 || result.MaxBytes != 123 {
		t.Fatalf("poller accounting: %+v, %v", result, err)
	}
	if again, err := stop(); err != nil || again != result {
		t.Fatal("poller stop is not idempotent")
	}
	failed := make(chan struct{})
	stop = startExperimentPoller(time.Millisecond, func() (experimentSnapshot, error) {
		close(failed)
		return experimentSnapshot{}, fmt.Errorf("snapshot failed")
	})
	select {
	case <-failed:
	case <-time.After(time.Second):
		t.Fatal("failing poll did not run")
	}
	if result, err := stop(); err == nil || result.Count != 0 {
		t.Fatal("failed poll was counted as successful")
	}
}

func TestExperimentPollerWaitsForInFlightRead(t *testing.T) {
	started, release := make(chan struct{}), make(chan struct{})
	stop := startExperimentPoller(time.Second, func() (experimentSnapshot, error) {
		close(started)
		<-release
		return experimentSnapshot{Bytes: 7}, nil
	})
	<-started
	stopped := make(chan experimentPolls, 1)
	go func() { result, _ := stop(); stopped <- result }()
	select {
	case <-stopped:
		t.Fatal("stop returned while a snapshot read was still running")
	case <-time.After(5 * time.Millisecond):
	}
	close(release)
	select {
	case result := <-stopped:
		if result.Count != 1 || result.TotalBytes != 7 {
			t.Fatal("in-flight read lost after stop")
		}
	case <-time.After(time.Second):
		t.Fatal("stop did not join the poller")
	}
}

func TestBaselineIPCSerializesInspectionRequests(t *testing.T) {
	client, server := net.Pipe()
	t.Cleanup(func() { _ = client.Close(); _ = server.Close() })
	ipc := &baselineIPC{connection: client, responses: make(chan ActionResult, 1), errors: make(chan error, 1)}
	served := make(chan error, 1)
	go func() {
		for i := 0; i < 2; i++ {
			payload, err := readFrame(server)
			if err != nil {
				served <- err
				return
			}
			var action Action
			if err := json.Unmarshal(payload, &action); err != nil {
				served <- err
				return
			}
			ipc.responses <- ActionResult{Id: action.Id, Method: action.Method, Data: `{"connections":[]}`}
		}
		served <- nil
	}()
	errors := make(chan error, 2)
	for i := 0; i < 2; i++ {
		go func() { _, err := ipc.snapshot(); errors <- err }()
	}
	for i := 0; i < 2; i++ {
		if err := <-errors; err != nil {
			t.Fatal(err)
		}
	}
	if err := <-served; err != nil || ipc.sequence != 2 {
		t.Fatalf("IPC serialization: sequence=%d err=%v", ipc.sequence, err)
	}
}
