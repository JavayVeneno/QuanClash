# Architecture

## Core Integration

The Go proxy core in `core/` operates in two modes.

Android lib mode:

- Go core is compiled as a C shared library, `libclash.so`, through `go build -buildmode=c-shared` with CGO.
- Flutter calls it via FFI through the `service` plugin.
- Dart-side implementation: `lib/core/lib.dart` (`CoreLib`).

Desktop core mode:

- Go core runs as a separate process with `CGO_ENABLED=0`.
- Flutter communicates via framed JSON through the Rust IPC transport, using a Unix socket on macOS/Linux and a named pipe on Windows.
- Dart-side implementation: `lib/core/service.dart` (`CoreService`).

`lib/core/controller.dart` (`CoreController`) selects the implementation based on platform. `lib/core/interface.dart` defines the shared `CoreHandlerInterface`.

Key Go core files:

- `core/hub.go`: handler functions.
- `core/action.go`: dispatch.
- `core/lib.go`: CGO exports.
- `core/server.go`: socket server.

DNS diagnostics:

- `getDnsDiagnostic` is available via desktop IPC and Android FFI action
  dispatch. `CoreHandlerInterface` retrieves its structured map and
  `CoreController` validates the typed `DnsDiagnostic` model.
- The Go handler inspects only the active parsed config under `runLock`; it adds
  no DNS probes or forwarding hooks. Schema v1 separates main, fallback,
  policy, bootstrap, and direct resolver roles.
- Routes and warnings describe configured paths, not observed network traffic.
  They do not treat RULES or a selectable proxy group as a verified proxy-only
  path. DNS URL credentials/path/query/fragment and policy domains are omitted.
- `lib/views/config/dns_diagnostic.dart` presents this snapshot within the
  existing DNS settings design, only while the core is connected and
  initialized. Entry, manual refresh and config events trigger reads, not
  periodic polling. A five-second timeout, request revision and lifecycle
  checks discard stale/late results; raw IPC exceptions are never rendered.
- Effective DNS generation (`lib/common/dns_config.dart`) returns the config,
  warnings, and blocking errors. `DnsSafetyMode.proxyOnly` pins ordinary
  and direct-traffic resolvers to one verified static proxy graph
  (`lib/common/dns_proxy_target.dart`). Validation runs after profile/custom
  overrides and rejects unknown targets instead of treating them as interfaces.
  Dynamic providers/filtered groups are refused until a core-owned runtime
  gate exists. Explicit IP bootstrap resolvers are required; their disclosed
  direct path remains separate from ordinary queries.
- Generation failure produces no usable YAML/hash and blocks export/apply;
  both normal and initial startup wait for config acknowledgment. This app-side
  gate does not constrain independently edited core YAML or controller reloads.
- Android shares the action path, but its NDK build and device test remain
  pending.

Performance measurement:

- `core/performance_windows_test.go` is an opt-in test-only harness over the
  existing named-pipe action boundary. Fresh children have isolated config,
  loopback endpoints and no TUN/controller/helper or system-network changes.
- `core/performance_test.go` accounts for CPU/RSS/rate/RTT with bounded latency
  sampling and validated pacing. OS sampling does not call core heap APIs or
  force GC. Connection snapshots are taken only after timed stages.
- These tests do not add production forwarding hooks. Methods, artifact
  provenance, recorded ranges and remaining acceptance gaps are documented in
  `.agents/performance-baseline.md`.
- `core/performance_experiments_windows_test.go` adds opt-in inspection A/B
  and three load/quiet retention cycles. The test-only IPC client serializes
  requests and propagates background errors; completion-relative poller stop
  joins in-flight reads. TCP/UDP snapshot identity/network fields are checked.
  No core GC/flush/forced-connection-close is used for retention. Workload
  boundaries and results live in `.agents/performance-experiments.md`.

Connection inspection:

- `getConnectionUpdates` is a schema-1 Go action returning a full reset or
  cursor-based upserts, absolute counter changes and last-observed removals.
  `core/connection_updates.go` owns one bounded latest-snapshot cache; there is
  no forwarding event queue, tracker retention or extra idle timer.
- Detached typed comparison data covers every JSON-visible metadata field and
  tracker inspection field, including nil/empty and in-place slice changes.
  Unchanged records reuse their JSON; new/changed records are serialized. Raw
  address objects are excluded and strings/slices are cloned on changes. The
  8 MiB accounting budget charges typed data as well as JSON.
- Missing/stale/expired cursor and lifecycle changes force resynchronization.
  Caps trigger `fallback-required`, never truncation. Removed counters are
  explicitly not verified final counters. Range is weakly consistent, not an
  event/audit/quota stream. Contract: `.agents/connection-updates.md`.
- The legacy action remains active in Flutter. Stable-record count-only
  encoding has lower measured time/allocations. Cold initial snapshots remain
  costly; replacement-heavy rounds now switch to a full policy response (details
  below). Dart serialization/merge and UI adoption stay gated on production-like
  and retained-memory acceptance. Do not infer forwarding CPU/RSS improvement or
  enable it by default. Legacy-action/old-binary fallback is not a Mihomo
  version downgrade.

Node quality inspection:

- `core/node_quality.go` implements the independent schema-1 `testNodeQuality`
  action. Fixed Cloudflare/IPPure HTTPS uses a concrete adapter, bounded admission,
  time/body/header limits and certificate validation, with no forwarding hooks
  or arbitrary URLs. Failures contain no success data.
- `CoreHandlerInterface`/`CoreController` share desktop IPC and Android FFI;
  `lib/core/node_quality.dart` strictly decodes identity and metrics. Android's
  `CoreLib` now forwards the existing optional per-action timeout.
- `lib/views/proxies/node_quality.dart` opens from latency without sending probes.
  Manual start defaults to Cloudflare only; IPPure opt-in is dialog-local.
  Config/selection/profile/lifecycle changes clear stale reports/reset consent;
  late results are ignored. No timer/persistent cache is added.
- Network measurements and each IPPure egress/risk result remain separate.
  Missing/unverified IPv6 scores are unknown; non-residential is not data-center.
  Adapter bootstrap/dialer-proxy paths are not a no-leak guarantee.
- Local HTTPS, Dart/widget and refused-loopback-SOCKS Windows IPC tests pass;
  remote-provider/device/runtime acceptance remains pending. Contract, limits,
  provenance and gates: `.agents/node-quality.md`.

## State Management

Provider files in `lib/providers/`:

- `app.dart`: runtime/UI state, logs, traffic, delays, loading, navigation.
- `config.dart`: persistent config providers, app settings, theme, VPN, proxy style.
- `state.dart`: derived/computed providers, navigation, proxy, tray, color scheme.
- `action.dart`: business logic notifiers, setup, backup, core lifecycle, proxy selection.
- `database.dart`: Drift database provider wrappers.

`globalState` in `lib/state.dart` is a singleton holding app lifecycle, timers, theme, and start/stop state. Providers are generated into `lib/providers/generated/`.

## Database

The app uses Drift/SQLite in `lib/database/`. Current schema version is 2.

Tables:

- `Profiles`
- `Scripts`
- `Rules`
- `ProfileRuleLinks` (`profile_rule_mapping`)
- `ProxyGroups`
- `IconRecords` (`icon_records`)

Rule scenes distinguish global added rules, profile added rules, profile custom rules, and disabled links. Rule and proxy-group ordering use fractional indexing.

Generated Drift output lives in `lib/database/generated/database.g.dart`. After schema changes, run code generation and add or update focused database tests under `test/database/` when converter or migration behavior changes.

## Manager Stack

Managers are nested `InheritedWidget`/`StatefulWidget` components in `lib/application.dart`:

```text
AppEnvManager > StatusManager > ThemeManager
  > [Desktop: WindowManager > TrayManager > HotKeyManager > ProxyManager]
  > ConnectivityManager > CoreManager > AppStateManager
  > [Mobile: AndroidManager > VpnManager | Desktop: WindowHeaderContainer]
```

Each manager in `lib/manager/` handles a specific platform concern. Desktop-only managers are conditionally inserted.

## Core Controller and Actions

`lib/core/controller.dart` (`CoreController`) is a singleton facade over `CoreHandlerInterface`. Public methods delegate to the platform-specific interface, either Android FFI or desktop socket. It has an `@visibleForTesting` constructor and `resetInstance()` for test injection.

Business logic lives in Riverpod notifier classes in `lib/providers/action.dart`:

- `CommonAction`: update check and common UI operations.
- `SetupAction`: config setup and TUN management.
- `BackupAction`: backup/restore with WebDAV sync.
- `CoreAction`: core lifecycle, init, connect, restart, shutdown.
- `SystemAction`: system integration, tray, exit, brightness.
- `StoreAction`: profile storage operations.
- `ThemeAction`: theme state updates.
- `ProxiesAction`: group management and proxy selection.
- `ProfilesAction`: profile CRUD, auto-update, import.

## Platform Managers

Desktop:

- `WindowManager`
- `TrayManager`
- `HotKeyManager`
- `ProxyManager`

Mobile:

- `AndroidManager`
- `TileManager`
- `VpnManager`

Shared:

- `ConnectivityManager`
- `CoreManager`
- `AppStateManager`
- `StatusManager`
- `ThemeManager`

## Build System

`setup.dart` is the release build orchestrator:

1. On Windows, pre-builds Go core via `dart run build_tool windows` and reads `core_sha256.json`.
2. Writes `env.json` (`APP_ENV`).
3. Passes SHA256 as `--dart-define=CORE_SHA256=$val`, embedded at compile time for Windows.
4. Activates `flutter_distributor` for packaging.

Go core building is handled by `build_tool`, a standalone Dart CLI in `plugins/setup/buildkit/build_tool/`.

Platform build hooks inside `flutter build` trigger `build_tool` automatically:

- macOS: podspec script phase, `build_pod.sh`, `build_tool macos`.
- Linux: CMake include, `buildkit/cmake/buildkit.cmake`, `build_tool linux`.
- Windows: CMake include, `buildkit/cmake/buildkit.cmake`, `build_tool windows`. The active `$<CONFIG>` sets `BUILDKIT_CONFIGURATION` for Debug/Release.
- Android: Gradle include, `buildkit/gradle/plugin.gradle`, `build_tool android`.

Windows helper auth:

- Release: Core SHA256 is embedded in both the Flutter app and the Rust helper. The app pings the helper and verifies the token matches.
- Debug: The Rust helper skips token verification when built in debug mode, so `flutter run` works without the SHA256 flow.

`plugins/setup/` is an FFI plugin that exists only as a build harness. It carries no Dart API, only platform build hooks that trigger Go compilation. Windows builds also compile a Rust helper in `services/helper/` through `RustBuilder`.

Build configuration defaults live in `build_tool/lib/src/options.dart` and can be overridden via `build_config.yaml`.

Architecture detection is automatic. The `--description` flag passed to `flutter_distributor` adds arch suffixes to artifact names, such as `FlClash-0.8.93-macos-arm64.dmg`.

## Local Plugins

- `setup`: build harness FFI plugin.
- `proxy`: system proxy configuration.
- `rust_api`: Flutter Rust Bridge FFI plugin.
- `tray_manager`: system tray fork/customization.
- `wifi_ssid`: Wi-Fi SSID detection.
- `window_ext`: window extensions.
- `flutter_distributor`: app packaging/distribution.

## Rust Helper Service

`services/helper/` is a Windows-only privileged helper for starting the core as admin and managing TUN. It is built with:

```bash
cargo build --release --features windows-service
```

It uses token-based auth with the Flutter app.

## Desktop IPC Shutdown And Build Provenance - 2026-10-30

`IPCCoreTransport.close()` now stops the native producer before awaiting FRB
stream cancellation. FRB 2.12 uses an async receive stream whose cancellation can
wait for the producer to finish: cancelling first deadlocks before stop is called.
Close is shared/idempotent, suppresses late data/disconnect callbacks, and releases
Dart subscriptions in `finally`. The Rust stop function takes its join handle
under `STATE` and releases that lock before joining the worker, which also needs
`STATE` during exit. It synchronously joins; no detached reaper or polling loop
is added. Frame-size policy and framing behavior remain unchanged.

Windows owners must disconnect/terminate their own child before stopping this
blocking-reader transport (as CoreService.destroy does through shutdown). Joining
while a live client remains connected, overlapping native stop/restart calls and
Unix native runtime tests remain separate lifecycle acceptance gaps. The passing
fixture does not imply those cases are fixed.

CMake core/helper builds no longer depend only on output-file existence, and
Debug compilation never taskkills a service. `BUILDKIT_OUTPUT_DIR` and
`CARGO_TARGET_DIR` allow coordinated staging without changing published artifacts.
The script records AOT and Rust DLL hashes, not only the generic Flutter runner
hash, and statically checks app/helper core-token consistency. Native fixture
acceptance loads bundle DLL/core through production Dart transport, not the GUI
AOT or privileged helper. Their runtime and real providers remain unverified.

A preparatory `getConnectionUpdates` Dart action/interface now encodes schema 1,
validates cursor shape and bounds the invoke timeout at five seconds. Its nullable
structured response is not a decoded connection list. Strict merger, lifecycle
recovery, fallback and UI adoption are still pending; legacy snapshots remain
active. No incremental polling or claimed RSS improvement is enabled by this API.
## Connection-Update Typed Client Checkpoint - 2026-10-30

`lib/core/connection_updates.dart` now strictly decodes schema-1 packets and
retains immutable inspection records including provider chains and current full
metadata, plus the exact start timestamp. CoreController returns typed packets;
legacy getConnections stays active in the connection page. Additive unknown JSON
fields are ignored, not retained. Shared model/freezed/provider schema is not
changed, so no manual generated edits or code generation are needed here.

The pure snapshot merger applies full/reset or cursor-checked delta atomically,
refuses unknown updated/removed IDs, clears inactive/fallback states and exposes
needsFull/requiresLegacyFallback without issuing actions. It bounds membership
and conservative retained-data charge, not RSS or all transport allocation.
Future consumers must serialize requests and invalidate lifecycle epochs BEFORE
applying replies: full snapshots cannot prove freshness through a base cursor.
Old-core fallback/async recovery and activation remain gated on tests/performance.

Windows native acceptance now exercises real loopback TCP additions/counters/
removals through the production Dart transport with the prior matching core/DLL;
merged TrackerInfo equals the unchanged full action. No GUI/helper/TUN/public
provider or forwarding fast-path change occurs. Detailed bounds/evidence:
`.agents/connection-updates.md`.

## Inspection Session Ownership And Recovery - 2026-10-30

CoreController.createConnectionInspectionSession binds typed incremental and
strict legacy full reads. ConnectionInspectionSession owns immutable accepted
state, an owner-controlled epoch, coalesced refresh future, unresolved-callback
admission gate and epoch-pinned legacy mode. It has no global state, polling or
lifecycle subscriptions. Existing connection UI and getConnections are unchanged.

Owners must reset/disconnect/dispose BEFORE lifecycle/config/profile changes;
full response/cursor validity cannot establish freshness. Disposal is terminal;
controller/handler replacement requires a new session. Reset while work is active
shares obsolete work, never queues another refresh. Invalid merge gets one fresh
full resync; second failure defers legacy to next refresh, keeping <=2 reads.
Unsupported/missing/schema/capacity replies pin legacy until reset. No core binary
is downgraded. Legacy wire format has no inactive flag: owners must also gate on
actual initialized/connectivity state, never infer it from an empty full list.

Deadline expiry does not cancel native work: gate new reads until the injected
future settles and discard late state. A lower layer may itself time out before
native completion, so this is not a physical/global IPC backlog guarantee.
Failure state is explicit and redacted, not a successful stale/empty view.
Legacy decoding validates totals/records and bounds larger full lists (16384),
string arrays (8192) and conservative retained charge (16 MiB), without truncation.

76 focused tests x3, real loopback session/strict-full IPC x3, node-quality native
regression and 637 full Flutter tests pass; analysis retains 13 original infos.
The old matching core/DLL are reused only for tests; no packaged new GUI/runtime
or savings claim. Production owner wiring/disposal, cold/churn and real IPC/RSS
performance gates remain pending before activation. Evidence: .agents/connection-updates.md.

## Inspection Performance Boundary - 2026-10-30

The production IPC A/B reduces stable counter-only response traffic but is not a
universal optimization: high membership churn approaches full-snapshot size and
can be slightly slower, while short quiet RSS is not lower. Keep explicit full
fallback and lifecycle invalidation. Production UI activation waits for
allocation/service-time profiling, production-like client measurements, retained
Dart-object evidence and owner lifecycle tests.

## Adaptive Churn Resync Boundary - 2026-11-02

`connection_updates.go` now switches to a full policy response when a snapshot has
at least 16 records and at least three quarters of next records need upserts.
Removed IDs are not counted in that ratio, so half replacement remains delta and
removals alone remain delta. Full packets clear `baseCursor` and carry only
upserts. This is a response-shape heuristic with the ordinary full fallback, not
an exact cost model.

The private-core/Rust production-transport A/B reduces all-replacement packets
from about 100.4 KB to 87.6 KB and reads to 4.983-5.353 ms versus legacy
5.424-5.679 ms in the tested JIT harness. Stable and half-churn gains remain.
Cold reads/forwarding rates are inconclusive, and quiet child RSS is still higher
for incremental. No packaged runtime, GUI AOT, RSS or forwarding claim follows.
The connection UI remains on full snapshots until Release/AOT or production-like,
cold/open and retained-Dart gates pass, followed by owner lifecycle, hidden-page
and reconnect integration.

## Traffic Classification Foundation - 2026-11-02

`core/traffic_class.go` is an internal, pure classification layer. It strictly
parses a bounded schema-1 class set and compiles process-name, process-path, UID,
package and TCP/UDP maps. Every configured dimension must match, values within a
dimension are alternatives, and the first class in configuration order wins.
Priority is descriptive for later scheduling, not a precedence override.

Windows process names and normalized paths are case-insensitive; Unix matching
remains case-sensitive. Package matching uses the Android package value in
`Metadata.Process`. Parsing is bounded and immutable, with unknown fields,
duplicates, empty matches and oversized collections rejected. There is currently
no action/config lifecycle, metadata hook, per-class accounting, limiter, queue,
UI or forwarding enforcement using this object. Do not describe it as working QoS.

## TrafficClass Configuration Ownership - 2026-11-02

This supersedes the identity assumptions in the initial foundation checkpoint.
`trafficClassInput` uses explicit UIDKnown and separate resolved PackageName;
Metadata.Uid=0 and Metadata.Process alone cannot certify either identity. Paths
must be absolute under platform rules; Unix backslashes are not separators.
Strict config rejects duplicate/aliased keys, null values and empty dimensions.

`traffic_class_state.go` stores one volatile immutable snapshot behind an atomic
pointer, with serialized revision/CAS publication. The new Go shared actions expose
only IDs/priority, revision and prepared/inactive state with enforcing=false.
Action publication/read serializes on runLock with setup/update/listener/shutdown;
parsing is detached and CAS revalidates before publication. Initialization/shutdown
clear to inactive; only successful setup enables preparation. Listener/runtime
update invalidates without independently enabling an unprepared state. Rejected
setup preserves policy. Shutdown now takes the existing runLock as well.

No Dart action enum/facade, profile owner, persistence, data-plane hook, class
accounting or enforcement is installed. Future clients must not treat write
acknowledgment as QoS success; timeout is unknown completion, requiring explicit
revision/owner reconciliation. Contract, bounds, safety and verified artifact:
`.agents/traffic-class.md`.
