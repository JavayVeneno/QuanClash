# Commands

## Building

Update submodules first. The ClashMeta Go core lives in `core/Clash.Meta/`.

```bash
git submodule update --init --recursive
```

Full package build, including Go core, Flutter, and packaging, runs through `setup.dart`:

```bash
dart setup.dart macos
dart setup.dart linux
dart setup.dart windows
dart setup.dart android
```

Build only the Go core and skip Flutter packaging:

```bash
make core-macos
make core-linux
make core-windows
make core-android
```

Pass `ARCH` or `TARGET_PLATFORM` through `make` when needed, for example:

```bash
make core-macos ARCH=arm64
make core-android TARGET_PLATFORM=android-arm64
```

The Makefile wraps `plugins/setup/buildkit/run_build_tool.sh`; prefer the `make` entry points unless debugging the build tool itself.

## Flutter Development

The project is pinned with FVM.

```bash
fvm flutter pub get
fvm flutter run
fvm flutter test
```

Plain Flutter also works when the global SDK matches project constraints:

```bash
flutter pub get
flutter run
flutter test
```

Use `flutter test`, not `dart test`, because models pull in Flutter types.

## Code Generation

Run code generation after modifying models, providers, or database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch
```

Code generation covers:

- Riverpod providers through `riverpod_generator`.
- Models through `freezed` and `json_serializable`.
- Database tables through `drift_dev`.

Generated output paths, configured in `build.yaml`:

- `lib/models/generated/*.g.dart`, `*.freezed.dart`.
- `lib/providers/generated/*.g.dart`.
- `lib/database/generated/*.g.dart`.

## Testing

Tests use `package:test/test.dart` for pure Dart logic and `flutter_test` for provider and widget tests. `mocktail` is the mocking framework.

```bash
flutter test test/models/
flutter test test/core/
flutter test test/providers/
flutter test test/common/
flutter test test/database/
flutter test test/widgets/
flutter test test/setup_test.dart
flutter test plugins/proxy/test/proxy_test.dart
```

Root `flutter test` only discovers the root package's `test/` directory by default. Include bundled plugin Dart tests by passing paths explicitly, or run `flutter test` from that plugin package directory. Native plugin tests under platform folders are not run by `flutter test`.

## Verify

CI runs these in order:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test --reporter expanded
```

Run `flutter analyze` locally before committing when practical.

## Isolated Windows Performance Reference

Run from `core/`. Default Go tests skip the load test. The opt-in harness uses
only a private child core and loopback traffic; it does not manage the running
app, system proxy, DNS or TUN. Use a new output path for every capture.

```powershell
$env:CGO_ENABLED = '0'
go test -tags=with_gvisor ./...
go build -tags=with_gvisor -o ../build/QuanClashCore-perf.exe .
$env:QUANCLASH_CORE_PERF = (Resolve-Path ../build/QuanClashCore-perf.exe).Path
$env:QUANCLASH_PERF_OUTPUT = (Join-Path (Resolve-Path ../build).Path 'performance-baseline-new.json')
go test -tags=with_gvisor -run '^TestDesktopCorePerformanceBaseline$' -count=1 -v -timeout 180s .
Remove-Item Env:QUANCLASH_CORE_PERF, Env:QUANCLASH_PERF_OUTPUT
```

The three repetitions take about 70 seconds and occupy CPU/loopback resources.
Short connections are capped; failures stop the run. Methodology and result
limitations live in `.agents/performance-baseline.md`. Do not compare different
build flags, or treat this as remote-node/TUN throughput or a no-leak verdict.

For the separate inspection on/off and load/quiet retention experiments, use
the same artifact but explicitly enable experiments and supply a new prefix:

```powershell
$env:QUANCLASH_CORE_PERF = (Resolve-Path ../build/QuanClashCore-perf.exe).Path
$env:QUANCLASH_PERF_EXPERIMENTS = '1'
$env:QUANCLASH_PERF_REPORT_PREFIX = (Join-Path (Resolve-Path ../build).Path 'performance-experiments-new')
go test -tags=with_gvisor -run '^TestDesktopCore(Inspection|Retention)Experiment$' -count=1 -v -failfast -timeout 8m .
Remove-Item Env:QUANCLASH_CORE_PERF, Env:QUANCLASH_PERF_EXPERIMENTS, Env:QUANCLASH_PERF_REPORT_PREFIX
```

Run from `core/` with `CGO_ENABLED=0` as above. These run serially in about five
minutes. Methodology/limits and reviewed results: `.agents/performance-experiments.md`.

## Connection Update API Verification

From `core/`, with `CGO_ENABLED=0`. No Flutter consumer is enabled yet:

```powershell
go test -tags=with_gvisor -run '^TestConnectionUpdate|^TestConnectionObservation' -count=3 -v .
go test -tags=with_gvisor -run '^$' -bench '^BenchmarkConnectionInspection(Encoding|Workloads)$' -benchmem -benchtime=1s -count=3 .
go build -tags=with_gvisor -o ../build/QuanClashCore-updates-cached.exe .
$env:QUANCLASH_CONNECTION_UPDATES_SMOKE = (Resolve-Path ../build/QuanClashCore-updates-cached.exe).Path
go test -tags=with_gvisor -run '^TestDesktopConnectionUpdatesSmoke$' -count=3 -v -failfast -timeout 90s .
Remove-Item Env:QUANCLASH_CONNECTION_UPDATES_SMOKE
```

The smoke test uses only a private child and a few loopback requests, not TUN
or system proxy/DNS changes. The synthetic benchmark is not forwarding
performance. Contract, service-time gate and pending UI work:
`.agents/connection-updates.md`.

## Manual Node Quality Verification

From `core/`, with `CGO_ENABLED=0`. Default tests use local HTTPS fixtures; the
opt-in IPC smoke uses a private child and loopback SOCKS5 server that refuses
all destinations, never a public Cloudflare/IPPure request:

```powershell
go test -tags=with_gvisor -run '^TestNodeQuality' -count=3 .
go build -tags=with_gvisor -o ../build/QuanClashCore-node-quality.exe .
$env:QUANCLASH_NODE_QUALITY_SMOKE = (Resolve-Path ../build/QuanClashCore-node-quality.exe).Path
go test -tags=with_gvisor -run '^TestDesktopNodeQualitySmoke$' -count=3 -v -failfast -timeout 60s .
Remove-Item Env:QUANCLASH_NODE_QUALITY_SMOKE
```

From the repository root:

```bash
flutter test test/core/node_quality_test.dart test/widgets/node_quality_test.dart --reporter expanded
```

No system proxy/DNS/TUN/helper changes. Do not treat local fixtures as provider
availability, IP purity, DNS-leak or performance acceptance. Consent, contract,
artifact provenance and pending runtime checks: `.agents/node-quality.md`.

## Coordinated Windows Staging Build And Native IPC Acceptance

From the repository root (build only; does not launch the app or helper):

```powershell
./scripts/build_node_quality_windows.ps1
```

Each invocation creates `build/node-quality-release-<timestamp>/bundle` and a
`delivery.json`. It validates staged core/helper equality and the core hash
embedded in the helper and Flutter AOT file; records app, AOT, Rust IPC and helper
hashes; leaves existing `libclash/windows` binaries and root hash manifest intact.
This script shares Flutter's `build/windows` intermediate directory: do not run
it concurrently with `flutter run` or another Windows build. Copy the whole bundle,
not just the executable. Building never proves GUI/helper runtime acceptance.

Windows/Linux CMake now invokes the language build tools on every native build,
using their incremental caches rather than artifact-existence checks. The active
multi-config `$<CONFIG>` selects Debug/Release. `BUILDKIT_OUTPUT_DIR` overrides
core/helper output and install paths; `CARGO_TARGET_DIR` isolates helper output.
Debug builds no longer kill a running helper; use staging if files are locked.

Explicit native acceptance against the returned bundle (replace the placeholder):

```powershell
$bundle = (Resolve-Path 'build/node-quality-release-<timestamp>/bundle').Path
$env:QUANCLASH_NODE_QUALITY_IPC_CORE = Join-Path $bundle 'QuanClashCore.exe'
$env:QUANCLASH_NODE_QUALITY_IPC_RUST = Join-Path $bundle 'rust_api.dll'
flutter test test/core/node_quality_ipc_test.dart --reporter expanded --no-pub
Remove-Item Env:QUANCLASH_NODE_QUALITY_IPC_CORE, Env:QUANCLASH_NODE_QUALITY_IPC_RUST
```

The test loads the real Rust bridge, production Dart transport/shared facade and
private child core. SOCKS destinations are refused locally, never forwarded to
Cloudflare/IPPure. It kills only its own child before joining Windows IPC, checks
native stopped state, then starts/stops twice more. No app/helper managers run.
Default full Flutter tests skip this test and the marker-only CMake test.

```powershell
flutter test test/core/transport_test.dart test/core/interface_test.dart --reporter expanded
$env:QUANCLASH_BUILDKIT_TEST_CMAKE = (Get-Command cmake).Source
$env:QUANCLASH_BUILDKIT_TEST_NINJA = (Get-Command ninja).Source
flutter test test/setup_buildkit_test.dart --reporter expanded
Remove-Item Env:QUANCLASH_BUILDKIT_TEST_CMAKE, Env:QUANCLASH_BUILDKIT_TEST_NINJA
```

If Ninja is not on PATH, use its absolute path from the Visual Studio CMake
installation. This CMake fixture only writes markers; it invokes no Go/Rust build.
Run `flutter test test/options_test.dart --reporter expanded` from
`plugins/setup/buildkit/build_tool`, and `cargo test` plus
`cargo clippy --all-targets -- -D warnings` from `plugins/rust_api/rust`.
## Typed Connection Update Client Verification

From the repository root. Unit fixtures do not open sockets or start the core:

```powershell
flutter test test/core/connection_updates_test.dart --reporter expanded
```

Opt-in real Rust IPC/local TCP echo verification, using a matching core/DLL bundle:

```powershell
$bundle = (Resolve-Path 'build/node-quality-release-<timestamp>/bundle').Path
$env:QUANCLASH_CONNECTION_IPC_CORE = Join-Path $bundle 'QuanClashCore.exe'
$env:QUANCLASH_CONNECTION_IPC_RUST = Join-Path $bundle 'rust_api.dll'
flutter test test/core/connection_updates_ipc_test.dart --reporter expanded --no-pub
Remove-Item Env:QUANCLASH_CONNECTION_IPC_CORE, Env:QUANCLASH_CONNECTION_IPC_RUST
```

The private core binds a freshly reserved loopback port; collision fails instead
of reclaiming a port/process. All traffic goes to a local echo fixture, not public
nodes or providers. Process lookup, DNS, TUN/controller and geo-update are disabled;
no app/helper/system proxy manager runs. The test validates real typed merge,
legacy snapshot equality, deletion, cursor loss, listener restart and shutdown.
It is low-volume correctness coverage, not IPC/forwarding/RSS performance or
Android/GUI/native-helper runtime acceptance. Default Flutter skips this opt-in.

## Serialized Connection Inspection Session Verification

From the repository root, no sockets/core required for the focused tests:

```powershell
flutter test test/core/connection_inspection_session_test.dart test/core/connection_updates_test.dart --reporter expanded --no-pub
```

Run the existing QUANCLASH_CONNECTION_IPC_CORE/RUST opt-in command above with a
matching bundle to test the session factory/coalesced refresh, strict legacy
full equality, lifecycle reset and inactive shutdown through real transport.
Compatibility uses a simulated unsupported update callback plus the actual full
IPC action; it does not swap/downgrade the core or certify an old binary. Repeat
in fresh Flutter processes (three runs for this checkpoint). Native teardown
terminates only its private child before transport join; EOF logging there is
expected, not a failure. Node-quality native regression uses its existing
QUANCLASH_NODE_QUALITY_IPC_CORE/RUST command and refuses destinations locally.

Current full-suite/analysis evidence: 637 passed/three default-skipped opt-ins,
13 original infos. Offline pub get succeeds without changing dependencies. No
model/provider/schema changes in this checkpoint require code generation.
No app/helper/proxy/DNS/TUN manager runs. These are correctness checks, not cold/
churn performance, retained-memory/RSS or remote-provider/device acceptance.
Detailed admission/recovery limits: .agents/connection-updates.md.

## End-to-End Inspection Performance Verification

Use a new report path with a matching core/Rust bundle:

```powershell
$env:QUANCLASH_CONNECTION_IPC_CORE = Join-Path $bundle 'QuanClashCore.exe'
$env:QUANCLASH_CONNECTION_IPC_RUST = Join-Path $bundle 'rust_api.dll'
$env:QUANCLASH_INSPECTION_PERF = '1'
$env:QUANCLASH_INSPECTION_PERF_OUTPUT = Join-Path (Resolve-Path build).Path 'inspection-perf-new.json'
flutter test test/core/connection_inspection_performance_test.dart --reporter expanded --no-pub
Remove-Item Env:QUANCLASH_CONNECTION_IPC_CORE, Env:QUANCLASH_CONNECTION_IPC_RUST, Env:QUANCLASH_INSPECTION_PERF, Env:QUANCLASH_INSPECTION_PERF_OUTPUT
```

This runs three alternating fresh-child pairs with 128 local TCP records, stable
polling, half/full replacement churn and quiet TTL recovery. It is a JIT/loopback
client-cost comparison, not Release/AOT, leak, forwarding or remote-node
acceptance. Full-action fallback and the existing page remain the safety path.

## Traffic Class Foundation Verification

From `core/` with `CGO_ENABLED=0`. These are pure parser/matcher tests and do not
start a core, open sockets or alter forwarding:

```powershell
go test -run '^TestTrafficClass' -count=3 .
go test -tags=with_gvisor -count=1 ./...
go vet -tags=with_gvisor .
gofmt -l traffic_class.go traffic_class_test.go
```

The matcher is not wired to an action or data path yet. Passing tests certify the
configuration/matching contract only, not connection limits, shaping, queues or
QoS behavior.

## TrafficClass Versioned Preparation Verification

The Go actions are enabled only in the candidate core; no production Dart caller
or shaper is active. Run from `core/` with CGO disabled, using new output filenames:

```powershell
$env:CGO_ENABLED = '0'
go test -count=3 -run '^TestTrafficClass' .
go test -tags=with_gvisor -count=1 ./...
go vet -tags=with_gvisor .
go build -tags=with_gvisor -ldflags='-w -s' -o ../build/QuanClashCore-traffic-class-new.exe .
$env:QUANCLASH_TRAFFIC_CLASS_SMOKE = (Resolve-Path ../build/QuanClashCore-traffic-class-new.exe).Path
go test -tags=with_gvisor -run '^TestDesktopTrafficClassStateSmoke$' -count=3 -v -timeout 90s .
Remove-Item Env:QUANCLASH_TRAFFIC_CLASS_SMOKE
```

The opt-in test uses a private named pipe/core plus loopback fixtures. No helper,
TUN, system proxy/DNS/routes or public provider probes run. Reuse the existing
QUANCLASH_CONNECTION_IPC_CORE/RUST and QUANCLASH_NODE_QUALITY_IPC_CORE/RUST fixtures
with this candidate core and the known Rust DLL for existing-function regression.
New TrafficClass action verification currently uses Go IPC only; shared Dart
facade and Android device acceptance are pending. Contract: `.agents/traffic-class.md`.
