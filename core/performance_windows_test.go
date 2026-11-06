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
	"sync"
	"sync/atomic"
	"syscall"
	"testing"
	"time"

	"github.com/Microsoft/go-winio"
	"github.com/metacubex/mihomo/component/memory"
	"github.com/metacubex/mihomo/transport/socks5"
	D "github.com/miekg/dns"
	"golang.org/x/sys/windows"
)

const baselineConfig = `
mixed-port: %s
allow-lan: false
bind-address: 127.0.0.1
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
ipv6: false
external-controller: ''
profile:
  store-selected: false
  store-fake-ip: false
tun:
  enable: false
sniffer:
  enable: false
dns:
  enable: true
  listen: %s
  enhanced-mode: normal
  cache-algorithm: lru
  nameserver: [%s]
  default-nameserver: [%s]
  fallback-filter:
    geoip: false
rules: ['MATCH,DIRECT']
`

const baselineDNSTCPBatch = 64

type baselineIPC struct {
	mutex      sync.Mutex
	connection net.Conn
	responses  chan ActionResult
	errors     chan error
	sequence   int
}

func (ipc *baselineIPC) invoke(t *testing.T, method Method, data any) any {
	t.Helper()
	result, err := ipc.call(method, data)
	if err != nil {
		t.Fatal(err)
	}
	return result
}

// Polling goroutines propagate errors to their owner, never call t.Fatal.
// Only one request is outstanding on this test-only synchronous client.
func (ipc *baselineIPC) call(method Method, data any) (any, error) {
	ipc.mutex.Lock()
	defer ipc.mutex.Unlock()
	ipc.sequence++
	id := fmt.Sprintf("baseline-%d", ipc.sequence)
	payload, err := json.Marshal(Action{Id: id, Method: method, Data: data})
	if err != nil {
		return nil, err
	}
	if err := ipc.connection.SetWriteDeadline(time.Now().Add(10 * time.Second)); err != nil {
		return nil, err
	}
	if err := writeFrame(ipc.connection, payload); err != nil {
		return nil, err
	}
	select {
	case result := <-ipc.responses:
		if result.Id != id || result.Method != method || result.Code != 0 {
			return nil, fmt.Errorf("invalid %s response id/method/code", method)
		}
		return result.Data, nil
	case err := <-ipc.errors:
		return nil, fmt.Errorf("%s: %w", method, err)
	case <-time.After(10 * time.Second):
		return nil, fmt.Errorf("%s: timed out", method)
	}
}

func startBaselineCore(t *testing.T, corePath, config string) (*baselineIPC, func() (baselineProcessSample, error)) {
	t.Helper()
	home := t.TempDir()
	if err := os.WriteFile(filepath.Join(home, "config.yaml"), []byte(config), 0600); err != nil {
		t.Fatal(err)
	}
	pipeName := `\\.\pipe\quanclash-perf-` + filepath.Base(home)
	listener, err := winio.ListenPipe(pipeName, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = listener.Close() })
	logFile, err := os.Create(filepath.Join(home, "core.log"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = logFile.Close() })
	cmd := exec.Command(corePath, pipeName)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	cmd.Stdout, cmd.Stderr = logFile, logFile
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	exited := make(chan error, 1)
	go func() { exited <- cmd.Wait() }()
	t.Cleanup(func() {
		_ = cmd.Process.Kill()
		select {
		case <-exited:
		case <-time.After(5 * time.Second):
			t.Error("baseline child did not exit")
		}
	})
	processHandle, err := windows.OpenProcess(windows.PROCESS_QUERY_LIMITED_INFORMATION, false, uint32(cmd.Process.Pid))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = windows.CloseHandle(processHandle) })
	sample := func() (baselineProcessSample, error) {
		var created, exited, kernel, user windows.Filetime
		if err := windows.GetProcessTimes(processHandle, &created, &exited, &kernel, &user); err != nil {
			return baselineProcessSample{}, err
		}
		mem, err := memory.GetMemoryInfo(int32(cmd.Process.Pid))
		if err != nil {
			return baselineProcessSample{}, err
		}
		if mem.RSS == 0 {
			return baselineProcessSample{}, fmt.Errorf("OS reported zero child working set")
		}
		ticks := (uint64(kernel.HighDateTime)<<32 | uint64(kernel.LowDateTime)) + (uint64(user.HighDateTime)<<32 | uint64(user.LowDateTime))
		return baselineProcessSample{time.Now(), time.Duration(ticks) * 100 * time.Nanosecond, mem.RSS}, nil
	}
	accepted := make(chan net.Conn, 1)
	acceptError := make(chan error, 1)
	go func() {
		connection, err := listener.Accept()
		if err != nil {
			acceptError <- err
		} else {
			accepted <- connection
		}
	}()
	var connection net.Conn
	select {
	case connection = <-accepted:
	case err := <-acceptError:
		t.Fatal(err)
	case <-time.After(10 * time.Second):
		t.Fatal("baseline child did not connect")
	}
	t.Cleanup(func() { _ = connection.Close() })
	ipc := &baselineIPC{connection: connection, responses: make(chan ActionResult, 1), errors: make(chan error, 1)}
	// Drain unsolicited events, as the real app does, so synchronous tracker
	// notifications cannot fill the private pipe and stall forwarding.
	go func() {
		for {
			payload, err := readFrame(connection)
			if err != nil {
				ipc.errors <- err
				return
			}
			var result ActionResult
			if err := json.Unmarshal(payload, &result); err != nil {
				ipc.errors <- err
				return
			}
			if result.Id != "" {
				ipc.responses <- result
			}
		}
	}()
	init, _ := json.Marshal(InitParams{HomeDir: home, Version: 1})
	if ipc.invoke(t, initClashMethod, string(init)) != true {
		t.Fatal("baseline core initialization failed")
	}
	params, _ := json.Marshal(SetupParams{SelectedMap: map[string]string{}, TestURL: "http://127.0.0.1/"})
	if result := ipc.invoke(t, setupConfigMethod, string(params)); result != "" {
		t.Fatalf("baseline configuration rejected: %v", result)
	}
	if ipc.invoke(t, startListenerMethod, nil) != true {
		t.Fatal("baseline listeners did not start")
	}
	return ipc, sample
}

func baselineEchoServers(t *testing.T) (string, string) {
	t.Helper()
	tcp, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	var workers sync.WaitGroup
	acceptDone := make(chan struct{})
	go func() {
		defer close(acceptDone)
		for {
			connection, err := tcp.Accept()
			if err != nil {
				return
			}
			workers.Add(1)
			go func() {
				defer workers.Done()
				defer connection.Close()
				_ = connection.SetDeadline(time.Now().Add(5 * time.Minute))
				_, _ = io.Copy(connection, connection)
			}()
		}
	}()
	t.Cleanup(func() {
		_ = tcp.Close()
		<-acceptDone
		workers.Wait()
	})
	udp, err := net.ListenPacket("udp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	udpDone := make(chan struct{})
	go func() {
		defer close(udpDone)
		buffer := make([]byte, 65535)
		for {
			n, remote, err := udp.ReadFrom(buffer)
			if err != nil {
				return
			}
			if _, err := udp.WriteTo(buffer[:n], remote); err != nil {
				return
			}
		}
	}()
	t.Cleanup(func() { _ = udp.Close(); <-udpDone })
	return tcp.Addr().String(), udp.LocalAddr().String()
}

func baselineDNSUpstream(t *testing.T) (string, *atomic.Uint64) {
	t.Helper()
	packet, err := net.ListenPacket("udp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	// Queries are handled serially by our workloads, but the DNS server invokes
	// handlers concurrently. The counter is returned through atomic access.
	count := new(atomic.Uint64)
	server := &D.Server{PacketConn: packet, Handler: D.HandlerFunc(func(w D.ResponseWriter, query *D.Msg) {
		count.Add(1)
		answer := new(D.Msg).SetReply(query)
		for _, question := range query.Question {
			if question.Qtype == D.TypeA {
				answer.Answer = append(answer.Answer, &D.A{
					Hdr: D.RR_Header{Name: question.Name, Rrtype: D.TypeA, Class: D.ClassINET, Ttl: 60},
					A:   net.ParseIP("203.0.113.7"),
				})
			}
		}
		_ = w.WriteMsg(answer)
	})}
	go func() { _ = server.ActivateAndServe() }()
	t.Cleanup(func() { _ = server.Shutdown() })
	return packet.LocalAddr().String(), count
}

func baselineSOCKSConnect(proxyAddress, target string, command byte) (net.Conn, socks5.Addr, error) {
	connection, err := net.DialTimeout("tcp4", proxyAddress, 3*time.Second)
	if err != nil {
		return nil, nil, err
	}
	_ = connection.SetDeadline(time.Now().Add(3 * time.Second))
	bound, err := socks5.ClientHandshake(connection, socks5.ParseAddr(target), command, nil)
	if err != nil {
		_ = connection.Close()
		return nil, nil, err
	}
	return connection, bound, nil
}

func baselineTCPOperation(t *testing.T, proxyAddress, target string, churn bool) func() (uint64, error) {
	t.Helper()
	payload := bytes.Repeat([]byte{0x5a}, 64*1024)
	if churn {
		payload = payload[:32]
	}
	buffer := make([]byte, len(payload))
	var persistent net.Conn
	if !churn {
		var err error
		persistent, _, err = baselineSOCKSConnect(proxyAddress, target, socks5.CmdConnect)
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() {
			if persistent != nil {
				_ = persistent.Close()
			}
		})
	}
	return func() (uint64, error) {
		connection := persistent
		if churn {
			var err error
			connection, _, err = baselineSOCKSConnect(proxyAddress, target, socks5.CmdConnect)
			if err != nil {
				return 0, err
			}
			defer connection.Close()
		}
		if err := connection.SetDeadline(time.Now().Add(3 * time.Second)); err != nil {
			return 0, err
		}
		n, err := connection.Write(payload)
		if err != nil || n != len(payload) {
			return 0, fmt.Errorf("TCP write: n=%d err=%v", n, err)
		}
		if _, err := io.ReadFull(connection, buffer); err != nil {
			return 0, err
		}
		if !bytes.Equal(payload, buffer) {
			return 0, fmt.Errorf("TCP echo payload mismatch")
		}
		return uint64(2 * len(payload)), nil
	}
}

func baselineUDPOperation(t *testing.T, proxyAddress, target string) func() (uint64, error) {
	t.Helper()
	control, bound, err := baselineSOCKSConnect(proxyAddress, "0.0.0.0:0", socks5.CmdUDPAssociate)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = control.Close() })
	_ = control.SetDeadline(time.Time{})
	relay, err := net.Dial("udp4", bound.String())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = relay.Close() })
	payload := bytes.Repeat([]byte{0x6b}, 1200)
	packet, err := socks5.EncodeUDPPacket(socks5.ParseAddr(target), payload)
	if err != nil {
		t.Fatal(err)
	}
	buffer := make([]byte, len(packet)+256)
	return func() (uint64, error) {
		if err := relay.SetDeadline(time.Now().Add(3 * time.Second)); err != nil {
			return 0, err
		}
		if _, err := relay.Write(packet); err != nil {
			return 0, err
		}
		n, err := relay.Read(buffer)
		if err != nil {
			return 0, err
		}
		address, response, err := socks5.DecodeUDPPacket(buffer[:n])
		if err != nil || address.String() != target || !bytes.Equal(response, payload) {
			return 0, fmt.Errorf("UDP echo address/payload mismatch: %v", err)
		}
		return uint64(2 * len(payload)), nil
	}
}

func baselineDNSOperation(t *testing.T, address, network, prefix string) func() (uint64, error) {
	t.Helper()
	client := &D.Client{Net: network, Timeout: 3 * time.Second}
	var persistent *D.Conn
	if network == "tcp" {
		var err error
		persistent, err = client.Dial(address)
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() {
			if persistent != nil {
				_ = persistent.Close()
			}
		})
	}
	var sequence uint64
	return func() (uint64, error) {
		// miekg/dns defaults to 128 queries before closing a TCP connection.
		// Rotate proactively below that limit; never hide a failed query by retry.
		if persistent != nil && sequence > 0 && sequence%baselineDNSTCPBatch == 0 {
			if err := persistent.Close(); err != nil {
				return 0, err
			}
			var err error
			persistent, err = client.Dial(address)
			if err != nil {
				return 0, err
			}
		}
		sequence++
		query := new(D.Msg).SetQuestion(fmt.Sprintf("%s-%d.invalid.", prefix, sequence), D.TypeA)
		var answer *D.Msg
		var err error
		if persistent != nil {
			answer, _, err = client.ExchangeWithConn(query, persistent)
		} else {
			answer, _, err = client.Exchange(query, address)
		}
		if err != nil {
			return 0, err
		}
		if answer.Id != query.Id || answer.Rcode != D.RcodeSuccess || len(answer.Answer) != 1 {
			return 0, fmt.Errorf("invalid DNS echo response")
		}
		record, ok := answer.Answer[0].(*D.A)
		if !ok || record.A.String() != "203.0.113.7" {
			return 0, fmt.Errorf("DNS echo address mismatch")
		}
		return 0, nil
	}
}

func TestDesktopCorePerformanceBaseline(t *testing.T) {
	corePath := os.Getenv("QUANCLASH_CORE_PERF")
	if corePath == "" {
		t.Skip("opt-in: set QUANCLASH_CORE_PERF and QUANCLASH_PERF_OUTPUT")
	}
	corePath, err := filepath.Abs(corePath)
	if err != nil {
		t.Fatal(err)
	}
	output := os.Getenv("QUANCLASH_PERF_OUTPUT")
	if output == "" {
		t.Fatal("QUANCLASH_PERF_OUTPUT must name a new JSON report file")
	}
	if _, err := os.Stat(output); err == nil || !os.IsNotExist(err) {
		t.Fatal("report path already exists or cannot be inspected; choose a new file")
	}
	binary, err := os.ReadFile(corePath)
	if err != nil {
		t.Fatal(err)
	}
	binaryHash := sha256.Sum256(binary)
	buildInfo, err := buildinfo.ReadFile(corePath)
	if err != nil {
		t.Fatal(err)
	}
	gitValue := func(args ...string) string {
		t.Helper()
		result, err := exec.Command("git", args...).Output()
		if err != nil {
			t.Fatal(err)
		}
		return string(bytes.TrimSpace(result))
	}
	type repetition struct {
		Index  int             `json:"index"`
		Stages []baselineStage `json:"stages"`
	}
	report := struct {
		SchemaVersion   int          `json:"schema_version"`
		RecordedAt      string       `json:"recorded_at"`
		Platform        string       `json:"platform"`
		HostProcessor   string       `json:"host_processor"`
		LogicalCPUs     int          `json:"logical_cpus"`
		HarnessGo       string       `json:"harness_go_version"`
		CoreSHA256      string       `json:"core_sha256"`
		CoreBuildInfo   any          `json:"core_build_info"`
		WrapperRevision string       `json:"wrapper_revision_at_measurement"`
		WrapperDirty    string       `json:"wrapper_status_at_measurement"`
		MihomoRevision  string       `json:"mihomo_revision_at_measurement"`
		MihomoDirty     string       `json:"mihomo_status_at_measurement"`
		ConfigTemplate  string       `json:"config_template"`
		StageSeconds    float64      `json:"requested_stage_seconds"`
		WarmupSeconds   float64      `json:"workload_warmup_seconds"`
		Concurrency     int          `json:"workload_concurrency"`
		Limitations     []string     `json:"limitations"`
		Repetitions     []repetition `json:"repetitions"`
	}{
		SchemaVersion: 1, RecordedAt: time.Now().UTC().Format(time.RFC3339),
		Platform:      runtime.GOOS + "/" + runtime.GOARCH,
		HostProcessor: os.Getenv("PROCESSOR_IDENTIFIER"), LogicalCPUs: runtime.NumCPU(),
		HarnessGo: runtime.Version(), CoreSHA256: hex.EncodeToString(binaryHash[:]), CoreBuildInfo: buildInfo,
		WrapperRevision: gitValue("rev-parse", "HEAD"), WrapperDirty: gitValue("status", "--short", "--untracked-files=normal"),
		MihomoRevision: gitValue("-C", "Clash.Meta", "rev-parse", "HEAD"), MihomoDirty: gitValue("-C", "Clash.Meta", "status", "--short"),
		ConfigTemplate: baselineConfig, StageSeconds: 3, WarmupSeconds: .5, Concurrency: 1,
		Limitations: []string{
			"Loopback SOCKS5 inbound with DIRECT outbound, not remote/encrypted node or TUN performance.",
			"Child working set and user+kernel CPU only; Flutter, helper, echo servers and test harness are excluded.",
			"One sequential worker; bidirectional payload rate is not maximum throughput or one-way bandwidth.",
			"200ms working-set samples may miss transient peaks; latency uses a bounded 8192-entry reservoir.",
			"DNS uses unique uncached names; TCP DNS rotates its reused client connection every 64 queries (server default limit: 128).",
			"TCP churn is capped at 250 connections/s to avoid Windows ephemeral-port exhaustion; observed latency excludes pacing.",
			"No process lookup, sniffing, mux, GUI connection polling, GC forcing, system proxy or TUN changes.",
			"Stage order is fixed; post-load idle is not a long-term memory leak verdict.",
			"Current source revision/status is recorded separately from binary build provenance; do not equate them.",
		},
	}
	for index := 1; index <= 3; index++ {
		run := repetition{Index: index}
		if !t.Run(fmt.Sprintf("repeat-%d", index), func(t *testing.T) {
			tcpOrigin, udpOrigin := baselineEchoServers(t)
			upstream, upstreamCount := baselineDNSUpstream(t)
			proxyAddress, dnsAddress := unusedSmokeTCPAddress(t), unusedSmokeTCPAddress(t)
			_, proxyPort, _ := net.SplitHostPort(proxyAddress)
			ipc, sample := startBaselineCore(t, corePath, fmt.Sprintf(baselineConfig, proxyPort, dnsAddress, upstream, upstream))
			for _, name := range []string{"idle-before", "tcp-64k", "tcp-churn-32b", "udp-1200b", "dns-udp-miss", "dns-tcp-miss", "idle-after"} {
				if !t.Run(name, func(t *testing.T) {
					var operation func() (uint64, error)
					switch name {
					case "tcp-64k", "tcp-churn-32b":
						operation = baselineTCPOperation(t, proxyAddress, tcpOrigin, name == "tcp-churn-32b")
					case "udp-1200b":
						operation = baselineUDPOperation(t, proxyAddress, udpOrigin)
					case "dns-udp-miss", "dns-tcp-miss":
						network := "udp"
						if name == "dns-tcp-miss" {
							network = "tcp"
						}
						operation = baselineDNSOperation(t, dnsAddress, network, name)
					}
					if operation != nil {
						until := time.Now().Add(500 * time.Millisecond)
						for time.Now().Before(until) {
							if _, err := operation(); err != nil {
								t.Fatalf("warmup: %v", err)
							}
							if name == "tcp-churn-32b" {
								time.Sleep(4 * time.Millisecond)
							}
						}
					}
					countBefore := upstreamCount.Load()
					var interval time.Duration
					if name == "tcp-churn-32b" {
						interval = 4 * time.Millisecond
					}
					result, err := runBaselineStage(name, 3*time.Second, interval, sample, operation)
					if err != nil {
						t.Fatal(err)
					}
					if name == "dns-udp-miss" || name == "dns-tcp-miss" {
						if queries := upstreamCount.Load() - countBefore; queries < result.Operations {
							t.Fatalf("uncached workload served only %d upstream queries for %d operations", queries, result.Operations)
						}
					}
					// Outside the timed region. Do not perturb forwarding by polling
					// connection inspection while collecting the initial baseline.
					var snapshot struct {
						Connections []json.RawMessage `json:"connections"`
					}
					encoded, ok := ipc.invoke(t, getConnectionsMethod, nil).(string)
					if !ok || json.Unmarshal([]byte(encoded), &snapshot) != nil {
						t.Fatal("invalid post-stage connection snapshot")
					}
					result.ActiveConnections = len(snapshot.Connections)
					run.Stages = append(run.Stages, result)
					t.Logf("cpu=%.2f%% RSS p50=%.2f MiB max=%.2f MiB ops/s=%.0f payload=%.2f MiB/s p95=%.3fms",
						result.CPUCorePercent, float64(result.RSSP50Bytes)/(1024*1024), float64(result.RSSMaxBytes)/(1024*1024), result.OperationsPerSec, result.PayloadMiBPerSec, result.LatencyP95Ms)
				}) {
					return
				}
			}
			if ipc.invoke(t, stopListenerMethod, nil) != true || ipc.invoke(t, shutdownMethod, nil) != true {
				t.Fatal("baseline core shutdown failed")
			}
		}) {
			return
		}
		report.Repetitions = append(report.Repetitions, run)
	}
	data, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		t.Fatal(err)
	}
	// A failed run never overwrites a previously successful report.
	file, err := os.OpenFile(output, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		t.Fatal(err)
	}
	_, writeErr := file.Write(append(data, '\n'))
	closeErr := file.Close()
	if writeErr != nil || closeErr != nil {
		t.Fatalf("write report: %v / %v", writeErr, closeErr)
	}
	t.Logf("complete report: %s", output)
}

func TestBaselineTCPDNSRespectsServerQueryLimit(t *testing.T) {
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	var mutex sync.Mutex
	connections := make(map[string]int)
	server := &D.Server{Listener: listener, Handler: D.HandlerFunc(func(w D.ResponseWriter, query *D.Msg) {
		mutex.Lock()
		connections[w.RemoteAddr().String()]++
		mutex.Unlock()
		answer := new(D.Msg).SetReply(query)
		answer.Answer = []D.RR{&D.A{
			Hdr: D.RR_Header{Name: query.Question[0].Name, Rrtype: D.TypeA, Class: D.ClassINET, Ttl: 60},
			A:   net.ParseIP("203.0.113.7"),
		}}
		_ = w.WriteMsg(answer)
	})}
	started := make(chan struct{})
	server.NotifyStartedFunc = func() { close(started) }
	serveResult := make(chan error, 1)
	go func() { serveResult <- server.ActivateAndServe() }()
	t.Cleanup(func() {
		_ = server.Shutdown()
		_ = listener.Close()
		if err := <-serveResult; err != nil {
			t.Error(err)
		}
	})
	select {
	case <-started:
	case <-time.After(3 * time.Second):
		t.Fatal("local DNS test server did not start")
	}
	operation := baselineDNSOperation(t, listener.Addr().String(), "tcp", "batch")
	for i := 0; i < 2*baselineDNSTCPBatch+2; i++ {
		if _, err := operation(); err != nil {
			t.Fatalf("query %d: %v", i+1, err)
		}
	}
	mutex.Lock()
	defer mutex.Unlock()
	if len(connections) != 3 {
		t.Fatalf("expected three reused TCP batches: %v", connections)
	}
	for _, queries := range connections {
		if queries > baselineDNSTCPBatch {
			t.Fatalf("client exceeded its TCP batch limit: %v", connections)
		}
	}
}
