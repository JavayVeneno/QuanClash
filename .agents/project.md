# Project Context

QuanClash is a multi-platform proxy client based on ClashMeta (mihomo), built with Flutter. It is a desktop-focused fork of [FlClash](https://github.com/chen08209/FlClash) with an in-app frosted-glass visual system, top icon navigation and a tray panel. It supports Android, Windows, macOS, and Linux.

## Version Notes

- CI uses Flutter 3.44.4 (see `.github/workflows/build.yaml`), the source of truth for release builds.
- `pubspec.lock` requires Flutter `>=3.44.0`.
- Dart SDK constraint: `>=3.8.0 <4.0.0`.

## Build Dependencies

Linux:

```bash
sudo apt-get install libayatana-appindicator3-dev libkeybinder-3.0-dev
```

Windows:

- GCC and Inno Setup.
- `ANDROID_NDK` env var for Android builds.

macOS:

```bash
npm install -g appdmg
```

## Core Roadmap

QuanClash keeps Mihomo as the compatibility and data-plane base while building its
own traffic-control and node-quality layers above it.

### Delivery Goals

- Performance: bounded memory growth, low idle overhead, stable TCP/UDP/TUN behavior,
  and repeatable benchmarks.
- Functionality: process/UID traffic classes, connection limits, upload/download
  shaping, priority scheduling, protocol compatibility, and node-quality checks.
- Quality: every core change must include regression coverage for desktop and mobile
  integration where practical.
- Delivery order: finish core, functionality, and performance acceptance first.
  Keep the current UI; visual redesign is deferred to the end of this cycle.

### Phases

1. Core synchronization and baseline: update the Clash.Meta snapshot, record the
   upstream/local boundary, compile all supported targets, and establish RSS/CPU/
   latency/UDP benchmark baselines.
2. DNS leak hardening: make the effective DNS path explicit, remove accidental
   system-DNS fallbacks, and add effective-config regression tests.
3. Lightweight statistics: separate forwarding fast paths from connection inspection,
   reduce full snapshots, cache process lookup, and bound UDP/connection state.
4. TrafficClass: classify by process, path, UID, package, rule, network, and proxy.
5. QoS: add connection limits, shared token-bucket shaping, and priority scheduling.
6. Protocol matrix: validate TCP/UDP/IPv4/IPv6/mux/chain/TUN/DNS/platform behavior
   before adding new protocol types.
7. Node quality: extend latency tests with Cloudflare network probes and opt-in
   IPPure/IPure provider adapters for egress IP risk information.

### Current Sync Target

- Previous embedded core / rollback reference: `80362fc1895dcf60b79b562896653046e0687413`
  (2026-01-21 snapshot).
- Selected `origin/FlClash` target: `8380d0e7` (`flclash/v0.9.0`,
  2026-10-12).
- These commits are not on a linear history. Treat the first update as a core
  replacement audit: preserve the current pointer for rollback, update the
  submodule only after checking API/build compatibility, and do not mix QoS
  changes into the synchronization change.

### Phase 0 Status

- The submodule is switched to `8380d0e7` and is clean.
- The root `core` module dependency graph is synchronized with `go mod tidy`.
- Mihomo's own `go test ./...` passes, and the QuanClash wrapper's
  `go test ./...` passes after adapting the latency hook to the new
  `timedOut` parameter.
- Windows release core and Rust helper builds pass.
- Linux and macOS amd64/arm64 plus Windows arm64 cross-compilation pass.
- Flutter full tests pass (530 tests on 2026-10-29). Analysis passes with 13
  existing info-level diagnostics; YAML is now a direct dev dependency.
- Windows named-pipe lifecycle, HTTP forwarding, TCP/UDP DNS and rejected
  reloads pass three consecutive isolated integration runs.
- Linux/macOS amd64/arm64 and Windows arm64 cross-builds pass with DNS
  diagnostics.
- Android c-shared build and runtime TUN/FFI smoke tests remain pending because
  the local Android NDK is not installed.
- An initial Windows loopback idle/TCP/churn/UDP/DNS CPU/RSS/RTT reference
  passes three complete repetitions. Idle RSS medians are 22.68-23.00 MiB;
  post-load idle is 35.36-35.80 MiB. TCP rate dispersion exceeds 2x, so this
  is exploratory data, not full performance acceptance or an improvement claim.
  Methodology and ranges: `.agents/performance-baseline.md`.
- Inspection polling A/B (128 TCP records) and a four-minute, three-cycle
  TCP/UDP/DNS retention test pass. All 16 UDP trackers expire by the 60-second
  quiet observation each cycle. RSS still grows across cycles; polling rate
  changes are inconsistent, so no savings or long-run memory bound is claimed.
  Results and next implementation boundary: `.agents/performance-experiments.md`.
- Stable concurrent/hour-scale, TUN, IPv6, process lookup, sniffing, mux and
  remote-protocol baselines remain pending; build success is not performance.

### Phase 1 Status

- Effective DNS generation no longer appends system DNS implicitly; explicit
  opt-in and complete subscription DNS preservation have regression coverage.
- Invalid config parsing preserves the active in-memory DNS/routing policy.
- Configuration acknowledgment is required before caching its hash or invoking
  the initial listener startup callback. Missing responses are errors.
- Read-only `getDnsDiagnostic` core action and typed Dart facade report the
  active parsed DNS paths. This configuration snapshot is not a leak verdict.
- Explicit `compatible`, `proxyOnly` and `custom` DNS safety modes are wired
  into settings and profile generation. Proxy-only validates the pending
  config's static proxy graph after custom overrides, pins main/fallback/policy
  and direct-traffic resolvers to it, requires explicit IP bootstrap, and
  rejects ambiguous fragments and unverified/dynamic target groups.
- Invalid strict profiles produce no usable YAML/hash, are not exported or
  applied, and cannot invoke listener startup. Bootstrap stays directly dialed
  and is disclosed; this is not a claim of zero direct DNS packets.
- DNS diagnostic presentation is available in the existing settings UI. It
  reads the connected, initialized core on entry, manual refresh, or config
  events, clears stale results, and discloses unverified paths and bootstrap.
- On-device leak tests, dynamic-provider runtime enforcement, and full
  performance acceptance remain pending. The generator does not enforce policy
  on independently edited YAML/external-controller configs.

### Phase 2 Status

- A schema-1 Go connection update action is implemented, with bounded cursor
  state, full resynchronization, counter-only packets and explicit last-observed
  removal accounting. Legacy full snapshots remain supported and active in UI.
- Detached field comparison now avoids reserializing stable metadata. In three
  same-build 128-record synthetic runs, count-only encoding takes 102.9-113.2
  microseconds versus legacy 368.7-463.2, with 149 versus 1560 allocations/op.
  Every metadata/tracker field and mutable slice change has regression coverage.
- Full Go tests/vet, three rebuilt isolated Windows IPC runs and five desktop
  cross-builds pass. Cold initial snapshots and high-churn responses still cost
  more than legacy; strict Dart merge/UI activation and real IPC/RSS acceptance
  remain gated. These are
  inspection microbenchmark gains, not forwarding or RSS improvement claims.
  Contract/results: `.agents/connection-updates.md`.

### Node Quality Status

- Manual Cloudflare/IPPure checks use a shared core action, strict typed decoding
  and a separate icon next to latency. Opening sends nothing; IPPure requires
  dialog-local opt-in. Default latency/ranking and the visual system stay unchanged.
- Egress IP, edge/TTFB and risk/type remain separate. Missing/unverified IPv6
  scores are unknown; no purity percentage, data-center inference or no-leak claim.
- Flutter full suite passes 556 tests (2026-10-30); analysis retains only 13
  existing infos. Go tests/vet, five desktop cross-builds and three isolated
  Windows IPC runs pass. The
  local SOCKS fixture refuses public destinations; Verge/system proxy fingerprints
  are unchanged. Release artifacts are not replaced. Real remote provider,
  Android/device and native-runtime acceptance remains pending.
- Contract/evidence: `.agents/node-quality.md`. Resume connection inspection and
  TrafficClass/QoS after node-quality acceptance; UI redesign remains last.

Detailed milestones and acceptance criteria are documented in
`.agents/roadmap.md`.

### Coordinated Delivery Checkpoint - 2026-10-30

- The coordinated Windows Release bundle builds without replacing published
  core/helper files. CMake rebuild/config/staging tests pass; Debug builds no
  longer terminate helper processes. Token consistency is statically checked.
- Fixed two shutdown waits: FRB producer-stop before stream cancellation, and
  Rust joining outside STATE. Real bundle DLL/core + production Dart transport
  pass three complete refused-loopback node-quality runs including teardown and
  repeated listener start/stop. No detached-reaper workaround is retained.
- Flutter: 561 passed, two explicit opt-in tests skipped by the default suite;
  both are separately exercised. Analysis: 13 existing infos. Rust: two tests and
  clippy pass. Go default/gVisor tests and tagged vet plus three smoke runs pass.
- System proxy, DNS addresses, route table, Verge/helper process identity and
  published core/helper hashes match pre/post fingerprints. No test child remains.
- Only the Dart connection-update transport entry is prepared; no merger or UI
  activation. Next: strict merge/recovery and IPC/cache performance gates, then
  TrafficClass/QoS. Real remote providers and GUI/helper/device acceptance remain
  pending; UI redesign remains last. Evidence: `.agents/node-quality.md`.
### Typed Connection Inspection Checkpoint - 2026-10-30

- Strict typed packet decoding and immutable all-or-nothing Dart snapshot merge
  are implemented behind CoreController; the existing connection page remains
  on full snapshots. Counts are absolute and removals last observed, never quotas.
- 34 focused tests pass three runs, including 150 seeded mixed updates and count/
  retained-charge bounds. Real Rust IPC/local TCP echo passes three runs and
  matches the unchanged full action; node-quality native regression also passes.
- Full Flutter: 595 passed, three opt-in tests skipped by default; analysis keeps
  13 original infos. Core/Mihomo/published artifacts and system network settings
  are unchanged. Prior core/DLL are reused only in tests, not rebuilt GUI AOT.
- Next: serialized refresh and lifecycle epoch/recovery, old-core/full fallback,
  then IPC/cache/cold/churn performance gates before enabling the consumer.
  TrafficClass/QoS follows; remote provider/device acceptance and UI redesign
  remain separate later work. Contract/evidence: `.agents/connection-updates.md`.

### Serialized Inspection Session Checkpoint - 2026-10-30

- Opt-in ConnectionInspectionSession serializes/coalesces refreshes, invalidates
  stale full/delta/legacy/error/timeout results by owner-controlled lifecycle
  epoch, bounds recovery to two reads/refresh and pins full-action compatibility
  until reset. It adds no production polling or connection-page activation.
- Strict legacy full decoding prevents missing/malformed data becoming an empty
  success, with independent larger count cap and bounded retained charge. Timeout
  admission lasts until the injected read future settles; it does not cancel or
  certify completion of native work. Owners still must wire lifecycle invalidation.
- Verified: 76 focused tests x3 (42 new), native loopback IPC x3, node-quality native
  regression, 637 full Flutter passes/three default-skipped opt-ins and 13 original
  analysis infos. Offline pub get and diff checks pass. Pre/post system network,
  Verge/helper identity and published-file fingerprints match; no fixture remains.
- No Go/Rust/Mihomo/published binary or GUI AOT rebuild in this checkpoint.
  Fallback means the legacy action, never a core-version downgrade. CF/IPPure
  remote acceptance remains pending; no public quality probes run.
- Next: cold/open and churn service-time/bytes/client-cost measurements plus
  serialized legacy/incremental IPC and quiet-cycle retained-memory A/B gates.
  Only after reviewing them wire real page lifecycle/disposal and activate the
  consumer. TrafficClass/QoS follows; visual redesign remains last.
  Detailed contract, callback-deadline limits and evidence: .agents/connection-updates.md.

### End-to-End Inspection Performance Checkpoint - 2026-10-30

Production Rust/Dart A/B confirms stable counter updates are smaller/faster, but
all-identity replacement is near full-snapshot size and quiet child RSS is sometimes
higher. The incremental page remains disabled. Next is bounded churn/full-resync
policy, allocation/service-time profiling, Release/AOT and retained-Dart evidence.

### Adaptive Churn Resync Checkpoint - 2026-11-02

- The Go connection update action now uses a bounded >=75% record-upsert rule
  (minimum 16 records) to return full resync instead of a near-full delta.
  Removals alone do not trigger it; full policy packets clear `baseCursor`.
- Private Windows core/Rust/JIT A/B with 128 loopback TCP records keeps stable and
  half-replacement gains. All replacement falls from about 100.4 KB to 87.6 KB
  and 4.983-5.353 ms versus legacy 5.424-5.679 ms. Cold time, forwarding rate and
  quiet RSS are not improved; incremental child RSS remains 0.332-2.043 MiB higher.
- Full Go tests/vet and five desktop cross-builds pass, real IPC x3, 642
  Flutter tests (four default-skipped opt-ins) and analysis with 13 original
  infos pass. Host proxy/DNS/routes, Verge/helper identity and published files
  match pre/post fingerprints. No packaged runtime or GUI AOT was replaced and
  the connection page remains on full snapshots.
- Next: Release/AOT or production-like inspection measurement, cold/open and
  retained-Dart accounting, then owner lifecycle and page activation. TrafficClass/
  QoS follows; visual redesign stays last.

### TrafficClass Classification Foundation - 2026-11-02

- `core/traffic_class.go` now parses an immutable schema-1 class set and matches
  process name/path, UID, package and TCP/UDP metadata. Dimensions are ANDed,
  values within a dimension are ORed, and configuration order decides the first
  match; priority does not affect precedence.
- The parser rejects unknown fields, duplicate IDs/values, empty matches and
  oversized input, with 256-class/128-value/64-byte-ID/1024-byte-text limits.
  Windows process names/paths are case-insensitive; Unix paths remain exact.
- No core action, config transport, forwarding hook, accounting, rate limiter,
  queue or UI consumes the matcher yet. Seven tests x3, full Go tests/vet and five
  desktop cross-builds pass. The next gate is detached configuration lifecycle and
  post-process-resolution classification; QoS remains separate.

### TrafficClass Versioned Preparation - 2026-11-02

- Go shared actions `getTrafficClassState` / `setTrafficClasses` now store an
  immutable volatile class set with opaque revision/CAS. Stale, invalid and
  concurrent same-base writes cannot overwrite accepted state; explicit empty
  sets clear it. Summaries omit selectors and always disclose enforcing=false.
- Setup/update/listener lifecycle changes clear and invalidate state; rejected
  setup preserves it, initialization/shutdown is inactive. Shutdown is serialized
  with runLock. No classification data-plane hook or persisted policy is active.
- Identity correction supersedes the initial matcher draft: UID needs explicit
  validity and package needs a separate resolved value, not overloaded Metadata.
  Absolute platform paths are required; Unix backslashes remain filename text.
  Duplicate/case-aliased JSON keys, null fields/UIDs and empty dimensions reject.
- Verified: 17 focused Go tests x3, full tagged Go tests/vet/gofmt, five desktop
  cross-builds, new private Go action IPC x3, existing Rust/Dart connection IPC x3,
  node-quality native regression, 642 full Flutter passes/four default skips and
  13 original infos. Host network/process/published-file fingerprints match.
- Next: typed Dart facade and epoch/acknowledgment reconciliation, then explicit
  identity adapter and diagnostic-only classification. No actual QoS, UI change,
  memory/throughput gain or Android/race-runtime acceptance is claimed. Existing
  connection-page activation gates remain. Contract: `.agents/traffic-class.md`.
