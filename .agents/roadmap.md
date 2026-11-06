# QuanClash Core Roadmap

This roadmap covers the server/core side of QuanClash. The product UI should
consume stable core APIs instead of reaching into platform-specific core
implementations.

## Principles

- Keep Mihomo for Clash compatibility, protocol implementations, DNS, TUN, and
  the basic data plane during the first delivery cycle.
- Put QuanClash-specific differentiation in explicit layers: TrafficClass,
  QoS, node quality, and lightweight statistics.
- Do not call Go goroutines "threads" in the product model. The supported
  control units are process, UID/package, connection, and mux logical stream.
- Do not trade away buffer pooling, bounded queues, or zero-copy paths for
  convenience.
- Never make third-party IP-quality checks part of the core forwarding fast
  path.
- Keep the current UI while core/features/performance work is in progress;
  visual redesign is deferred to the final delivery phase.

## Phase 0 - Core Synchronization and Baseline

### Work items

- Preserve the current core pointer:
  `80362fc1895dcf60b79b562896653046e0687413`.
- Audit the available `origin/FlClash` target before changing the submodule
  pointer. The current local remote-tracking target is `8380d0e7`.
- Switch the submodule to the target in a reversible, clean checkout.
- Record the upstream commit, local patches, Go version, and dependency changes.
- Compile the Go core for Windows, Android, macOS, and Linux where toolchains are
  available.
- Run the core unit tests and the repository's core integration checks.
- Capture a baseline for idle, TCP, UDP, TUN, DNS, process lookup, sniffing, and
  mux workloads.

### Acceptance criteria

- No uncommitted files inside `core/Clash.Meta` before the switch.
- Parent Flutter code still builds against the selected core APIs.
- Desktop socket mode and Android FFI mode both start and stop cleanly.
- Existing DNS, TUN, proxy-group, process-rule, and traffic-statistics paths
  pass regression checks.
- The new core pointer is isolated from later QoS changes.

### Current status

- The core pointer is now `8380d0e7462f061a964323e9bf3129a236fcc5d5`
  (`flclash/v0.9.0`, 2026-10-12).
- The old pointer `80362fc1895dcf60b79b562896653046e0687413` remains
  recoverable and is the rollback reference.
- `core/go.mod` and `core/go.sum` were regenerated with `go mod tidy`; notable
  dependency movement includes `metacubex/http` 0.1.6 -> 0.1.8,
  `metacubex/sing` 0.5.7 -> 0.5.8, `metacubex/quic-go` 0.59.1 -> 0.61.1,
  and new `mipstack`, ZeroTier, EasyTier, and JLS dependencies.
- The latency hook now handles the new `timedOut` callback argument. A timed-out
  test is reported as `-1`, never as a valid delay.
- Passed: `go test ./...` in `core/Clash.Meta`; `go test ./...` in `core`;
  Windows release build of `QuanClashCore.exe` and
  `QuanClashHelperService.exe`; cross-compilation for Linux amd64/arm64,
  macOS amd64/arm64, and Windows arm64; `flutter analyze --no-fatal-infos`.
- Final Windows artifacts: `QuanClashCore.exe` is 70,752,768 bytes with SHA256
  `c379c8727d404982023613491ab7eaff6f45877e36b349edfea5647e61cbb812`; the
  Rust helper is 806,912 bytes with SHA256
  `38866dcfe624a4fb420cd88934687bc236b32a1e222e8b46ca1db4449ff4dfb3`. The
  previous Windows core artifact was 55,281,152 bytes, so the wider protocol
  set added about 15.5 MB (28%) before any size optimization. Track this
  separately from runtime RSS.
- Passed: the Windows named-pipe smoke test three consecutive times. It covers
  init/setup/start/stop/shutdown, HTTP forwarding, TCP and UDP DNS, rejected
  reloads, unchanged diagnostic output after rejection, and an inactive
  diagnostic after shutdown.
- Passed: Linux amd64/arm64, macOS amd64/arm64, and Windows arm64 cross-builds
  with the DNS diagnostic API included.
- Pending: Android NDK/c-shared build and Android device TUN/FFI smoke test
  (no local NDK), privileged TUN acceptance, macOS/Linux runtime IPC tests, and
  full performance acceptance.
- Passed: three fresh Windows child-core loopback baseline repetitions for
  idle/TCP/churn/UDP/uncached UDP and TCP DNS. Pacing bounds short-connection
  load; TCP DNS rotates connections below the dependency's 128-query limit.
  Source tests and complete raw report pass. System proxy and Clash Verge
  process fingerprints are unchanged before/after; test children are gone.
- This is an exploratory reference: TCP rate dispersion exceeds 2x and
  long-run retention/concurrency/TUN/IPv6/process lookup/sniffing/mux/remote
  protocols still need measurement. See `.agents/performance-baseline.md` for
  reproducible methodology, binary identity, ranges and limitations.

### Delivery Checkpoint - 2026-10-29

- Toolchains: Go 1.27.0 windows/amd64; Flutter 3.44.4; Dart 3.12.2.
- The wrapper passes `go test ./...` and `go test -tags=with_gvisor ./...`.
  The latter also compiles the opt-in Windows smoke test.
- Flutter: 512 full-suite tests pass, including the effective DNS/YAML cases,
  setup-acknowledgment/startup regressions, invalid-config regressions, and the
  read-only DNS diagnostic tests. Provider and model generation was rerun
  instead of editing generated files manually.
- `flutter analyze --no-fatal-infos` passes with 13 pre-existing info-level
  diagnostics. `yaml: ^3.1.3` is declared under `dev_dependencies` and resolves
  as a direct dev dependency in `pubspec.lock`.
- Windows release artifacts were rebuilt after the Go changes and the helper
  contains the current core token. `core_sha256.json` was refreshed. A running
  app or packaged Flutter binary is not automatically upgraded by rebuilding
  these artifacts.
- None of these tests modify the user's active app profile, system proxy,
  system DNS, or TUN routes. Privileged TUN and real upstream-proxy behavior
  require separate acceptance tests.

## Phase 1 - DNS Leak Hardening

DNS leakage is a configuration and path problem, not a property that can be
declared from the proxy protocol alone. The current implementation has a real
risk in compatible configurations:

- `Dns.respectRules` defaults to `false`, so nameservers without an explicit
  proxy name are dialed directly by the core.
- The default nameservers are mainland DoH endpoints. Queries are encrypted in
  transit, but the selected resolver still sees the queried domain.
- Previously, `task.dart` automatically appended `system://` when subscription
  DNS was disabled. This implicit path is removed. `appendSystemDns` can still
  append it explicitly, and custom subscriptions can contain it. `system://`
  uses host resolver addresses rather than the selected proxy path.
- TUN DNS hijacking defaults to `any:53` on desktop and intercepts supported
  port-53 traffic while TUN and the matching routes are active. It does not
  cover application-owned DoH/DoT, traffic outside the TUN route, or guarantee
  that the core's upstream DNS is proxied.

### Work items

- Define explicit DNS modes: compatible, proxy-routed, and custom.
- Distinguish rules-routed DNS from proxy-only DNS: `respect-rules` can match
  `DIRECT` and is not by itself a no-leak guarantee. Proxy-only mode must pin
  ordinary resolvers to an explicit proxy/group, disallow system/direct
  fallbacks and fail visibly if that route is unavailable.
- Keep a non-empty `proxy-server-nameserver` for bootstrap in proxy-routed
  configurations; test policies and fallback resolvers as well as nameservers.
- Keep a separate bootstrap resolver for proxy server hostnames.
- Make `appendSystemDns` visibly opt-in and warn when it is used.
- Add effective-config tests for profile DNS enabled/disabled, override DNS,
  nameserver policy, and TUN hijack combinations.
- Add a DNS path diagnostic that reports whether each nameserver is direct,
  proxied, system, or rules-routed. Do not claim that a reachability trace is a
  DNS-leak test.

### Acceptance criteria

- Proxy-only mode cannot emit a system/direct fallback for ordinary queries;
  incompatible settings block generation with a visible error. Never silently
  downgrade to custom mode; the user must explicitly choose it.
- A strict mode always has a bootstrap resolver for proxy server addresses.
- Changing DNS settings cannot silently turn a proxied path into a direct one.
- The DNS page explains the difference between DNS privacy and IP reputation.

### Current Status

- Implemented: a detached effective-DNS builder, preservation of advanced
  subscription DNS fields, explicit-only system DNS injection, alias
  de-duplication, patch policy conversion, and DNS/TUN YAML regression tests.
- Implemented: invalid/missing config and invalid setup JSON no longer install
  default policy. The previous in-memory configuration and test URL remain
  active on parse rejection.
- Implemented: the app commits `lastConfigMd5` only after setup success;
  empty-file errors are no longer ignored, and a null core response is no
  longer represented as an empty success string. Initial startup callbacks
  wait for acknowledgment and propagate asynchronous failures.
- Upstream parser regression coverage proves that `respect-rules` tags main,
  fallback and policy resolvers as `RULES`, keeps bootstrap separate, and
  requires a proxy-server resolver. Tests disable GeoIP fallback filtering so
  they do not download data from the internet.
- Implemented: read-only `getDnsDiagnostic` core action and stricter Dart
  decoding. Schema v1 reports resolver roles, configured paths
  (direct/rules/proxy/interface/system/dhcp/overlay/synthetic/blocked/unknown),
  bootstrap inheritance, and warning codes. It never performs a query and
  explicitly declares that it is not a leak test.
- Implemented: `compatible`, `proxyOnly` and `custom` DNS safety modes.
  `proxyOnly` pins main, fallback, policy and direct-traffic resolvers to one
  validated target. It rejects system/dhcp, reserved or mismatched selectors,
  multiple bare fragment selectors (Mihomo uses the last), unknown transports,
  invalid field shapes and `respect-rules`.
- Implemented: target graph validation against the config about to be applied,
  after script/custom group overrides, not the previous live proxy list. It
  rejects missing/duplicate names, DIRECT descendants, cycles, excessive depth,
  unverified outbound types, empty/filtered groups and dynamic provider groups.
  Provider refresh and auto-inclusion require a future core-owned runtime gate;
  they are conservatively refused in strict mode for now.
- Implemented: explicit, non-empty IP-address bootstrap resolvers are required
  for both default and proxy-server DNS. System/dhcp, hostname-only bootstrap
  and proxy-selector bootstrap loops are blocking errors, not just warnings.
  Bootstrap remains directly dialed and is disclosed separately from ordinary
  queries; this is not an assertion of zero direct DNS packets.
- Implemented: invalid strict profiles yield no usable YAML/hash, cannot be
  exported or applied, and never run the startup callback. Normal startup now
  waits for config acknowledgment like initial startup. IPv6 and escaped target
  names are covered in Dart and the real Mihomo parser.
- Implemented: a DNS diagnostic panel within the existing settings UI. It
  groups ordinary, bootstrap and direct-traffic resolvers; explains inherited,
  direct and unverified paths; and explicitly distinguishes configuration
  privacy from IP reputation and packet-capture leak testing.
- Pending: on-device IPv4/IPv6/TUN/mobile packet-capture acceptance tests and a
  core-owned runtime enforcement gate for dynamic providers. Generation checks do not constrain a
  separately edited YAML or external controller configuration.
- Boundary: parse rejection preserves the policy in memory, not the old file
  on disk. Persistence rollback and timeout/late-ack reconciliation are separate
  follow-ups; a missing acknowledgment is an error, not proof that the child
  core did not apply the request.

### Strict DNS Checkpoint - 2026-10-29

- Added 20 Flutter regressions for pending-config target validation, bootstrap,
  IPv6, decoded fragment selection, repeat generation with encoded group names,
  custom group overrides, startup and export refusal. Full suite: 512 passed;
  official `flutter analyze --no-fatal-infos`: 13 existing info diagnostics and
  no new issues. Detailed test output: `build/dns-safety-full-tests.log`.
- The wrapper passes `go test -tags=with_gvisor ./...`, including real parser
  coverage for IPv6, escaped group names, transport parameters and explicit
  direct-traffic resolver pinning despite `MATCH,DIRECT` routing rules.
- This increment changes app-side generation and tests, not the Mihomo
  submodule or core runtime. Previously built core/helper hashes remain valid;
  restarting an old packaged app does not load these Dart changes.
- All validation runs during configuration generation, not packet forwarding.
  No performance improvement is claimed until workload baselines are captured.

### Next Delivery Order

1. Capture isolated idle/TCP/UDP/DNS baseline measurements; keep TUN, process
   lookup, sniffing, mux and real upstream acceptance explicitly pending.
   Initial three-run loopback reference is recorded; next reduce dispersion
   and add inspection-on/off plus long-duration retention workloads.
2. Design a core-owned runtime enforcement gate before allowing dynamic
   provider groups in strict mode. Static generation checks cannot guarantee
   that refreshed provider members remain proxy-only.
3. Capture idle/connection churn/TCP/UDP/DNS benchmarks before changing tracker
   allocation or scheduling. Establish measurements before claiming lower RSS.
4. Proceed to lightweight statistics; then TrafficClass/QoS. Keep the Cloudflare
   and IP-quality pipeline independent of forwarding and default health checks.
5. Run privileged TUN and Android device acceptance tests where an approved
   environment and NDK are available.

### DNS Diagnostic Presentation Checkpoint - 2026-10-29

- Added 18 widget tests: lazy entry, resolver grouping, manual refresh,
  timeout/late responses, disconnected or uninitialized core, refresh races,
  disposal, error redaction, unknown paths/warnings and narrow-width scrolling
  in English, Simplified Chinese, Japanese and Russian.
- Localized the panel in all four ARBs and regenerated localization output.
  No visual-system redesign or core forwarding hooks are added.
- Full Flutter suite: 530 passed. `flutter analyze --no-fatal-infos`: the same
  13 existing infos, no new diagnostics. Log:
  `build/dns-diagnostic-full-tests.log`.
- A configuration snapshot and an empty warning list are not proof of no DNS
  leaks. Bootstrap remains directly dialed; device packet capture is pending.

## Phase 2 - Lightweight Connection and Statistics

### API Checkpoint - 2026-10-29

- Implemented: schema-1 `getConnectionUpdates` Go action, full/opaque-cursor
  query chain, full-record upserts, counter-only updates and removals. One
  cache is capped at 4096 records/8 MiB charged budget; invalid/missing/expired
  cursor and lifecycle changes resynchronize, and overflow requires fallback.
- Removed counts are last observed (`finalCountersVerified:false`), not exact
  final byte totals. Between-poll short-lived connections are not journaled.
  Precise close accounting remains a separate lifecycle task, not a quota API.
- Passed: unit coverage, three low-volume Windows IPC tests and Linux/macOS
  amd64/arm64 plus Windows arm64 cross-builds. No Mihomo patch, forwarding queue
  or new background timer is added; full legacy action stays unchanged.
- Gate: 128-record delta wire size is about 88% smaller, but service duration
  and allocation count are higher in the initial comparison. Keep the current
  Flutter full-snapshot consumer until comparison/encoding is optimized and a
  strict Dart merger plus compatibility/restart tests are implemented.
- Contract, benchmark ranges, profiling evidence and next step:
  `.agents/connection-updates.md`. Do not claim throughput/CPU/RSS gains yet.

### Cached Comparison Checkpoint - 2026-10-29

- Stable metadata is compared against detached typed data on every query;
  unchanged records no longer pay repeated metadata serialization. Every
  JSON-visible metadata/tracker field and nil/empty/in-place slice change has
  regression coverage. Raw address objects are not retained; cloned strings
  and comparison data are included in the bounded cache accounting budget.
- Three same-build 128-record synthetic count-only runs take 102.9-113.2
  microseconds/op versus legacy 368.7-463.2; allocations fall from 1560 to 149
  per operation, and wire bytes remain about 88% lower. Warm full resync and
  unchanged delta also improve. These are inspection microbenchmark results,
  not forwarding, UI responsiveness or RSS acceptance.
- Cold initial snapshots and high metadata/membership churn still regress.
  Profile evidence points to raw-object JSON reformatting and full-record
  copies. The Flutter consumer therefore remains on `getConnections`.
  Compatibility fallback is a full-snapshot action, not a core-version rollback.
- Passed: default/tagged full Go tests, vet, three focused regressions, three
  isolated rebuilt Windows IPC runs, and Linux/macOS amd64/arm64 plus Windows
  arm64 cross-builds. Published binaries and the clean Mihomo commit are not
  changed. System proxy/Clash Verge fingerprints match, and no child remains.
- Next: address cold/churn response costs or test an explicit adaptive full
  strategy; measure record counts/churn ratios and real IPC/retained-cache A/B;
  then add strict Dart merge, old-core compatibility and lifecycle recovery.
  Android NDK/device and race acceptance remain pending. Details and raw-log
  references: `.agents/connection-updates.md`.

### Measurement Checkpoint - 2026-10-29

- Inspection A/B passes three alternating-order pairs with 128 live TCP
  records and completion-relative one-second polling. Each full snapshot is
  about 89 KB inner JSON; eight successful polls per on-stage. Rate changes
  are inconsistent (-24.03%, -4.22%, +3.88%); do not call them causal overhead.
- Three ten-second mixed loads plus 70-second quiet periods pass in one child.
  TCP records return to zero; 16 UDP records per cycle expire by the 60-second
  observation without forced GC, cache flush or closing core connections.
- Quiet-end RSS is 32.51, 33.49 and 34.37 MiB across cycles. That working-set
  growth is not identified or proven bounded by this four-minute run. No
  memory/CPU improvement is claimed, and no production forwarding change is made.
- Methodology, binary identity, raw report hashes, safety checks and the next
  versioned inspection-API boundary: `.agents/performance-experiments.md`.

### Work items

- Split connection state into a fast tracker and an inspection record.
- Keep full Metadata, process path, rule payload, and provider chains on demand.
- Replace repeated full connection snapshots with initial snapshot plus
  add/update/remove events.
- Cache process and package lookup for a short bounded period.
- Bound UDP flow state, idle timers, and connection inspection memory.
- Keep dashboard traffic aggregation independent from the connection-detail page.

### Acceptance criteria

- Forwarding remains fast when the connection page is closed.
- Connection refresh frequency does not create a measurable throughput regression.
- UDP and high-churn connection tests show bounded memory growth.
- Connection details remain correct when the inspection page is opened.

## Phase 3 - TrafficClass

### Work items

Add a core-owned classification model with these possible match dimensions:

- process name and path;
- UID and Android package;
- rule and rule-set result;
- TCP/UDP network;
- inbound and proxy/policy;
- optional domain, destination IP, and port.

Each class should carry a stable identifier and optional:

- priority;
- maximum connection count;
- upload limit;
- download limit;
- quota;
- overflow policy.

Start with process/path on desktop and UID/package on Android. Add other
dimensions only after the first classification path is stable.

## Phase 4 - QoS

### Work items

- Add global, policy, process/UID, and connection-level token buckets.
- Support separate upload and download limits.
- Enforce connection-count limits before allocating expensive connection state.
- Use shared scheduling and bounded queues instead of one timer/goroutine per
  connection.
- Add UDP drop/queue behavior explicitly.
- Treat mux logical streams separately only after the underlying stream
  identity is available.

### Acceptance criteria

- A single high-volume process cannot starve interactive traffic.
- Limits are enforced in both Read/Write and buffer fast paths.
- UDP queues cannot grow without a configured bound.
- Removing a policy releases all associated buckets and waiters.

## Phase 5 - Protocol Compatibility Matrix

For each supported protocol, test:

```text
TCP, UDP, IPv4, IPv6, mux, chain, TUN, DNS resolve,
Windows, Android, macOS/Linux, health check
```

Prioritize compatibility and parameter coverage for TUIC, Hysteria2, AnyTLS,
MASQUE, WireGuard, Trust Tunnel, VLESS Reality/xhttp, ShadowTLS, SOCKS5-TLS,
HTTP/2 CONNECT, and UDP relay behavior.

Do not add a protocol only because it has a new enum. It must have configuration,
import, validation, health-check, and platform behavior.

## Phase 6 - Node Quality and IP Purity

The node test pipeline should remain non-blocking:

```text
basic latency -> proxy handshake -> Cloudflare probe -> IP quality provider
```

Cloudflare is used for egress IP, edge/colo, HTTP reachability, and TTFB.
IPPure or a future IPure adapter is used for risk and IP-type information.
These results must remain separate; Cloudflare reachability is not an IP
cleanliness score.

### Provider design

Use a provider interface rather than hardcoding one service:

```text
IpQualityProvider
  checkThroughProxy(context) -> IpQualityResult
```

The result should preserve:

- provider name;
- egress IP;
- checked time;
- risk fields as optional values;
- confidence/status;
- raw error category, not sensitive response bodies.

### Runtime rules

- For an automatic pipeline, run quality checks after a successful latency/
  handshake test. The first manual entry performs its own HTTPS handshake,
  avoids mutating URLTest history, and keeps provider failures independent.
- Future caches must key by provider, observed egress IP and protocol. The first
  manual implementation retains only the current dialog report, with no
  cross-dialog cache, persistent risk data or background refresh.
- Do not run IP-quality checks in the default high-frequency health check.
- Use short timeouts and independent failure handling.
- Display `unknown` when a provider fails; never turn failure into score zero.
- Make third-party checks opt-in and explain that the egress IP/ASN is sent to
  the selected provider.
- Do not include purity in default latency ranking. Add a separate quality
  ranking mode later.

### Current status - 2026-10-30

- First manual delivery is implemented: bounded selected-adapter Go action,
  fixed HTTPS provider parsers, strict Dart facade, separate latency-area icon,
  dialog-local IPPure consent and four-locale stateful UI.
- Cloudflare is not a risk score. IPPure Beta documented fields are mapped
  without guessed credentials/types. Missing/unverified IPv6 scores are unknown;
  different provider egress IPs are not merged.
- Passed: 556 full Flutter tests, analysis with 13 existing infos, generation,
  Go default/gVisor tests/vet, five desktop cross-builds and three private
  refused-SOCKS Windows IPC runs.
  Verge/WinInet proxy fingerprints remain unchanged.
- Release core/helper stay unchanged. Real remote checks, coordinated app/core
  runtime, rate limits and Android/native runtime remain pending. Fixture success
  is not remote-node/score/performance acceptance. Details: `.agents/node-quality.md`.
- Next: node-quality acceptance, connection-inspection Dart merge/performance
  gates, TrafficClass/QoS, protocol matrix, then UI redesign.

- 2026-11-02: Cloudflare score is shown as unavailable because
  `/cdn-cgi/trace` has no Bot Score; the dialog now discloses the probe
  footprint and applies a bounded 30 s per-node/provider courtesy cooldown.
  30 focused node-quality tests and 724 full-suite passes / 5 skips.

## Verification

For core changes:

```bash
go test ./...
```

For the repository integration:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test --reporter expanded
```

Generated Dart files must not be edited manually. If the core API changes a
model/provider contract, update the source model and regenerate it.

The opt-in Windows smoke test runs from `core/` against the release artifact:

```powershell
$env:QUANCLASH_CORE_SMOKE = (Resolve-Path ../libclash/windows/QuanClashCore.exe).Path
$env:CGO_ENABLED = '0'
go test -tags=with_gvisor -run TestDesktopCoreSmoke -count=1 -v -timeout 90s .
```

This is a loopback integration test, not a public DNS-leak test or a throughput
benchmark. Do not interpret its result as proof about application-owned DoH,
system-proxy-only applications, privileged TUN or remote node protocols.

### Coordinated Node-Quality Delivery And Next Gate - 2026-10-30

- Coordinated staged Release core/helper/app build passes static core-token and
  artifact checks without replacing published binaries or launching services.
  CMake no longer packages stale outputs based only on file existence.
- Actual bundle Rust DLL/core with production Dart transport/facade passes three
  refused-loopback runs, including shutdown cleanup and repeated listener start/
  stop. This exposed and fixed a Dart FRB cancellation-order deadlock and a Rust
  join-under-lock deadlock. Final code adds no reader polling or detached reaper.
- Verification: 561 full Flutter passes (two opt-in tests skipped by default and
  exercised separately), 13 original analysis infos, two Rust tests/clippy, Go
  default/gVisor tests/tagged vet and three Go IPC smoke passes. Pre/post proxy,
  DNS, routes, Verge/helper identity and published hashes are unchanged.
- The IP-quality feature is implemented and locally integrated, not certified
  against real providers. GUI/helper auth runtime, remote CF/IPPure, device/TUN/
  Android and sustained performance remain separate acceptance work.
- Next code increment: strict Dart connection-update decoding and atomic merge,
  stale-cursor/restart recovery and old-action fallback, followed by cold/churn
  and real IPC/cache performance gates. Only transport entry/encoding is ready;
  existing connection UI still uses full snapshots. Then TrafficClass/QoS and
  protocol matrix; visual redesign remains last.
- Never start an app with system integration or make real provider probes merely
  to mark this checkpoint complete. Obtain explicit scope for remote acceptance.
  Bundle identity and limitations: `.agents/node-quality.md`.
### Typed Connection Merge Checkpoint - 2026-10-30

- Delivered a strict Dart packet decoder and immutable atomic snapshot merger,
  preserving current metadata/provider fields and nil/empty distinctions while
  refusing malformed cursors, fractional counters and overlapping operations.
  Existing connection UI remains unchanged; nothing polls the new API by default.
- Verified: 34 focused regressions x3 and real production Rust IPC/local TCP
  echo x3 with legacy snapshot equality, removals and full resynchronization;
  595 full Flutter passes, three default-skipped opt-ins, 13 original analysis
  infos. Node-quality native regression passes; pre/post network/published-file
  fingerprints match. Core/Mihomo/GUI packaging are not changed this increment.
- Next critical task: serialize refreshes, lifecycle-epoch stale-reply rejection
  (especially full replies), bounded timeout and old-core/full-action fallback.
  Then validate cold/churn, IPC and retained-memory costs before UI activation.
  Immutable merge correctness alone is not forwarding/RSS improvement or final
  recovery acceptance. Details: `.agents/connection-updates.md`.

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

- Production Rust/Dart A/B covers stable and high-churn inspection through actual
  IPC. Stable 128-record counter updates are substantially smaller/faster, but
  all-identity replacement is near full-snapshot size and has no reliable latency
  benefit. Quiet child RSS is exploratory and sometimes higher for incremental.
- Decision: do not activate the consumer yet. Add churn/full-resync policy, profile
  allocations/service time, repeat Release/AOT or production-like client measures,
  and measure retained Dart objects before lifecycle integration. TrafficClass/QoS
  and visual redesign remain later; no performance/RSS improvement claim is made.

### Adaptive Churn Resync Checkpoint - 2026-11-02

- The inspection server returns full resync at >=75% record upsert churn for
  snapshots with at least 16 records; removals do not trigger it alone and full
  packets clear the base cursor. The half-replacement delta path is preserved.
- Private-core/Rust A/B: stable 1.364-1.744 ms / 10.852 KB and half replacement
  3.628-4.150 ms / about 55.1 KB versus legacy 4.364-6.527 ms / about 103-104 KB.
  All replacement is about 87.6 KB and 4.983-5.353 ms, versus prior delta about
  100.4 KB and 5.44-6.08 ms. Cold path and forwarding rate are inconclusive, and
  quiet child RSS remains 0.332-2.043 MiB higher for incremental.
- Go focused/full tagged tests, vet/gofmt, real IPC x3 and the 642-test Flutter
  suite pass; four opt-in tests skipped by default and analysis keeps 13 infos.
  Host proxy/DNS/routes, Verge/helper identity and published hashes are unchanged.
- UI activation remains gated. Next: Release/AOT or production-like inspection
  measurement, cold/open and retained-Dart accounting, then owner lifecycle,
  hidden-page and reconnect integration. TrafficClass/QoS follows; visual redesign
  remains last. No packaged runtime, RSS or forwarding claim is made.

### TrafficClass Classification Foundation - 2026-11-02

- Added the pure `core/traffic_class.go` schema-1 parser/matcher for process name,
  process path, UID, package name and TCP/UDP network. Every configured dimension
  must match; values within one dimension use OR; configuration order selects the
  first match. Priority is retained for future scheduling and does not alter match
  precedence.
- Parsing is immutable and bounded: 1 MiB JSON, 256 classes, 128 values per
  dimension, 64-byte IDs, 1024-byte text and duplicate/unknown/empty configuration
  rejection. Process names and paths are case-insensitive only on Windows; path
  separators are normalized on every platform. Package matching uses the Android
  package carried in `Metadata.Process` and is case-sensitive.
- This is internal groundwork only. No action, config persistence, connection
  counter, forwarding hook, queue, token bucket, UI or QoS enforcement consumes it
  yet. No overhead or throughput claim is made.
- Seven focused tests pass three runs, including first-match order, all-dimension
  AND semantics, platform case behavior, nil/empty inputs, input detachment and
  resource bounds. Full tagged Go tests, vet and five desktop cross-builds pass.
- Next: add an explicit detached configuration/action lifecycle, classify after
  process/package resolution but before expensive connection state or queues, then
  add bounded per-class accounting. Connection-count/rate/quota enforcement belongs
  to the following QoS increment and requires separate failure/queue tests.

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
