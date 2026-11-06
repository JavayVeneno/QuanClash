# Isolated Core Performance Baseline

## Scope

`core/performance_windows_test.go` is an opt-in Windows harness. Three fresh
child cores use temporary homes, private named pipes, loopback SOCKS5/DNS and
local echo/DNS servers. It does not change app profiles, system proxy, system
DNS or TUN. It does not start the privileged helper or manage other processes.

This is a measurement tool, not an optimization, a Surge comparison, or remote
node acceptance. The user's Clash Verge remains running during this capture;
background workload is not controlled, so short-run results can vary.

## Workloads

Three-second stages, half-second workload warmup, one sequential worker, fixed
stage order. Three repetitions each start a fresh child core.

| Stage | Workload |
| --- | --- |
| idle-before | Open listeners, no workload |
| tcp-64k | Persistent SOCKS5 TCP, 64 KiB echo payload |
| tcp-churn-32b | New SOCKS5 connection per 32-byte echo, capped at 250/s |
| udp-1200b | SOCKS5 UDP associate, 1200-byte echo payload |
| dns-udp-miss | Unique uncached A queries to the core over UDP |
| dns-tcp-miss | Unique A queries, TCP connection reused in batches of 64 |
| idle-after | No workload after clients close |

Echo payloads and DNS addresses are validated. DNS upstream request counts must
cover successful queries, so cached answers cannot mask the miss workload. Any
workload/sampling failure invalidates the run. A report is written exclusively
after all repetitions pass, without overwriting a previous report.

The initial unpaced experiment exhausted Windows ephemeral ports during TCP
DNS and produced no valid report. Churn now has a four-millisecond minimum
operation interval (including warmup, conservatively paced). A second trial
exposed the DNS dependency's default limit of 128 queries per TCP connection;
the client now rotates connections every 64 queries without retrying failures.
Three repetitions use about 5250 TCP connections at most across both sides of
churn, plus control/persistent sockets and one TCP connection per 64 DNS queries.
This is a bounded workload, not an assurance that host port capacity is always
available in the presence of unrelated activity.

## Metrics

- Child working set only: 200ms samples plus start/end, median, sampled max and
  raw values. Sampled max can miss brief peaks; working set is not live heap.
- Windows child user+kernel CPU: 100% means one logical CPU busy, not
  host-normalized. Short idle runs can round to zero at OS CPU-timer resolution.
- Successful bidirectional echo payload rate excludes headers and is not
  one-way bandwidth or maximum throughput.
- RTT P50/P95 use an 8192-entry bounded reservoir across the whole stage.
  Churn pacing is excluded from RTT, but included in wall time. Idle has no RTT
  samples; zero fields do not mean zero network latency.
- One full connection snapshot is read after each timed stage; no in-stage
  inspection polling or forced GC. UDP NAT, DNS cache and buffers can remain
  after load. Three seconds of idle is not a long-term leak verdict.
- Reports record binary SHA256/build settings, CPU identification, config
  template, current wrapper/submodule revisions and dirty status. Source status
  at measurement time is separate from the tested binary's build provenance.
- Flutter/helper/harness CPU/RSS, remote encrypted protocols, process lookup,
  sniffing, mux, concurrent traffic, IPv6 and TUN are not measured here.

## Reproduce

From `core/`, use a new output path and identical build flags for comparisons:

```powershell
$env:CGO_ENABLED = '0'
go test -tags=with_gvisor ./...
go build -tags=with_gvisor -o ../build/QuanClashCore-perf.exe .
$env:QUANCLASH_CORE_PERF = (Resolve-Path ../build/QuanClashCore-perf.exe).Path
$env:QUANCLASH_PERF_OUTPUT = (Join-Path (Resolve-Path ../build).Path 'performance-baseline-new.json')
go test -tags=with_gvisor -run '^TestDesktopCorePerformanceBaseline$' -count=1 -v -timeout 180s .
```

Use an independently verified release artifact for release comparisons. This
temporary source build has no release stripping/version flags; do not mix its
file size or measurements with packaged release builds. JSON and logs under
`build/` are Git-ignored. Keep reviewed result ranges in this document. Default
Go tests skip child-process benchmarking unless explicitly opted in.

## Next Measurements

The subsequent inspection A/B and a four-minute, three-cycle retention test are
documented in `.agents/performance-experiments.md`.

1. Repeat under comparable host load and identical build settings to reduce
   dispersion before setting performance regression thresholds.
2. Add long-run churn/UDP/DNS retention and concurrent traffic workloads.
3. Compare connection inspection polling on/off and process lookup overhead.
4. Measure privileged TUN, IPv6, sniffing, mux and remote protocols separately.
5. Compare the same workloads before/after statistics, TrafficClass and QoS.

## Recorded Checkpoint - 2026-10-29

Three complete repetitions passed (71.27 seconds overall). This is an initial
exploratory Windows loopback reference, not full Phase 0 performance acceptance.

- Host: Windows amd64, Intel64 Family 6 Model 191 Stepping 2, GenuineIntel,
  24 logical CPUs. Harness and binary: Go 1.27.0; CGO disabled; `with_gvisor`;
  GOAMD64 v1; no release stripping/version flags.
- Wrapper revision: `46ff75c580468bb8d4cf68a76d143b319665c48d`, dirty.
  Mihomo: `8380d0e7462f061a964323e9bf3129a236fcc5d5`, clean.
- Temporary core SHA256:
  `044928d061226aed2df3f514be366440c3225299b24cc7f401ea4767e9f926a7`.
- Complete raw report: `build/performance-baseline-20261029-batched.json`;
  SHA256 `ed05c3014e09dfdd676e58948637aac11e5e728ca91e83a3da72318df77a02e8`.
  Log: `build/performance-baseline-20261029-batched.log`. Both are Git-ignored.
- Metric tests pass three times, including reservoir bounds, CPU/RSS/rate
  accounting, idle/pacing, sampling failures and 130 TCP DNS queries split
  across three connections below the dependency's default 128-query limit.
- Final wrapper verification passes `go test -count=1 ./...`,
  `go test -tags=with_gvisor -count=1 ./...` and
  `go vet -tags=with_gvisor ./...`. This increment changes only test tooling and
  documentation; the previous Flutter result remains 530 passing tests with
  13 existing analysis infos, not a newly repeated Flutter run.
- Read-only pre/post checks show unchanged system proxy settings and unchanged
  Clash Verge/Mihomo PIDs and start times. No benchmark children remain. These
  checks are not a full connectivity, DNS-server or route-table audit.
- Published core/helper hashes remain unchanged; the temporary benchmark
  artifact is not installed into the running app or substituted for release.

Ranges are the minimum and maximum of the three runs. RSS is the range of
within-stage medians. CPU uses one-logical-core percentages, not total host CPU.
TCP/UDP rates count both directions of echo payload. DNS/churn rates count
successful operations. Idle stages have no latency observations.

| Stage | RSS median range (MiB) | CPU range (%) | Rate range | RTT P95 range (ms) |
| --- | --- | --- | --- | --- |
| idle-before | 22.68-23.00 | 0.00 observed | n/a | n/a |
| tcp-64k | 27.48-27.63 | 51.56-80.20 | 248.06-569.37 MiB/s | 0.546-0.775 |
| tcp-churn-32b | 28.41-28.71 | 22.39-40.56 | 210.63-221.66 connections/s | 1.669-2.741 |
| udp-1200b | 30.00-30.14 | 79.17-88.53 | 28.55-29.14 MiB/s | 0.516-0.517 |
| dns-udp-miss | 33.82-34.38 | 69.79-80.19 | 1814.31-2040.82 queries/s | 0.551-1.031 |
| dns-tcp-miss | 35.33-35.62 | 97.39-98.95 | 2471.39-2665.45 queries/s | 0.539-0.543 |
| idle-after | 35.36-35.80 | 0.00 observed | n/a | n/a |

The highest sampled RSS across all stages is 36.23 MiB. Idle-after still reports
one tracked flow following the UDP workload; the short stage does not wait for
NAT expiry. Retained buffers/cache/flow state must be measured over a longer
interval before calling growth bounded or a leak. No forced GC was performed.

TCP payload rate varies by more than 2x across repetitions. Host scheduling,
background load and sequential-client overhead are not isolated here; these
numbers are unsuitable for small optimization claims or a Surge comparison.
Before changing statistics, add controlled inspection-on/off and long-duration
retention workloads. Do not tune forwarding from the best short run alone.
