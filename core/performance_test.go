//go:build !cgo

package main

import (
	"fmt"
	"math"
	"math/rand"
	"sort"
	"testing"
	"time"
)

const baselineLatencyCapacity = 8192

type baselineProcessSample struct {
	at       time.Time
	cpu      time.Duration
	rssBytes uint64
}

type baselineStage struct {
	Name              string   `json:"name"`
	PacingIntervalMs  float64  `json:"pacing_interval_ms"`
	WallSeconds       float64  `json:"wall_seconds"`
	Operations        uint64   `json:"successful_operations"`
	OperationsPerSec  float64  `json:"operations_per_second"`
	PayloadBytes      uint64   `json:"payload_bytes_both_directions"`
	PayloadMiBPerSec  float64  `json:"payload_mib_per_second"`
	LatencySamples    int      `json:"latency_sample_count"`
	LatencyP50Ms      float64  `json:"round_trip_p50_ms"`
	LatencyP95Ms      float64  `json:"round_trip_p95_ms"`
	CPUSeconds        float64  `json:"child_cpu_seconds"`
	CPUCorePercent    float64  `json:"child_cpu_percent_one_logical_core"`
	RSSSampleCount    int      `json:"rss_sample_count"`
	RSSStartBytes     uint64   `json:"rss_start_bytes"`
	RSSEndBytes       uint64   `json:"rss_end_bytes"`
	RSSP50Bytes       uint64   `json:"rss_p50_bytes"`
	RSSMaxBytes       uint64   `json:"rss_max_sampled_bytes"`
	RSSSamplesBytes   []uint64 `json:"rss_samples_bytes"`
	ActiveConnections int      `json:"active_connections_after_stage"`
}

// Algorithm R keeps latency storage bounded while sampling the entire stage,
// rather than reporting only its first (coldest) operations.
type baselineLatencies struct {
	seen   uint64
	values []float64
	random *rand.Rand
}

func newBaselineLatencies() *baselineLatencies {
	return &baselineLatencies{
		values: make([]float64, 0, baselineLatencyCapacity),
		random: rand.New(rand.NewSource(1)),
	}
}

func (l *baselineLatencies) add(elapsed time.Duration) {
	l.seen++
	ms := float64(elapsed) / float64(time.Millisecond)
	if len(l.values) < baselineLatencyCapacity {
		l.values = append(l.values, ms)
	} else if index := l.random.Int63n(int64(l.seen)); index < baselineLatencyCapacity {
		l.values[index] = ms
	}
}

func baselinePercentile(sorted []float64, percentile float64) float64 {
	if len(sorted) == 0 {
		return 0
	}
	index := int(math.Ceil(percentile*float64(len(sorted)))) - 1
	if index < 0 {
		index = 0
	} else if index >= len(sorted) {
		index = len(sorted) - 1
	}
	return sorted[index]
}

func summarizeBaseline(name string, samples []baselineProcessSample, latencies *baselineLatencies, payloadBytes uint64) (baselineStage, error) {
	result := baselineStage{Name: name, ActiveConnections: -1}
	if len(samples) < 2 {
		return result, fmt.Errorf("%s: fewer than two process samples", name)
	}
	first, last := samples[0], samples[len(samples)-1]
	wall := last.at.Sub(first.at)
	if wall <= 0 || last.cpu < first.cpu {
		return result, fmt.Errorf("%s: invalid wall/CPU sample interval", name)
	}
	result.WallSeconds = wall.Seconds()
	result.CPUSeconds = (last.cpu - first.cpu).Seconds()
	// Deliberately not divided by host CPU count: 100 means one busy core.
	result.CPUCorePercent = result.CPUSeconds / result.WallSeconds * 100
	result.Operations = latencies.seen
	result.OperationsPerSec = float64(latencies.seen) / result.WallSeconds
	result.PayloadBytes = payloadBytes
	result.PayloadMiBPerSec = float64(payloadBytes) / (1024 * 1024) / result.WallSeconds
	result.LatencySamples = len(latencies.values)
	sort.Float64s(latencies.values)
	result.LatencyP50Ms = baselinePercentile(latencies.values, .5)
	result.LatencyP95Ms = baselinePercentile(latencies.values, .95)
	result.RSSSampleCount = len(samples)
	result.RSSStartBytes, result.RSSEndBytes = first.rssBytes, last.rssBytes
	rss := make([]float64, 0, len(samples))
	for _, sample := range samples {
		result.RSSSamplesBytes = append(result.RSSSamplesBytes, sample.rssBytes)
		rss = append(rss, float64(sample.rssBytes))
		if sample.rssBytes > result.RSSMaxBytes {
			result.RSSMaxBytes = sample.rssBytes
		}
	}
	sort.Float64s(rss)
	result.RSSP50Bytes = uint64(baselinePercentile(rss, .5))
	return result, nil
}

// Operations run sequentially; the OS sampler is independent and never asks
// the child core for a heap snapshot or forces GC during the measurement.
func runBaselineStage(name string, duration, interval time.Duration, sample func() (baselineProcessSample, error), operation func() (uint64, error)) (baselineStage, error) {
	if duration <= 0 || interval < 0 {
		return baselineStage{}, fmt.Errorf("%s: invalid stage duration or pacing interval", name)
	}
	first, err := sample()
	if err != nil {
		return baselineStage{}, err
	}
	type observation struct {
		samples []baselineProcessSample
		err     error
	}
	stop := make(chan struct{})
	observed := make(chan observation, 1)
	go func() {
		samples := []baselineProcessSample{first}
		ticker := time.NewTicker(200 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-stop:
				last, err := sample()
				observed <- observation{append(samples, last), err}
				return
			case <-ticker.C:
				next, err := sample()
				if err != nil {
					observed <- observation{samples, err}
					return
				}
				samples = append(samples, next)
			}
		}
	}()
	latencies := newBaselineLatencies()
	var payload uint64
	deadline := first.at.Add(duration)
	if operation == nil {
		time.Sleep(time.Until(deadline))
	} else {
		for time.Now().Before(deadline) {
			start := time.Now()
			bytes, operationErr := operation()
			if operationErr != nil {
				err = operationErr
				break
			}
			latencies.add(time.Since(start))
			payload += bytes
			// Pacing belongs in wall time, not in the round-trip latency sample.
			if interval > 0 {
				if wait := time.Until(start.Add(interval)); wait > 0 {
					time.Sleep(wait)
				}
			}
		}
	}
	close(stop)
	observationResult := <-observed
	if err != nil {
		return baselineStage{}, fmt.Errorf("%s: workload failed: %w", name, err)
	}
	if observationResult.err != nil {
		return baselineStage{}, fmt.Errorf("%s: process sampling failed: %w", name, observationResult.err)
	}
	if operation != nil && latencies.seen == 0 {
		return baselineStage{}, fmt.Errorf("%s: no successful operations", name)
	}
	result, err := summarizeBaseline(name, observationResult.samples, latencies, payload)
	result.PacingIntervalMs = float64(interval) / float64(time.Millisecond)
	return result, err
}

func TestBaselineSummary(t *testing.T) {
	start := time.Now()
	latencies := newBaselineLatencies()
	for _, ms := range []int{1, 2, 3, 4, 5} {
		latencies.add(time.Duration(ms) * time.Millisecond)
	}
	result, err := summarizeBaseline("example", []baselineProcessSample{
		{start, time.Second, 100},
		{start.Add(time.Second), 2 * time.Second, 300},
		{start.Add(2 * time.Second), 4 * time.Second, 200},
	}, latencies, 4*1024*1024)
	if err != nil {
		t.Fatal(err)
	}
	if result.Operations != 5 || result.OperationsPerSec != 2.5 || result.PayloadMiBPerSec != 2 || result.CPUCorePercent != 150 {
		t.Fatalf("incorrect rate/CPU accounting: %+v", result)
	}
	if result.LatencyP50Ms != 3 || result.LatencyP95Ms != 5 || result.RSSP50Bytes != 200 || result.RSSMaxBytes != 300 || result.RSSStartBytes != 100 || result.RSSEndBytes != 200 {
		t.Fatalf("incorrect latency/RSS accounting: %+v", result)
	}
	for _, samples := range [][]baselineProcessSample{
		nil,
		{{start, 0, 1}},
		{{start, 0, 1}, {start, 0, 1}},
		{{start, time.Second, 1}, {start.Add(time.Second), 0, 1}},
	} {
		if _, err := summarizeBaseline("invalid", samples, latencies, 0); err == nil {
			t.Fatal("accepted invalid process samples")
		}
	}
	if baselinePercentile(nil, .95) != 0 {
		t.Fatal("empty percentile must not claim a latency")
	}
}

func TestBaselineLatencyStorageIsBounded(t *testing.T) {
	latencies := newBaselineLatencies()
	for i := 0; i < 10*baselineLatencyCapacity; i++ {
		latencies.add(time.Duration(i) * time.Millisecond)
	}
	if len(latencies.values) != baselineLatencyCapacity || latencies.seen != 10*baselineLatencyCapacity {
		t.Fatal("latency reservoir grew beyond its bound or lost operation accounting")
	}
	sort.Float64s(latencies.values)
	if baselinePercentile(latencies.values, .95) < 5*baselineLatencyCapacity {
		t.Fatal("reservoir samples only the start of the workload")
	}
}

func TestBaselineStageRejectsWorkloadAndSamplingErrors(t *testing.T) {
	sample := func() (baselineProcessSample, error) {
		return baselineProcessSample{at: time.Now(), rssBytes: 1}, nil
	}
	if _, err := runBaselineStage("failure", time.Millisecond, 0, sample, func() (uint64, error) {
		return 0, fmt.Errorf("broken echo")
	}); err == nil {
		t.Fatal("failed workload was reported as a valid baseline")
	}
	if _, err := runBaselineStage("failure", time.Millisecond, 0, func() (baselineProcessSample, error) {
		return baselineProcessSample{}, fmt.Errorf("cannot sample")
	}, nil); err == nil {
		t.Fatal("failed sampling was reported as a valid baseline")
	}
	calls := 0
	if _, err := runBaselineStage("final-sample-failure", time.Millisecond, 0, func() (baselineProcessSample, error) {
		calls++
		if calls > 1 {
			return baselineProcessSample{}, fmt.Errorf("child exited")
		}
		return sample()
	}, nil); err == nil {
		t.Fatal("a failed final sample was reported as a valid baseline")
	}
}

func TestBaselinePacingAndIdleAccounting(t *testing.T) {
	sample := func() (baselineProcessSample, error) {
		return baselineProcessSample{at: time.Now(), rssBytes: 1}, nil
	}
	result, err := runBaselineStage("paced", 25*time.Millisecond, 10*time.Millisecond, sample, func() (uint64, error) {
		return 64, nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if result.Operations == 0 || result.Operations > 3 || result.PayloadBytes != result.Operations*64 || result.PacingIntervalMs != 10 {
		t.Fatalf("incorrect pacing or payload accounting: %+v", result)
	}
	idle, err := runBaselineStage("idle", time.Millisecond, 0, sample, nil)
	if err != nil || idle.Operations != 0 || idle.LatencySamples != 0 || idle.PayloadBytes != 0 || idle.RSSSampleCount < 2 {
		t.Fatalf("idle must not invent traffic or latency observations: %+v, %v", idle, err)
	}
	for _, durations := range [][2]time.Duration{{0, 0}, {-1, 0}, {time.Second, -1}} {
		if _, err := runBaselineStage("invalid", durations[0], durations[1], sample, nil); err == nil {
			t.Fatal("accepted invalid duration/pacing")
		}
	}
}
