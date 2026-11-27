# Changelog

QuanClash is a modified version of [FlClash](https://github.com/chen08209/FlClash).
The upstream changelog up to v0.8.94 is preserved in the git history; this file
records the changes made in this fork.

## Unreleased

### Added

- **Proxy Chains (Desktop & Android Mobile v4):** Support multi-hop entry/exit groups (or single-node direct links) stored per profile, with static strict-DNS-safe config generation, Möbius strip branding, Dashboard/tray/mobile active-chain display, and Rule/Global mode support.
- **Mobile v4 Globe Interaction:** Added horizontal swipe rotation with inertia on the 3D dot-matrix globe.

### Fixed

- **Mobile v4 Globe Orientation:** Corrected the sphere coordinate projection so East-West and Asia/China coastlines render without mirror inversion.

## v0.0.4

### Added

- **Android Mobile v4 single-surface redesign:**
  - Interactive 3D dot-matrix globe (Natural Earth 110m land dots & country borders) with swipe-up to connect / swipe-down to disconnect and smooth 900ms animated geo tracking that rotates the active proxy city to the front.
  - Obsidian-Amethyst glass floating QuanClash hub icon with real cloud silhouette and dynamic mode-specific golden accent (crescent for Rule, 360° halo for Global, minimal spark point for Direct).
  - iOS-26-inspired **Liquid Glass L-Dock** on long press: slide horizontally across the 4-slot floating capsule (`Proxy`, `Config`, `Monitor`, `Settings`) or slide vertically across the 3-mode rail (`Global`, `Rule`, `Direct`) with live icon preview and haptic feedback.
  - Full Dark (`#000000` OLED), Light (Porcelain Glass), and Follow System theme support with dynamic Android navigation bar styling.
  - Android-wide **Liquid Glass switches** featuring an oversized transparent glass lens bloom during press and horizontal drag.
  - Desktop feature parity across modular frosted bottom sheets: Proxy search, sort (`Default / Delay / Name`), region grouping, one-tap expand/collapse all, batch delay test, inline node risk score & quality inspection, external providers; Config CRUD menu (`Update / Edit / Preview YAML / Overwrite / Delete`) & auto-update interval picker; dedicated Monitor telemetry sheet (`Connections`, `Requests`, `Logs`, `DNS Diagnostic`); Settings parity (`On-Demand / Wi-Fi Exclude`, `Advanced Config`, custom `riskApiUrl`, `Backup & Restore`, `Geo Resources`, `About & Update`).
- **Android CI & Release Pipeline:** Enabled automated Android APK builds (`arm64-v8a`, `armeabi-v7a`, `x86_64`) in GitHub Actions alongside Windows builds, with conditional signing and Firebase config handling.

### Changed

- **Windows 11 Fluent title bar:** Refined title bar height (`38px`), silky vertical gradient surface, whisper-thin bottom hairline, pixel-aligned `10×10` native geometric minimize/maximize/restore/close glyphs, and live `isMaximizedProvider` state synchronization.

### Fixed

- Android: Opening `Config > Edit Profile` no longer freezes (properly wrapped in `BaseScaffold`).
- Android: Replaced legacy upstream status-bar & Quick Settings tile notification icons (`ic_service.xml` / `ic.xml`) with the monochrome QuanClash cloud + crescent vector icon.

## v0.0.3

### Added

- A configurable risk endpoint: point the risk check at any public HTTPS JSON
  service, with `{ip}` filled in from the probed egress IP. Risk-style fields
  are used as-is; trust/reputation fields are inverted, and 0-1 ratios are
  scaled to 0-100. When a response carries both kinds of signal the worse of
  the two is reported, so a quiet abuse ratio cannot hide a mediocre
  reputation and vice versa.
- Failed checks state why they failed: HTTP status, connection or TLS failure,
  unparsable response, oversized response, timeout, or an invalid endpoint.

### Fixed

- The interface switched to English after opening Settings > About in a
  non-English language.
- The tray panel ignored the configured language.
- The About page reported a stale version and offered no way to check for
  updates.

### Changed

- The dashboard card that measures the IP API round trip is labelled "IP API
  latency" and explains how it differs from the proxy delay on the node list.

## v0.0.2

### Added

- DNS safety: derive `proxy-server-nameserver-policy` from the proxy-server
  names, pin the bootstrap resolver to an encrypted IP literal, and cover proxy
  providers when repairing the DNS configuration.
- Node speed test on the dashboard, with download and upload probes against
  `speed.cloudflare.com`.
- Core version reported over IPC and shown on the About page.
- Direct-connection fallback for subscription updates: when the proxied path
  fails at the connection layer, the request is retried once without the proxy.

### Fixed

- Crash with `Unsupported operation: Infinity or NaN toInt` in the logs and
  proxy lists when the scroll position became non-finite.
- Dashboard notification for the benign unified-delay "failed to get the second
  response" probe.

### Changed

- The bypass-domain editor is a centered dialog instead of a drawer page.
- Removed upstream brand references from packaging metadata, CI and the macOS
  test host.

## v0.0.1

- Rebrand to QuanClash: application identity, icons, bundle identifiers and
  packaging.
- Redesigned desktop interface: frosted-glass visual system, top icon
  navigation, fixed dashboard layout.
- DNS leak protection and a read-only DNS path diagnostic.
- Standalone tray panel window for starting, stopping and switching nodes.
