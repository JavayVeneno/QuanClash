# TrafficClass Preparation Contract

## Delivery State - 2026-11-02

The Go wrapper has a bounded classifier and a volatile, versioned configuration
store. `getTrafficClassState` and `setTrafficClasses` are wired through the shared
Go action dispatcher (desktop IPC / Android FFI dispatch). No Dart facade,
persisted profile field, production caller, forwarding hook, connection-count
accounting, quota, shaper, scheduler or UI consumes this configuration yet.
`status:prepared` means only that configuration can be stored for this core
lifecycle; `enforcing` is always false. This is not functional QoS or thread-level
control. Do not enable enforcement from this checkpoint.

## Configuration And Identity

The configuration object is:

```json
{
  "schemaVersion": 1,
  "classes": [
    {
      "id": "interactive",
      "priority": 5,
      "match": {"processNames": ["browser.exe"], "networks": ["tcp"]}
    }
  ]
}
```

Supported match dimensions are `processNames`, `processPaths`, `uids`, `packages`
and `networks`. Dimensions use AND; values within a dimension use OR. The first
class in configuration order wins. Priority is an optional signed int32 (default
zero), descriptive only, not a precedence override or working scheduling policy.
An explicit empty `classes:[]` clears the prepared set. IDs are case-sensitive
ASCII letters/digits/dot/underscore/hyphen; there is no implicit catch-all class.

Bounds: complete set request and standalone configuration <=1 MiB UTF-8;
<=256 classes; <=128 values/dimension; IDs <=64 bytes; selector text <=1024 bytes.
Unknown/case-aliased/duplicate object keys, null fields, empty specified match
dimensions, duplicate IDs/normalized values, malformed/out-of-range numbers and
empty matches are rejected. Null UID list entries never become UID zero. The JSON
parser uses Go's string decoding (including its Unicode escape handling); it is
not a separate strict Unicode-scalar validator. Limits bound accepted data, not
all transient allocations, RSS or arbitrary concurrent action admission.

Paths must be absolute under the running platform's path rules. Windows names
and cleaned paths use lowercase matching; Unix names/paths remain case-sensitive
and backslash filename characters are preserved. No filesystem lookup, symlink
resolution, Windows case-sensitive-directory detection or process lookup occurs
in the matcher. This is normalized textual identity, not file identity or a
security authorization mechanism.

`trafficClassInput` now requires explicit `UIDKnown` and a separate resolved
`PackageName`. Mihomo Metadata has no UID-validity bit: default zero, failed lookup
and real root UID zero must not be confused. `Metadata.Process` is overloaded and
cannot alone certify a package name. Missing identity fails that dimension rather
than matching a default. A future data-plane adapter must propagate validity from
the resolver; it cannot manufacture it from a nonempty path or UID numeric value.
No such adapter is installed here. Network-only rules remain independently usable
in pure matching tests. Existing packet metadata is not changed.

## Versioned Actions

Read `getTrafficClassState` (no data). The response is schema 1:

```json
{
  "schemaVersion": 1,
  "status": "prepared",
  "revision": "0123456789abcdef0123456789abcdef",
  "enforcing": false,
  "classes": [{"id": "interactive", "priority": 5}]
}
```

`inactive` has empty revision and classes. Class IDs/priorities are returned in
order; process/path/package/UID selectors are deliberately omitted. The read is a
summary, not an editable configuration export or proof of traffic classification.
Arrays returned to callers are detached from the compiled state.

Send `setTrafficClasses` data as a JSON string containing exactly
`schemaVersion:1`, `expectedRevision:<last accepted revision>` and
`config:<configuration object above>`. Revisions are opaque random 32-character
lowercase hex strings. An accepted replacement (including empty/same config)
rotates the revision and returns the exact accepted summary. Under concurrent
same-base writes only one succeeds. Parse/capacity errors, inactive state and
stale revisions never partially publish or clear a valid policy. Errors at the
dispatcher are fixed redacted strings, never raw selectors/parser messages.

State uses one atomic immutable snapshot and a serialized writer. There is no
historical revision cache, timer, reaper or packet queue. The preparatory actions
also hold `runLock` when reading/publishing so they do not acknowledge midway
through a serialized lifecycle change; parsing occurs before that lock, followed
by revision validation at publication. Future forwarding reads must capture one
snapshot rather than lock the whole lifecycle. Previously captured snapshots
remain immutable and are GC-eligible once readers release them; reclamation timing
or a total long-lived-flow memory bound is not asserted.

## Lifecycle And Recovery

- Initialization clears the set to inactive. Only successful profile setup makes
  it prepared. Listener/update invalidation alone cannot activate an unprepared
  state, even if `currentConfig` still references a previous profile.
- Accepted profile setup, runtime config update and listener start/stop clear the
  class set and invalidate its revision. Listener transitions preserve prepared
  readiness, not policy contents. Rejected profile parse/setup preserves the set.
- Shutdown clears it to inactive. Shutdown now serializes with the existing
  `runLock` used by other core configuration/listener operations. This is not a
  comprehensive repair of all pre-existing lifecycle races or Android TUN code.
- Resets cannot fail because of entropy: they clear immediately; the next prepared
  read lazily assigns a token. Entropy failure returns unavailable, never accepts
  an old token. Tokens also change after resets/core process replacement.
- A timeout/lost acknowledgment is not proof a write failed. Future clients must
  keep their desired configuration separately, serialize writes, invalidate their
  own lifecycle epoch, re-read the current summary and explicitly reconcile. Do
  not blindly retry an old revision or treat IDs alone as proof selectors match.
- This store is intentionally volatile. No file persistence, restart replay,
  automatic retry or profile owner exists yet. Clearing class state on lifecycle
  transitions is preparatory policy; revisit connection behavior and atomic
  routing/classification activation before enabling any enforcement.

## Verification

- 17 focused Go tests pass three runs: strict shape/type/bound checks, first match,
  dimension alternatives, explicit UID/package provenance, missing/relative paths,
  immutable input, CAS conflicts, resets and concurrent complete-snapshot reads.
- Full gVisor-tagged Go tests, tagged vet and gofmt pass. Five desktop cross-builds
  pass (Linux/macOS amd64+arm64 and Windows arm64). Runtime was Windows amd64 only;
  cross-build success does not execute Unix path tests. Go race-detector and Android
  NDK/FFI/device acceptance remain pending.
- New Go named-pipe action smoke passes three private-child runs: stored summary,
  stale/invalid rejection, config/listener invalidation, ordinary loopback TCP and
  inactive shutdown. This uses the Go fixture, not a new Dart TrafficClass facade.
- Existing production Rust/Dart connection IPC regression passes three runs and
  node-quality IPC regression passes with all destinations refused locally.
  Full Flutter: 642 passed, four default-skipped opt-ins; analysis: 13 original
  infos. No Dart/model/provider/schema changes require code generation here.
- Final private core: `build/QuanClashCore-traffic-class-state-final-20261102.exe`,
  SHA256 `675e4f1677ce3cc0f4387d78d6fb91e09a642442190f39898a1575e2db4efc55`.
  Built with CGO disabled, gVisor tag and `-ldflags="-w -s"`. Rust DLL reused from
  `build/node-quality-release-20261030-140517-668/bundle`, SHA256
  `e208c15c0d9c3f7ffe266931fbc2af1d2e0e655990aada48e08f69d4e5fb64ce`.
- Read-only `build/traffic-class-state-{before,after}-20261102.json` fingerprints
  match for proxy/DNS/routes, Verge/helper processes and published core/helper
  hashes. No private child remains. Published files and Mihomo submodule are
  unchanged. No TUN/system-network changes or public CF/IPPure probes run.

## Next Gate

Add a typed CoreHandlerInterface/CoreController client with redacted logging,
strict acknowledgments and owner epoch/timeout reconciliation tests; regenerate
the ActionMethod serialization when extending the Dart enum. Then implement an
explicit process/package resolution adapter and diagnostic-only classification
before any forwarding/QoS activation. Quantify lookup/admission/retention costs and
test failed lookup, missing UID, profile reload and shutdown behavior. Keep
connection inspection UI activation behind its existing performance gates and
defer visual redesign. Connection limits, shaping, scheduling and quota lifecycle
remain subsequent work, not functionality delivered by this preparatory API.
