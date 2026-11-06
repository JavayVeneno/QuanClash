# Connection Inspection and State Retention Experiments

This supplements `.agents/performance-baseline.md`. The harness lives in
`core/performance_experiments_windows_test.go`; it only operates a private
Windows child core and loopback endpoints. No system networking, app profiles,
privileged helper, or other proxy processes are managed by these tests.

## Inspection A/B

- Three pairs, off/on then on/off then off/on, with a fresh child per stage.
- Each child has 128 established, payload-validated SOCKS5 TCP connections.
  One sequential worker sends 64 KiB echoes round-robin across those sockets.
  This holds connection count constant without opening new sockets under load.
- One-second warmup, then eight measured seconds per stage.
- Inspection uses `getConnections` immediately, then waits one second after
  each response, matching `lib/views/connection/connections.dart`. Reads never
  overlap. The off condition does not poll during the stage.
- Every snapshot must contain 128 TCP records, no UDP records, valid unique
  IDs and recognized network fields. Snapshot count, encoded bytes, RTT P50/P95,
  foreground RTT/rate and child CPU/RSS are recorded.
  Bytes count the inner snapshot JSON, not outer IPC escaping/framing. Poll RTT
  includes the harness's Go snapshot validation as well as core/IPC time.
- A poller error invalidates the stage; stop joins the in-flight read before
  returning. The first or final poll can straddle the timed sampling boundary;
  poll totals include those calls. No failed request is silently retried.

This measures the core's JSON/IPC snapshot path, not Flutter model allocation,
sorting or rendering. Host load remains uncontrolled, and the foreground uses
one worker rather than simultaneous streams. Per-pair ratios are descriptive,
not causal estimates or regression budgets. Alternate order reduces, but does
not eliminate, background/scheduler/temperature effects.

## Retention Cycles

- One fresh child, three cycles of ten-second mixed load plus 70-second quiet.
- A mixed operation sends one 32-byte echo over a new SOCKS5 TCP connection,
  one 1200-byte UDP echo through a rotating set of 16 source sockets, and one
  unique UDP DNS query. Minimum interval is 20ms: at most 50 new TCP connections
  per second and about 3000 TCP socket connections across both sides over all
  three cycles. DNS upstream query count must cover successful operations.
- Each load must show 16 tracked UDP flows. All load clients close through
  subtest cleanup, not a core close-connections action.
- During quiet, child OS CPU/RSS are sampled every 200ms. A single connection
  snapshot is taken after each ten-second interval. Quiet snapshots must have
  no TCP connections and at most 16 UDP flows. At 70 seconds, UDP count must be
  zero, otherwise the experiment fails.
- The embedded source's SOCKS5 UDP idle timeout is 60 seconds in
  `core/Clash.Meta/tunnel/tunnel.go`. No test-specific timeout is installed.
  Report parameters record that expectation; do not assume an arbitrary other
  binary uses this timeout. Changed binaries must be independently verified.
- The report preserves within-stage RSS raw samples, CPU, counts and rates.
  There is no forced GC, cache flush or artificial policy/state cleanup.

The four-minute retention window is longer than the UDP expiry, not a soak
test. RSS need not return to cold idle after Go heap/buffer/cache allocation.
The DNS workload is finite and does not deliberately saturate cache capacity;
this cannot establish a cache memory bound. Zero tracked flows establishes
tracker expiry for this workload, not the absence of every retained reference,
goroutine, packet buffer or native allocation.

## Run

From `core/`, with a matching temporary build or verified release artifact:

```powershell
$env:CGO_ENABLED = '0'
go test -tags=with_gvisor ./...
go build -tags=with_gvisor -o ../build/QuanClashCore-perf.exe .
$env:QUANCLASH_CORE_PERF = (Resolve-Path ../build/QuanClashCore-perf.exe).Path
$env:QUANCLASH_PERF_EXPERIMENTS = '1'
$env:QUANCLASH_PERF_REPORT_PREFIX = (Join-Path (Resolve-Path ../build).Path 'performance-experiments-new')
go test -tags=with_gvisor -run '^TestDesktopCore(Inspection|Retention)Experiment$' -count=1 -v -failfast -timeout 8m .
Remove-Item Env:QUANCLASH_CORE_PERF, Env:QUANCLASH_PERF_EXPERIMENTS, Env:QUANCLASH_PERF_REPORT_PREFIX
```

Both experiments run serially in about five minutes; they can be selected
individually by test name. Load tests are skipped unless explicitly opted in.
Use a new prefix: each successful experiment creates an exclusive JSON report
with `-inspection` or `-retention` suffix. A successful inspection report can
exist even if a later retention run fails; check each result separately.

Reports record binary hash/build settings, host CPU, source revisions/dirty
status, config template and workload parameters. Report/log files under
`build/` are ignored. Keep reviewed, non-sensitive result ranges here.

## Acceptance Boundary

Neither experiment adds production forwarding hooks or changes the UI. Process
lookup, request-notification serialization, Dart/GUI allocation, concurrent
forwarding, high-flow UDP churn, hour-scale cache/heap retention, IPv6, remote
encrypted nodes and privileged TUN still require separate measurements.

## Inspection Checkpoint - 2026-10-29

All six stages passed in 57.74 seconds. The temporary core matches the earlier
baseline binary SHA256
`044928d061226aed2df3f514be366440c3225299b24cc7f401ea4767e9f926a7`.
Host: Windows amd64, Intel64 Family 6 Model 191 Stepping 2, 24 logical CPUs;
Go 1.27.0, CGO disabled, `with_gvisor`, GOAMD64 v1, no release stripping flags.

Each on stage produced eight validated snapshots. Inner JSON maximum size was
89,152-89,158 bytes; stage sums were 711,414-711,462 bytes. Snapshot RTT P50 was
2.057-2.085ms and P95 was 2.578-2.633ms (only eight observations per stage).

| Pair | Off rate (MiB/s) | On rate (MiB/s) | Rate change | On-off CPU (percentage points) | On-off RSS median (MiB) |
| --- | --- | --- | --- | --- | --- |
| 1 | 407.58 | 309.62 | -24.03% | -11.91 | +0.08 |
| 2 | 322.88 | 309.25 | -4.22% | -0.20 | +0.50 |
| 3 | 305.33 | 317.16 | +3.88% | +8.40 | +0.81 |

Foreground RTT P95 was 0.581-0.613ms off and 0.611-0.620ms on. The changes are
not directionally consistent across throughput/CPU. Do not attribute the first
pair's 24% difference entirely to polling or claim a quantified improvement
from removing it. A longer controlled experiment plus allocation profiling is
needed to establish a regression budget. These measurements do establish the
full-snapshot payload shape and repeatable workload for a future delta API.

Raw report: `build/performance-experiments-20261029-inspection.json`; SHA256
`e30eda1fef2e19c566c34a67f3aeba5c7ece4df1e5fe7b8856b85f7ec870ccff`.
Combined log: `build/performance-experiments-20261029.log` (Git-ignored).

## Retention Checkpoint - 2026-10-29

The three cycles passed in 240.85 seconds; both experiments together took about
299 seconds. The binary/host/build settings match the inspection experiment.

| Cycle | Mixed operations / upstream DNS queries | Load RSS median (MiB) | Quiet at 50s UDP count | Quiet at 60s UDP count | Quiet at 70s RSS end (MiB) |
| --- | --- | --- | --- | --- | --- |
| 1 | 480 / 480 | 31.75 | 16 | 0 | 32.51 |
| 2 | 485 / 485 | 33.30 | 16 | 0 | 33.49 |
| 3 | 479 / 479 | 34.09 | 16 | 0 | 34.37 |

No TCP records remain at any quiet observation. All cycles retain 16 UDP
records through the 50-second observation and zero at the 60/70-second
observations. This brackets tracker expiry, not its exact packet-level timing.
No force-GC/flush/close-connections action was used. Highest sampled RSS over
this experiment is 34.46 MiB.

Quiet-end RSS grows by about 1.86 MiB across the three cycles while tracked
flows return to zero. The source of that retained working set is not identified
here. These data do not prove a leak, memory reclamation, or a long-run plateau;
longer runs and heap/allocation profiling remain required. Quiet CPU was zero
at the OS process-time resolution, not evidence of absolutely no CPU work.

Raw report: `build/performance-experiments-20261029-retention.json`; SHA256
`5fa2aa62712fca996c26efc6f8ffb4f4aa75b39b170f6906b9c6416c463641bc`.
All raw samples, operation counts and checkpoint snapshots are in the report.
The reports/logs are Git-ignored and are not installed into the running app.

Read-only checks before and after the experiments confirm unchanged system
proxy settings and Clash Verge/Mihomo PIDs/start times; no experiment child
remains. This is not a continuous internet-connectivity test or full route/DNS
audit. The harness itself does not modify those settings.

Final verification passes both `go test -count=1 ./...` and
`go test -tags=with_gvisor -count=1 ./...`, plus `go vet -tags=with_gvisor ./...`.
Four new unit regressions pass three consecutive times: snapshot validation,
poll accounting/failure/idempotent stop, in-flight read join and serialized IPC.
`git diff --check` passes. Published core/helper hashes and the clean Mihomo
submodule are unchanged. This increment edits tests/docs only; Flutter's prior
530 passing tests and 13 existing analysis infos were not repeated this turn.

## Next Implementation Boundary

The next lightweight-statistics increment should expose a versioned
connection-inspection contract rather than modify forwarding or shorten UDP
timeouts based on these numbers. Start with allocation/serialization profiling
of the existing wrapper snapshot and a compact counter/update response that
retains a full-snapshot fallback. Preserve live IDs and final byte counts;
explicitly resynchronize after core restart, dropped updates or close/reload.
Keep any event/tombstone queue bounded and avoid blocking packet forwarding on
UI consumption. Validate TCP/UDP close/restart races before wiring it into the
existing connection screen, then compare the same 128-connection workload.

No such delta API, process cache, QoS scheduler or memory optimization is
implemented by this measurement increment. Do not advertise measured CPU/RSS
savings until the changed production path and controlled comparison both pass.

The subsequent correctness-focused Go cursor API increment is documented in
`.agents/connection-updates.md`. Its first microbenchmark reveals a service-time
regression despite smaller wire packets, so Flutter activation remains gated.

## End-to-End Dart/Rust Inspection A/B - 2026-10-30

The opt-in `test/core/connection_inspection_performance_test.dart` measures the
production Rust named-pipe transport plus CoreController/Dart decode and merge
against the current full `getConnections` path. It does not activate the UI,
change Go/Rust production code, replace published binaries, manage the helper or
Clash Verge, or modify proxy/DNS/routes/TUN.

Three fresh-child alternating pairs exercise 128 validated loopback TCP records,
one sequential 64 KiB echo worker, a cold first read, eight stable reads, eight
half-membership replacement rounds, eight full-membership replacement rounds, and
a 35-second no-poll quiet/resync window. Each result is checked against a strict
full snapshot. Read time includes core, IPC, outer JSON, inner legacy model decode
or typed incremental decode/merge. Response bytes include the four-byte frame
prefix and exclude requests/events. Child-only Windows CPU/RSS is sampled at about
200ms; RSS is not live heap. This is Flutter JIT, not Release/AOT UI.

Report: `build/inspection-perf-v2-20261030-162803.json`; SHA256
`0fff16822b1dcad54285771caaaba7175e0686bbac0d3312fd7a99270acc84b8`.

| Condition | Legacy full | Incremental session | Interpretation |
| --- | ---: | ---: | --- |
| Stable read P50 | 4.59-5.52 ms | 1.47-1.94 ms | lower in this workload |
| Stable response P50 | 104.6 KB | 10.85 KB | about 89.6% lower |
| Half replacement read P50 | 5.35-6.21 ms | 3.38-4.09 ms | lower, packet about 55.1 KB |
| All replacement read P50 | 5.19-5.68 ms | 5.44-6.08 ms | no reliable benefit |
| Stable echo rate | 131.56-181.66 MiB/s | 125.02-139.01 MiB/s | not conclusive |
| Quiet-end child RSS | 35.61-37.40 MiB | 37.68-38.21 MiB | incremental 0.63-2.08 MiB higher |

All-replacement packets were about 100.4 KB, near the 103.1 KB legacy response,
because they carried upserts/removals. Stable packets carried 128 counter updates
and no upserts. Cold reads varied 4.72-16.33 ms. These data do not establish a
forwarding or memory improvement and do not justify UI activation.

### Decision

Keep the production page on the full path. Next: add a bounded churn/full-resync
policy, profile high-churn allocations and service time, repeat Release/AOT or
production-like client measurements, and measure retained Dart objects. Only then
wire explicit owner lifecycle/disposal, hidden-page and reconnect coverage. Raw
report/logs are Git-ignored; reproduction and limitations are in
`build/inspection-performance-draft.md`.

## Bounded Churn/Full-Resync A/B - 2026-11-02

The Go inspection endpoint now emits a full resync when a snapshot has at least
16 records and >=75% of next records need upserts. Removed records are excluded
from that ratio, preserving the measured half-replacement delta advantage. Full
policy packets carry only upserts and an empty base cursor. The rule is an
adaptive response-shape heuristic, not a claim that four stable records always
cost less than their removals or that all serialization is avoided.

Report: `build/inspection-perf-churn-policy-20261102.json`; SHA256
`3f346e1330021a018cf81328519bb337656f6d9983babe1bc344ed53414b0146`.
Candidate core: `QuanClashCore-churn-policy-20261102.exe`, SHA256
`1c8588787ae74e0ecbd8721c8bb1109b8331a34967fd7635c452f82e21f51e51`,
built with `CGO_ENABLED=0`, `-tags=with_gvisor`, `-ldflags="-w -s"`,
GOOS windows/GOARCH amd64. The Rust DLL and production Dart/IPC harness match
the prior bundle. Three alternating fresh-child pairs still use 128 loopback TCP
records, eight stable polls, eight 64-record and eight 128-record replacements,
plus a 35-second no-poll quiet window.

The stable path remains 1.364-1.744 ms and 10.852 KB versus legacy
4.364-5.511 ms and about 104.6 KB. Half replacement remains 3.628-4.150 ms and
about 55.1 KB versus 5.396-6.527 ms and about 103.2 KB. All replacement now
returns about 87.6 KB and takes 4.983-5.353 ms versus legacy 5.424-5.679 ms,
rather than the prior about 100.4 KB delta. This is a 4.77%-12.26% read reduction
for this stage, not a general throughput result. Cold reads and forwarding rates
remain noisy; quiet child RSS is still 0.332-2.043 MiB higher for incremental.
Do not infer RSS savings or UI responsiveness improvements.

The page stays on full snapshots. Next gates are Release/AOT or production-like
measurement, cold/open and retained-Dart-object accounting, then explicit owner
lifecycle/disposal and hidden-page/reconnect integration. TrafficClass/QoS and the
visual redesign remain later work.
