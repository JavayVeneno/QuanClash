# Manual Node Quality Checks

## Delivery Checkpoint - 2026-10-30

The first implementation is complete in source and isolated tests. It does not
replace release core/helper artifacts or redesign the UI. Remote-provider/device
acceptance is pending; this is not a DNS-leak or security verdict.

## User Flow

- A separate shield icon beside latency opens a dialog in all three proxy-card
  styles. Opening sends nothing and does not change proxy selection.
- The dialog pins the concrete node resolved from the existing selection model.
  The core rejects mutable groups/non-dialing pseudo adapters. A concrete node
  can still have a configured dialer-proxy chain; this feature does not freeze the
  entire chain. DIRECT intentionally measures direct egress.
- Check now requests Cloudflare. IPPure is excluded unless explicitly enabled
  in this dialog. Consent itself sends nothing and is never persisted.
- Manual HTTPS includes adapter handshake, TLS validation and HTTP response.
  It does not call URLTest, change health history/ranking, or require a previous
  latency URL to succeed. Providers fail independently: a blocked Cloudflare
  endpoint does not establish that IPPure is also unreachable.
- Both providers see their request's egress IP and HTTP/TLS metadata. QuanClash
  does not explicitly send account/profile/proxy credentials to them. Adapter
  DNS/bootstrap may still be direct, as disclosed in UI.
- Retry/config/selection/profile/lifecycle changes clear stale reports; changes
  reset consent and invalidate late results. Closing drops results rather than
  adding another cancellation action. In-flight core work has request bounds.
- Only the current dialog report is retained. No background timer, high-frequency
  health check, persistent cache or quality ranking is enabled. Future caches
  must include provider, observed egress IP and protocol, plus freshness/consent.

## Contract

Shared desktop IPC and Android FFI action: `testNodeQuality`. Action data is a
JSON **string**, matching existing conventions:

```json
{"proxy-name":"node","providers":["cloudflare","ippure"]}
```

Requests reject extra keys, unsupported/duplicate providers, trailing JSON,
empty identity/provider lists and input over 4096 bytes. No caller-selected URL,
API key, profile content or arbitrary destination is accepted.

```json
{
  "schemaVersion": 1,
  "source": "selected-proxy",
  "proxyName": "node",
  "sampledAt": "2026-10-30T01:02:03Z",
  "network": {
    "provider": "cloudflare", "status": "ok",
    "egressIp": "203.0.113.1", "colo": "HKG", "country": "HK", "ttfbMs": 42
  },
  "quality": {
    "provider": "ippure", "status": "ok",
    "egressIp": "203.0.113.2", "riskScore": 75, "isResidential": false
  }
}
```

`sampledAt` is the UTC check start, not each provider's completion time. TTFB
includes adapter dial/handshake and TLS from request start; it is not RTT or
throughput. Status: `ok`, `failed`, `timeout`, `unavailable`, `not-requested`.
Failures/unrequested probes contain no success metrics. Stable error categories
cross IPC, never response bodies/credentials/raw network exceptions.

The Dart facade validates schema/source/node/provider identity, metric types and
ranges, opt-in consistency, and absence of metrics in failure responses.
Cloudflare and risk fields cannot be mixed. Different observed IPs stay attached
to their own provider, with a warning against attributing one provider's risk to
the other's IP. Missing scores are null/unknown; genuine IPv4 zero is retained.

## Provider Boundaries

- Cloudflare: fixed HTTPS host `www.cloudflare.com`, path `/cdn-cgi/trace`.
  Exposes validated `ip`, `colo`, `loc`; rejects duplicate recognized fields.
- IPPure: fixed HTTPS host `my.ippure.com`, path `/v1/info`. Verified against the
  [official My IP Information API documentation](https://ippure.com/en/MyIP-Info-API)
  on 2026-10-30. Published fields: `ip`, `fraudScore`, `isResidential`. The page
  explicitly labels the API Beta. No API key is documented or guessed; unknown
  fields are ignored.
- The adapter accepts integer fraudScore in 0..100. Incompatible schemas fail
  instead of being silently rescaled. The public API page does not fully define
  IPv6 scoring, confidence/calibration or rate limits. IPv6 risk scores are
  therefore suppressed in Go/Dart pending verification. False residential means
  non-residential, not inferred data-center. Risk is advisory, never a purity
  percentage or safety guarantee.

## Resource And Network Bounds

- At most two concurrent core jobs and two sequential providers per job. Excess
  jobs return `busy`, without a waiting queue.
- Six-second request context per provider, covering dial/TLS/headers/body;
  15-second desktop IPC/dialog deadline. Android now respects the existing
  optional per-action timeout rather than dropping it.
- Certificate validation stays enabled. Redirects are not followed; non-2xx,
  oversize and malformed responses fail. No environment/system HTTP proxy,
  compression or keep-alive. Headers capped at 16 KiB; bodies at 256 KiB,
  including streamed bodies. Bodies/connections are closed.
- Target metadata goes directly to the pinned Mihomo adapter, without a separate
  `net.DefaultResolver` lookup or routing-rule selection for the probe destination.
  Adapter bootstrap/dialer-proxy/L3 internals are not a proxy-only guarantee.
- No forwarding hooks or changes to system proxy, DNS, TUN or routes.

## Verification

Passed on 2026-10-30:

- `flutter pub get`, intl_utils and build_runner generation; no hand-edited
  generated output.
- Analysis: 13 pre-existing infos, no new warnings/errors. Focused Dart tests:
  26 passed; full suite: **556 passed**. Covers opt-in/no-open/no-timer requests,
  missing/zero/IPv6 scores, mismatch, timeout/retry/disconnect/profile changes,
  late disposal, four locales at 360x800 and three card styles.
- Go default/gVisor tests and vet; three focused runs. Covers validation, parsers,
  local HTTPS with validated certificates, destination pinning, redirects,
  rate-limit failures, body bounds/timeouts, redaction, admission/independent errors.
- Three opt-in private Windows named-pipe runs. A loopback SOCKS5 fixture receives
  fixed destinations and **refuses** them; no public provider request is sent.
  Validates schema/opt-in, arbitrary URL rejection, concrete-node selection,
  missing/group/inactive states and refusal-as-unknown.
- Verge/Mihomo process identity/listening TCP ports and WinInet proxy fingerprint
  are unchanged around IPC runs. This is scoped observation, not a full route/DNS
  or device leak audit. Release core/helper hashes remain unchanged.
- Five desktop gVisor cross-builds pass: Linux amd64/arm64, macOS amd64/arm64,
  and Windows arm64. Builds are not native-runtime/device acceptance.

Private Windows artifact: `build/QuanClashCore-node-quality.exe`, SHA256
`97e43c343eeb5bde892838ef11692aa7999194de9a52071626e88844dab77a8a`.
Local logs/guard: `build/node-quality-flutter-tests.log`,
`build/node-quality-network-guard.json` (not committed).

Reproduce from `core/`, with `CGO_ENABLED=0`:

```powershell
go test -tags=with_gvisor -run '^TestNodeQuality' -count=3 .
go build -tags=with_gvisor -o ../build/QuanClashCore-node-quality.exe .
$env:QUANCLASH_NODE_QUALITY_SMOKE = (Resolve-Path ../build/QuanClashCore-node-quality.exe).Path
go test -tags=with_gvisor -run '^TestDesktopNodeQualitySmoke$' -count=3 -v -failfast -timeout 60s .
Remove-Item Env:QUANCLASH_NODE_QUALITY_SMOKE
```

Default Go tests skip the child smoke. Local fixture success is not real provider
availability/score accuracy, remote protocol compatibility, forwarding/RSS/CPU
improvement, or absence of DNS leaks.

## Remaining Acceptance

- GUI/helper runtime and explicitly approved remote-node/provider
  checks without taking over Clash Verge/system integration. Verify real schemas,
  score availability, rate limits and freshness before cache/ranking features.
- Android NDK/c-shared/FFI/device and Linux/macOS native runtime verification.
- Then connection-inspection consumer/performance gates, TrafficClass/QoS,
  protocol acceptance, and finally the deferred UI redesign.

## Coordinated Build And Native Transport Checkpoint - 2026-10-30

`build/node-quality-release-20261030-140517-668/bundle` is the final staged
Windows Release snapshot for this checkpoint. It contains app/AOT, core, Rust
IPC DLL and helper together. `scripts/build_node_quality_windows.ps1` validates
staged core/helper equality and presence of the core token in both AOT/helper.
The Flutter runner hash alone is not app-code identity; AOT is recorded separately.

### Shutdown Fix

Two independent waits blocked fixture teardown even after all node-quality
requests had succeeded:

1. Dart awaited FRB stream cancellation before stopping its producer. The async
   receive stream could not finish cancellation while the native sink remained
   alive. `IPCCoreTransport.close` now stops first, then cancels and closes;
   repeated close shares a future and late events cannot trigger crash callbacks.
2. Rust joined the worker while holding STATE, which the exiting worker also
   locks. It now takes the handle and releases STATE before synchronously joining.

No detached reaper, nonblocking frame-parser rewrite or new idle polling remains.
Windows owners must first disconnect their child before stopping this blocking
reader. Stop against a still-live client and concurrent native restart/stop are
not validated or claimed fixed. The fixture kills only its own child, verifies
native stopped/disconnected state and completes two additional no-client starts
and stops on the same pipe name. It never starts the application managers/helper.

### Verification Scope

- Final bundle DLL/core plus production Dart IPCCoreTransport/shared facade:
  three complete native fixture runs pass. Missing/group/inactive states, default
  CF-only and IPPure opt-in, fixed SOCKS destinations and unknown-on-refusal are
  validated. All outbound CONNECTs are refused by loopback; no provider is contacted.
- Full Flutter: **561 passed**, two opt-in tests skipped by default. Native IPC
  and marker-only CMake are separately exercised. Analysis: 13 original infos,
  no new diagnostics. Two mock transport regressions and three connection-update
  interface tests cover cleanup and the preparatory (not active in UI) action.
- Rust: two tests and clippy with warnings denied pass. Default/gVisor Go tests
  and tagged vet pass; three additional Go refused-loopback smoke runs pass.
- CMake marker-only test verifies repeated builds despite existing outputs,
  Debug/Release switching, deleted-helper recreation and staging with spaces.
  Four build-tool option tests pass. The earlier desktop cross-build evidence
  applies to Go, not native runtime validation of this Rust shutdown change.
- Pre/post system proxy, DNS server addresses, route table, Verge/helper process
  identity and published core/helper file hashes match. No test child remains.
  These are bounded observations, not packet-capture proof of no DNS leaks.
- Whole GUI AOT startup, helper authorization and real provider checks were NOT
  run. `delivery.json` keeps runtimeVerified=false and remoteProvidersVerified=false;
  successful build/native fixture must not silently set these to true.

Local evidence: `build/node-quality-delivery-20261030.log`,
`build/node-quality-delivery-ipc-{1,2,3}-20261030.log`,
`build/node-quality-flutter-accepted-20261030.log`,
`build/node-quality-analysis-accepted-20261030.log`, and
`build/node-quality-cleanup-{before,after}-20261030.json` (Git-ignored).
Earlier failed IPC runs/bundles are diagnostic artifacts, not accepted packages.

### Artifact SHA256

- Core: `99d17b3dc442997133c199e7bf76957014f1364022ecaa02b5bd45030c228a2c`.
- Flutter runner: `55ca3aec4694f06d98fa594530c51e9cceb349c78e3dbf8262ffc5eb3e99de0e`.
- Flutter AOT: `233048843d50d58d37227ed7ce4edd0c2c853faca0deb5921569f10f9811822d`.
- Rust IPC DLL: `e208c15c0d9c3f7ffe266931fbc2af1d2e0e655990aada48e08f69d4e5fb64ce`.
- Helper: `f15104695b8ab54d2bb58f5b5df0533f47939f05f68ce15a0de289f61d0d12ce`.

## Probe Impact And Cloudflare Score Boundary - 2026-11-02

- `/cdn-cgi/trace` does not return a Cloudflare Bot Score. Bot Management's
  request score is scoped to one request and is exposed only by an authorized
  site/origin (for example `cf.botManagement.score`); there is no public
  per-IP Cloudflare risk lookup in this feature. The UI now prints the
  Cloudflare score as unavailable instead of inferring one from TTFB or colo.
- IPPure `fraudScore` remains the only risk number and is labelled
  "IP risk score (IPPure)". It is not a purity percentage and is not a
  Cloudflare verdict.
- Manual-probe footprint is disclosed in the dialog: one HTTPS request per
  selected provider, no automatic retries or polling, no shared cookies, no
  keep-alive and no spoofed browser TLS/UA. The honest
  `QuanClash-NodeQuality/1` UA stays. Third parties may still log the request;
  zero impact cannot be guaranteed.
- Added a local 30-second per-(node, provider) courtesy cooldown, bounded to
  256 entries. It is recorded at request start, covers failed/timeout attempts
  and queues no work. It is not IP-level: different node names may share an
  egress IP, and restarting the app clears it.
- Verification: 30 focused node-quality tests pass; full Flutter
  **724 passed / 5 skipped**; analysis remains the 13 pre-existing infos. No
  Go/Rust/core/binary change. Real provider, GUI/helper and device acceptance
  remain pending.

## Dashboard Risk Index Display - 2026-11-04

- The dashboard now shows the most recent **successful manual** probe for the
  currently selected node: IPPure risk score and sampled time. It is treated as
  "not checked" after 10 minutes or when the selected node changes.
- The result is held in memory only: no persistence, no polling, no background
  probe. Opening the dashboard card opens the existing dialog, and no request is
  sent until the user presses the check button and opts into IPPure there.
- Cloudflare fields remain network context, not a risk score; the card does not
  infer or display a Cloudflare risk verdict.

## Proxy Page Risk Badge And Dialog Restyle - 2026-11-05

- Results are now kept per node in memory (`nodeQualityResultsProvider`) instead
  of a single last result. A fresh successful manual probe (within 10 minutes)
  shows as a `score/100` badge on that node's proxy card and on the dashboard
  risk card. Stale results are hidden; nothing is persisted, polled or probed in
  the background.
- Opening the dialog again within the freshness window shows the cached result
  without sending another request. Consent and cooldown behavior are unchanged.
- After a successful manual check the dialog closes automatically and a snackbar
  repeats the IPPure score; the detailed result remains available by reopening
  the dialog from the node badge or the dashboard card.
- Risk score presentation: `score / 100` plus a low/medium/high label, colored
  ≤30 green, 31–60 orange, ≥61 red. This presents the existing IPPure
  `fraudScore`; it is not a purity percentage, Cloudflare verdict or new metric.
- The proxy page also gained region grouping, recent/frequent sections and a
  collapsible provider-info section. Provider-info classification is
  name-based, display-only, and never applies to group-reference nodes; the
  classification does not change proxy selection or the core.
