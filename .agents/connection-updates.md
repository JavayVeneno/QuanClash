# Connection Update API - Schema 1

## Delivery State

The Go action `getConnectionUpdates` is implemented in
`core/connection_updates.go`. This is a bounded inspection optimization, not a
completed lightweight-statistics or forwarding change. Detached field comparison
improves stable-record costs, and the adaptive churn policy returns full resync
when at least 75% of a nontrivial snapshot needs upserts. Cold initial snapshots
still cost more than legacy in measured runs. Desktop named-pipe integration
passes; Android shares action dispatch but NDK/device acceptance remains pending.

The current Flutter connection screen still uses `getConnections`. A preparatory
Dart action/interface, strict typed decoder, immutable merger and opt-in
serialized session are present.
No production refresh consumer or UI activation exists. The new endpoint is
not enabled in the existing app, and old `getConnections` remains unchanged.
Do not switch the screen until service-side overhead and client merge/recovery
coverage meet acceptance criteria.

## Wire Contract

Send the action with a JSON string as `data`:

```json
{"id":"inspection-1","method":"getConnectionUpdates","data":"{\"schemaVersion\":1,\"cursor\":\"\"}"}
```

The response's action `data` is a structured object, not a second JSON string.
Requests are limited to 256 bytes. Schema 1 is required; unknown fields, null
cursor, invalid cursor shape and trailing JSON are rejected through a generic
IPC error. Cursor is optional on the first request, otherwise an opaque
32-character hexadecimal token. Clients must not interpret or synthesize it.

Response fields:

| Field | Meaning |
| --- | --- |
| schemaVersion | 1; reject unsupported response schemas |
| status | `ready`, `inactive`, or `fallback-required` |
| full | Whether this packet replaces the entire client inspection map |
| baseCursor | Empty for full packets; previous cursor for a delta |
| cursor | New opaque token on ready packets, empty otherwise |
| sampledAt | UTC observation-start timestamp, not a packet/event timestamp |
| uploadTotal / downloadTotal | Sampled manager totals, not sums over a transactionally frozen map |
| upserted | Full legacy-compatible TrackerInfo objects for new/changed metadata |
| updated | Absolute `{id, upload, download}` counters, not counter increments |
| removed | `{id, upload, download, finalCountersVerified:false}` using last observed counters |

All three lists are non-null, with deterministic ID ordering. Upserts contain
the same inspection fields as legacy full records, including metadata, start,
chains, provider chains and rule details. Ordinary count-only changes avoid
resending these fields. Each query compares every JSON-visible metadata field,
start, chains, provider chains and rule details against detached typed data.
Only new/changed records are serialized. Nil versus empty slices and in-place
slice mutations are detected. This is field equality, not pointer identity or
a hash; late metadata changes still produce full upserts.

## Client Merge and Recovery Requirements

1. `ready` + full: replace the local map exclusively with upserts. No old
   entries survive a full packet; then store its cursor.
2. `ready` + delta: require `baseCursor` to match the last accepted cursor.
   Apply full upserts, replace absolute counters of existing IDs, then remove
   IDs. Missing updated IDs, invalid records or an inconsistent cursor require
   a fresh full query; do not advance cursor after a partial merge.
3. `inactive`: clear local inspection state and cursor, never show stale live
   connections. This is returned if the core is uninitialized or unconfigured.
4. `fallback-required`: do not interpret empty lists as zero connections. Drop
   the incremental cursor and use the existing full-snapshot action. Do not
   repeatedly attempt the incremental endpoint in a tight loop.
5. Error/timeout/late response: do not apply a partial result. Resending an old
   cursor safely causes full resynchronization if the server already advanced.
   A future Dart consumer must serialize refreshes and discard obsolete replies
   after stop/restart, navigation disposal or a newer refresh.

Fallback means using the legacy `getConnections` full-snapshot action, including
compatibility with core binaries that do not expose this new action. It does
not mean downgrading the Mihomo commit or replacing the running core binary.

The endpoint stores only the latest snapshot globally, not one cache per
client. Another client, lost response, missing/wrong cursor or >=30-second idle
gap causes full resynchronization. Clock reversal also causes a full packet.
Successful initialization, listener start/stop, config update/reload and
shutdown invalidate the baseline. Rejected parsing leaves the cursor intact.
Explicit close is observed as a removal on the next scan; resolver reset is
observed from actual manager membership, not assumed to close every flow.

## Bounded State and Accounting Limits

- One cache of at most 4096 records, with an 8 MiB charged budget:
  twice static JSON bytes + ID bytes + 1024 bytes per record + 16 bytes per
  metadata/chain slice element. Typed comparison data is charged as well as
  detached JSON. The byte cap can precede the record cap. This is an accounting
  budget, not an assertion that process RSS or all Go map/scratch overhead is
  exactly 8 MiB. Previous/next snapshots and response copies coexist briefly.
- Exceeding either cap clears the baseline and returns `fallback-required`,
  never a silently truncated set. A single oversized record can allocate
  scratch while encoding before exceeding the retained-cache limit.
- The 30-second expiry is checked on the next query, not by a background
  timer. A bounded dormant cache remains until the next query or lifecycle
  invalidation; there is no additional idle polling/goroutine or per-client
  tombstone journal.
- The cache retains detached JSON, typed comparison data and sampled integer
  counters, not trackers, sockets or references to mutable metadata/slice objects.
  Raw source/destination address objects (excluded from JSON) are discarded.
  Strings are cloned on metadata changes so substrings do not pin arbitrarily
  large original backing buffers. Slice clones preserve nil/empty differences.
- Snapshot collection uses the existing manager's weakly consistent Range:
  concurrent byte transfer, connection creation/closure and metadata updates
  are not a transactionally frozen event stream. The next poll reconciles
  membership. No new forwarding hook, process lookup or GC is introduced.
- Connections that open and close between polls can be absent altogether.
  A disappeared tracker cannot supply exact final counts through Range.
  Removal counts are explicitly last-observed, not a final bill. Precise
  closing/quota accounting requires a separate bounded lifecycle mechanism.
- Global totals can change/reset independently of live connections. Clients
  must replace absolute counters, not infer deltas or quotas from this API.

## Verification - 2026-10-29

- Unit tests cover request validation, legacy-compatible full records, detached
  nested metadata/chains, adds/count changes/metadata upserts/removal semantics,
  missed replies/multiple clients/TTL/clock reversal/reset, rejected reload,
  successful reinitialization, bounds, duplicate/invalid observations and
  concurrent cache clients.
- Three isolated Windows named-pipe runs pass: request rejection, TCP/UDP
  additions, TCP counter-only changes/removal, stale cursor full resync,
  resolver reset, listener restart, DNS forwarding and inactive shutdown state.
  Only a few local echo/DNS requests are issued, not a throughput load.
- Final `go test -count=1 ./...`, `go test -tags=with_gvisor -count=1 ./...`
  and `go vet -tags=with_gvisor ./...` pass. New connection regressions also
  pass three consecutive runs; `git diff --check` passes. Cross-builds pass for Linux amd64/arm64,
  macOS amd64/arm64 and Windows arm64 with `with_gvisor`, CGO disabled.
- New Windows artifact is only `build/QuanClashCore-updates.exe`; SHA256
  `576f5cb76d2a39f76d50a260b0201884c55f434925bdd469ddfea4ab7e14299b`.
  Published core/helper artifacts are not replaced. Mihomo stays clean at
  `8380d0e7462f061a964323e9bf3129a236fcc5d5`.
- A read-only check matches system proxy and Clash Verge/Mihomo PID/start time
  to the prior experiment reference; no updates-test child remains. No system
  networking is changed by the implementation or its isolated smoke test.
- Android lib/device, race-detector acceptance, a future Dart merger and real
  UI/IPC performance A/B remain pending. Flutter is unchanged this increment;
  its prior 530-test result is not a newly repeated Flutter run.

## Microbenchmark and Profiling Gate

Three synthetic 128-record runs (Go 1.27.0 windows/amd64, i7-13700HX), one-second
benchtime per subtest. Legacy serializes a full snapshot; delta scans all
records and serializes count-only updates. Timings include their respective
collection/encoding work, not IPC or Flutter. These are descriptive ranges,
not packet-forwarding throughput or live-process RSS. Counters increase across
benchmark iterations, so encoded digits can vary slightly.

| Path | Time (microseconds/op) | Allocated bytes/op | Allocs/op | Encoded response bytes/op |
| --- | --- | --- | --- | --- |
| legacy full | 377.7-413.7 | 478276-481463 | 1559-1560 | 83774 |
| delta count-only | 691.9-788.4 | 269250-269458 | 2862 | 9728-9729 |

The wire packet is about 88% smaller and allocated byte volume lower, but
service-side duration and allocation count are worse. Do not advertise CPU,
latency or RSS savings, or enable this endpoint in the screen based on wire
size alone. Initial/full packets and metadata-heavy churn need their own
measurements before activation as well.

CPU/allocation profiles of a separate two-second delta run point to repeated
JSON struct encoding, cloning, temporary maps and UUID string construction.
`observeConnection` accounts for about 60% of cumulative sampled allocated
space in that run. Profiles are samples across the whole benchmark process,
not per-request guarantees. Run-to-run timing is variable; the profile run is
not merged into the three comparison ranges.

Artifacts (Git-ignored): `build/connection-updates-benchmark.log`,
`build/connection-updates-profile.log`, `build/connection-updates-cpu.pprof`,
`build/connection-updates-alloc.pprof`, `build/connection-updates-smoke.log`.

## Cached Comparison Follow-Up - 2026-10-29

Implemented in `core/connection_updates.go`:

- Compute ID once per scan record, pre-size the next map, and append scalar
  counters with `strconv.AppendInt` instead of formatting temporary strings.
- Retain immutable typed comparison data beside JSON. Unchanged metadata
  reuses that data; counter updates replace sampled integers only.
- Compare every JSON-visible upstream metadata field on every scan. Reflection-
  driven tests mutate each field individually; new upstream fields/types must
  gain coverage before an upgrade can pass. Tracker fields have the same guard.
- Serialize only new/changed metadata. Query collection accepts TrackerInfo,
  not caller-supplied raw JSON, so the former redundant `json.Valid` check is
  not needed. Marshal errors and invalid/duplicate tracker observations still
  fail without advancing cached metadata, counters or cursor.

The small ID/format/map changes alone did not pass the service gate: three
count-only runs remained 664.4-699.8 microseconds/op, 243795-244048 B/op and
2724-2725 allocations/op. Log: `build/connection-updates-small-optimizations.log`.

### Same-Build Synthetic Comparison

Go 1.27.0 windows/amd64, i7-13700HX, `CGO_ENABLED=0`, `with_gvisor`, three
one-second repetitions per subtest. The original encoding benchmark is
unchanged; additional paired workloads use separate fixtures. Counter workload
includes counter increments; cold/full/churn workloads include their respective
scan/cache/encode work. Neither includes IPC or Flutter.

| Path / workload | Time (microseconds/op) | Allocated bytes/op | Allocs/op | Wire bytes/op |
| --- | --- | --- | --- | --- |
| legacy full, original fixture | 368.7-463.2 | 480686-481272 | 1560 | 83774 |
| updates, count-only | 102.9-113.2 | 51828-51955 | 149 | 9857 |
| legacy, initial-full comparison | 820.9-860.9 | 480548-482694 | 1560 | 83774 |
| updates, cold initial full | 939.2-1048.1 | 798677-798736 | 1977 | 83936 |
| legacy, resync-full comparison | 645.8-682.1 | 478559-483881 | 1560 | 83774 |
| updates, unchanged full resync | 229.5-248.5 | 244142-247410 | 278-279 | 83936 |
| legacy, unchanged comparison | 588.1-623.2 | 479317-481573 | 1560 | 83774 |
| updates, unchanged delta | 43.9-47.5 | 31151-31153 | 141 | 258 |
| legacy, all metadata changed | 514.8-557.7 | 478040-480969 | 1559-1560 | 83006 |
| updates, all metadata changed | 813.0-930.1 | 776392-776450 | 1968 | 83201 |
| legacy, all identities replaced | 516.5-702.5 | 480857-481914 | 1560 | 83774 |
| updates, all identities replaced | 808.9-814.7 | 801720-802120 | 1982 | 97023-97024 |

For the original stable-record comparison, count-only median service time is
about 74% lower, allocated byte volume about 89% lower, and packet bytes about
88% lower than the same-build legacy path. These are synthetic inspection costs,
not forwarding CPU, system RSS, TUN throughput or real UI responsiveness.
Timing varies considerably across workload groups; do not combine their ranges
as if captured under a fixed CPU frequency or use a single best run. Separate
fixture/counter digit counts explain the small packet-size differences.

Cold initial snapshots and high-churn responses still regress. Replacing all
identities also sends last-observed removals, so a delta packet can exceed a
full snapshot. A separate two-second allocation profile attributes about 49%
of high-churn sampled allocated space to JSON raw-object reformatting, with
full-record copies and new comparison data also contributing. Count-only
allocation samples are dominated by query maps/slices, output copies and UUID
strings, rather than repeated metadata marshaling. Profiles are process-wide
samples, not retained-cache size or per-request guarantees.

### Repeated Verification

- `go test -count=1 ./...`, `go test -tags=with_gvisor -count=1 ./...`, and
  `go vet -tags=with_gvisor ./...` pass. Focused connection tests pass three
  repetitions, including every metadata/tracker field, slice aliasing,
  nil/empty changes, raw-address exclusion, integer extremes, full-response
  isolation and failure-preserves-baseline checks.
- The rebuilt temporary Windows child passes named-pipe smoke three times:
  TCP/UDP additions, counters, removals, stale-cursor recovery, resolver reset,
  listener lifecycle, DNS forwarding and inactive shutdown.
- Linux amd64/arm64, macOS amd64/arm64 and Windows arm64 cross-builds pass
  with `with_gvisor`, CGO disabled. These are compile checks, not device tests.
- Temporary artifact: `build/QuanClashCore-updates-cached.exe`, SHA256
  `595bb4f78acedddce2e8f97ff189daca2e7032de37fb1e7dfc3f07a145be98c9`.
  Published core/helper hashes remain unchanged; Mihomo remains clean at
  `8380d0e7462f061a964323e9bf3129a236fcc5d5`.
- System proxy and Clash Verge process/start-time fingerprints match before
  and after IPC tests; no child remains. Compare HKCU from the same permission
  environment: sandbox-isolated registry values are not the host baseline.
- Android NDK/device and race-detector acceptance remain pending (no NDK or
  GCC detected locally). Flutter was not changed or rerun this follow-up.

Logs/profiles (Git-ignored): `build/connection-updates-cached-tests.log`,
`build/connection-updates-cached-final-benchmark.log`,
`build/connection-updates-cached-cpu.pprof`,
`build/connection-updates-cached-alloc.pprof`,
`build/connection-updates-cached-churn-alloc.pprof`,
`build/connection-updates-cached-smoke.log`, and
`build/connection-updates-cached-network-check.json`.

### Remaining Activation Gate

1. Reduce repeated raw-object formatting/full-record copies for cold/full/churn
   responses, or define and test an explicit adaptive full-snapshot policy.
   Keep last-observed removal semantics and all-or-nothing cursor updates.
2. Repeat paired measurements across record counts and metadata/churn ratios,
   plus real IPC polling A/B under a matching isolated forwarding workload.
   Validate retained-cache/quiet-cycle behavior, not just allocations/op.
3. Only then add the strict Dart decoder/merger and old-core/full fallback,
   regenerate action serialization, and integrate the existing connection page.
   Test stale replies, disposal/restart and missing base cursors before enabling
   it. No visual redesign is included in this phase.

## Dart Transport Preparation - 2026-10-30

`ActionMethod.getConnectionUpdates` and its generated wire mapping are present.
The shared interface accepts empty/32-hex cursors, sends schema-1 JSON string data,
returns the structured map (or null when unavailable) and sets a five-second
invoke timeout in addition to the existing connection wait. Tests cover encoding,
null versus empty-list semantics, malformed cursors and generated action mapping.
This is transport preparation only: no controller merger, background consumer,
compatibility fallback or UI activation exists. Keep the strict merge/recovery,
cold/churn service costs and real IPC/cache RSS gates above before enabling it.
## Strict Dart Decoder And Atomic Merge - 2026-10-30

`lib/core/connection_updates.dart` adds immutable ConnectionUpdatePacket,
ConnectionInspectionRecord and ConnectionInspectionSnapshot. CoreController now
returns a typed packet or errors on missing/invalid data; getConnections stays
unchanged. This is correctness preparation, NOT activation/performance acceptance.

### Validation And Preservation

- Schema/status/full/cursors/totals/list shapes are checked without numeric
  coercion. Ready cursors are opaque canonical lowercase hex from the Go encoder;
  IDs are canonical UUID strings. Duplicate or overlapping operations are refused.
- Full packets cannot contain counter-only/removal operations. Inactive packets
  are empty with zero totals. Fallback-required packets are empty with no cursor
  but MAY contain manager totals (the Go handler assigns them after overflow).
  Fallback is explicit, never interpreted as a successful zero-connection result.
- Current schema-1 metadata fields are type-checked and retained, including the
  inbound/type/DSCP/sniffHost fields absent in TrackerInfo. Nil/empty GeoIP and
  chain/provider arrays remain distinguishable. The legacy UI projection uses
  empty arrays and null for an unknown DNS mode; raw inspection preserves unknown.
  Additive unknown fields are ignored and not retained; this is not an arbitrary
  lossless JSON/event archive. Missing known fields fail rather than using defaults.
- RFC3339/Nano-shaped timestamps reject timezone ambiguity and normalized invalid
  dates. Sample time must be UTC Z; start accepts a numeric zone. The exact start
  string is retained while TrackerInfo DateTime projects to microsecond precision.
- Responses and snapshots own unmodifiable maps/lists and detached list copies.
  Input mutation cannot change accepted state. Unchanged records can share
  immutable objects across snapshots; absolute counter updates replace records.

### Atomic State And Bounds

`ConnectionInspectionSnapshot.empty().apply(packet)` returns a new snapshot:
full replaces all membership; delta requires the current base cursor, performs
upserts/absolute-counter replacement/removal, and rejects missing update/remove
IDs. Invalid packets never advance any existing records/totals/cursor. Inactive
and fallback clear state/cursor with distinguishable status; needsFull and
requiresLegacyFallback signal the next consumer operation, but do not issue it.
Counter/global-total resets are accepted as absolute values, not monotonic quotas.

Each operation list and snapshot has a 4096-record cap; packets have at most 8192
combined operations (a disjoint full replacement can add/remove 4096 each).
String lists cap at 8192 items. Retained upserts and resulting snapshots have a
16 MiB conservative charge: 1024 per record, twice UTF-16 string lengths and 16
per list item. The check happens across packets as well as within one packet.
This is an accounting bound, NOT exact heap/RSS. Input JSON/transport allocations,
map/scratch costs and coexisting old/new snapshots are not an OS memory limit;
callers retaining arbitrarily many snapshots are not bounded by this API.

### Evidence And Remaining Gates

- 34 focused tests pass three runs: strict malformed inputs, nil/empty/unknown,
  duplicates/conflicts, absolute counts/removals, immutable inputs/outputs,
  atomic failure, replay/base mismatch, count/byte limits, and a seeded 150-step
  add/metadata/count/remove sequence checked against a full-record reference.
- Native Windows fixture passes three runs through actual Rust DLL, production
  Dart transport/shared facade and private core. It uses only loopback SOCKS5 TCP
  and echo. Real additions/count-only packets are merged and compared with the
  unchanged getConnections result; removals, missed-cursor full resync, listener
  restart and inactive shutdown are exercised. No helper/app managers run.
- Node-quality native regression passes after extracting the shared isolated
  handler to `test/core/fixtures/native_core_handler.dart`. Full Flutter: 595
  passed, three opt-in tests skipped by default. Analysis: 13 original infos.
- Tested core/DLL come from the prior coordinated bundle
  `build/node-quality-release-20261030-140517-668/bundle`:
  core `99d17b3dc442997133c199e7bf76957014f1364022ecaa02b5bd45030c228a2c`,
  Rust `e208c15c0d9c3f7ffe266931fbc2af1d2e0e655990aada48e08f69d4e5fb64ce`.
  New Dart code runs in Flutter tests, not that bundle's older GUI AOT. No new
  GUI package, published core/helper or Mihomo change is made this increment.
- Pre/post proxy, DNS, routes, Verge/helper identity and published hashes match;
  no native fixture child remains. This is scoped observation, not a leak audit.
- Pending: serialized refresh/lifecycle epochs (including stale FULL responses),
  timeout/old-core/full-action fallback, UI disposal/restart integration, cold/
  churn and real IPC/retained-memory A/B gates, Android/device/native acceptance.
  The pure merger cannot know that an otherwise valid full packet is obsolete;
  do not infer lifecycle recovery from cursor validation. No default consumer,
  extra timer, performance improvement or QoS/quota feature is enabled.

Local ignored logs: `build/connection-merge-focused-{1,2,3}-20261030.log`,
`build/connection-merge-native-{1,2,3}-20261030.log`,
`build/connection-merge-full-tests-20261030.log`,
`build/connection-merge-analyze-20261030.log`,
`build/connection-merge-node-quality-regression-20261030.log`, and
`build/connection-merge-{before,after}-20261030.json`.

## Serialized Session And Compatibility Checkpoint - 2026-10-30

`lib/core/connection_inspection_session.dart` adds an opt-in, caller-driven
ConnectionInspectionSession through CoreController.createConnectionInspectionSession.
No page, manager, provider, timer-driven poller or forwarding hook uses it yet.
The existing UI remains on its unchanged full action. This completes session-level
correctness preparation, not production lifecycle integration or performance.

### Ownership And State

- Concurrent refresh() calls share the same Future<bool>; there is no queued
  poll. A later refresh uses only the last accepted incremental cursor.
- true means a new ready/inactive/unavailable state was accepted, NOT necessarily
  successful inspection. false means disabled, busy or obsolete. Check status.
  Ready legacy state can carry failure as the reason for choosing compatibility,
  while unavailable has no successful source/records/totals. Errors do not become
  successful empty connection lists; raw exception strings are not stored in state.
- reset() starts a new active epoch and clears records/cursor/legacy mode;
  disconnect() clears and disables; dispose() is terminal. Owners MUST invalidate
  BEFORE listener, config, profile or core changes. Even valid full, delta, legacy,
  error and timeout responses from the previous epoch cannot publish or pin fallback.
  Handler/controller replacement requires disposing and recreating the session.
- Reset does not queue a new request behind obsolete work. While a refresh runs,
  an active reset still shares its obsolete future. Refresh again after it settles.
  Inactive is a core endpoint state, not proof of app connectivity; the legacy
  wire format has no readiness flag, so empty legacy results do not prove inactive.
  Production owners must guard core initialization/connectivity themselves.

### Bounded Recovery

- Unsupported/missing/malformed updates or fallback-required pin legacy for the
  current epoch and try exactly one full action immediately. Subsequent refreshes
  use only legacy until reset, not repeated update/legacy retries each poll.
- Invalid merge/base/membership triggers one empty-cursor resync. If that also
  fails, publish unavailable and pin legacy for the NEXT refresh. No third action
  is sent in that refresh. Each refresh issues at most two injected reads.
- Each read has a five-second default deadline (allowed >0 and <=15 seconds),
  not a five-second total refresh deadline. Two reads can take two deadlines.
  Deadline expiry does not physically cancel native work. The session refuses
  new reads while the injected callback future is unresolved, including after
  reset, and ignores its late result/error. Once that future settles the gate
  releases. This is per-session callback admission, NOT transport cancellation,
  proof the native action stopped, a global IPC backlog bound or a timeout fix
  for an implementation that independently stops waiting for its native reply.

### Strict Legacy Decoder

CoreController.getLegacyConnectionSnapshot validates explicit connection-array
presence and nonnegative integral signed-int64 totals/counters. Go's explicit
connections:null is supported; absent totals, invalid records/IDs/times, duplicate
IDs or wrong retained-field types fail. Older optional metadata defaults, nil
chains and absent/null/unknown DNS mode are supported without interpreting an
unknown mode as normal. Retained lists are detached and unmodifiable; provider
chains and other unrecognized legacy fields are not retained in the UI projection.

The full fallback has its own larger 16384-entry list cap, allowing more than
4096 incremental members, plus the same conservative 16 MiB retained charge and
8192-item string-list cap. The byte budget may fail below 16384. No records are
truncated; exceeding the bound is unavailable. This bounds charged retained data,
not transient JSON allocation, exact heap/RSS, coexisting snapshots or arbitrarily
many session instances. The old getConnections decoder/UI is not modified.

### Verification And Next Gate

- 42 new session/legacy/facade tests plus 34 existing decode/merge tests pass three
  focused runs (76 total). Coverage includes concurrent coalescing/no queue,
  lifecycle invalidation during full/delta/resync/legacy/error/timeout, bounded
  hung callbacks, one-shot resync, epoch-pinned fallback, strict full decoding,
  immutable collections, count/retained-charge limits and compatibility defaults.
- Real Rust DLL/production transport/private core/local SOCKS TCP echo passes
  three runs: session factory/coalescing, real refresh, equality with strict full
  action, deletion, reset before lifecycle changes and inactive shutdown. The
  unsupported update callback is simulated but fallback getConnections is real
  IPC. No old binary is replaced or launched for an old-version acceptance claim.
- Node-quality native regression passes, still refusing every SOCKS destination
  locally. No Cloudflare/IPPure/public requests or app/helper managers run.
- flutter pub get --offline succeeds; full Flutter is 637 passed, three explicit
  opt-ins skipped by default (native connection/node-quality exercised separately).
  Analysis retains only the 13 original infos. git diff --check passes.
- Reused test bundle: build/node-quality-release-20261030-140517-668/bundle;
  core 99d17b3dc442997133c199e7bf76957014f1364022ecaa02b5bd45030c228a2c,
  Rust e208c15c0d9c3f7ffe266931fbc2af1d2e0e655990aada48e08f69d4e5fb64ce.
  New Dart runs in tests, not the prior bundle's GUI AOT. Go/Rust/Mihomo, published
  binaries and GUI packaging are not changed this checkpoint.
- Pre/post WinInet proxy, DNS addresses, routes, Verge/helper process identity and
  published core/helper hashes match. No private test child remains. This scoped
  safety observation is not a general DNS-leak or remote-provider audit.

Next: same-build cold/open and high-churn client+IPC service-time/bytes/retained-
charge measurement, then serialized legacy-vs-incremental loopback polling A/B
with quiet-cycle RSS/CPU observation. Keep the production connection page on full
snapshots until cold/churn and real IPC/cache gates are reviewed; add real owner
lifecycle/disposal coverage before activation. Do not infer forwarding/RSS savings
from correctness or synthetic encoding tests. TrafficClass/QoS follows those
gates; remote providers/device/GUI-helper acceptance and UI redesign stay separate.

Local ignored evidence: build/connection-session-focused-{1,2,3}-20261030.log,
build/connection-session-native-{1,2,3}-20261030.log,
build/connection-session-node-quality-regression-20261030.log,
build/connection-session-pub-get-20261030.log,
build/connection-session-analyze-20261030.log,
build/connection-session-full-tests-20261030.log, and
build/connection-session-{before,after}-20261030.json.

## Adaptive Churn Resync Checkpoint - 2026-11-02

The schema-1 server now chooses a full resync when at least 16 records exist and
at least three quarters of the next snapshot require serialized upserts (new IDs
or changed inspected fields). Removed IDs do not count toward that ratio, so a
half replacement remains a delta; removals alone also remain a delta. A full
policy response clears `baseCursor` and carries only `upserted` records, never
update/removal operations. This is a bounded heuristic for response shape, not a
measurement of exact bytes or all serialization work; every remaining delta still
has the existing stale/missing-cursor full fallback.

The new production private-core A/B report is
`build/inspection-perf-churn-policy-20261102.json`; SHA256
`3f346e1330021a018cf81328519bb337656f6d9983babe1bc344ed53414b0146`.
Candidate core SHA256 is
`1c8588787ae74e0ecbd8721c8bb1109b8331a34967fd7635c452f82e21f51e51`,
using the prior matching Rust DLL and production transport. With 128 loopback TCP
records over six alternating fresh-child runs:

| Condition | Legacy full | Incremental after policy |
| --- | ---: | ---: |
| Stable read P50 | 4.364-5.511 ms | 1.364-1.744 ms |
| Stable response P50 | 104.597-104.600 KB | 10.852 KB |
| Half replacement P50 | 5.396-6.527 ms | 3.628-4.150 ms |
| Half response P50 | 103.187-103.193 KB | 55.131-55.134 KB |
| All replacement P50 | 5.424-5.679 ms | 4.983-5.353 ms |
| All response P50 | 103.061-103.064 KB | 87.605 KB |

All-replacement reads were 4.77%-12.26% lower than legacy in these pairs, but the
previous 100.4 KB delta was not; the policy worked as intended for this workload.
Cold first reads ranged 4.676-15.757 ms for incremental and 5.114-14.702 ms for
legacy, so no cold-path improvement is claimed. Quiet-end child RSS remained
0.332-2.043 MiB higher for incremental in these runs. The test is Flutter JIT
with loopback traffic and one sequential worker, not Release/AOT, forwarding,
remote-node, heap/RSS or device acceptance.

Verification: Go focused tests x3, full tagged Go suite, vet, gofmt and five
desktop cross-builds pass; real private-core/Rust IPC correctness passes x3;
full Flutter is 642 passed with four opt-in tests skipped by default; analysis
retains the 13 original infos. Pre/post WinInet proxy, DNS addresses, routes,
Verge/helper identity and published core/helper hashes match. No private child
remains. No packaged binary or GUI AOT was replaced. The connection page remains
on `getConnections` until Release/AOT, cold/open, retained-Dart and
owner-lifecycle gates are reviewed.
