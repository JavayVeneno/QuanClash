# Changelog

QuanClash is a modified version of [FlClash](https://github.com/chen08209/FlClash).
The upstream changelog up to v0.8.94 is preserved in the git history; this file
records the changes made in this fork.

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
