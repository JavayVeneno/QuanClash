<div align="center">

# QuanClash

A desktop-focused, multi-platform proxy client built on mihomo.

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/JavayVeneno/QuanClash)](https://github.com/JavayVeneno/QuanClash/releases)

[简体中文](README_zh_CN.md)

</div>

## What is QuanClash?

QuanClash is a Flutter-based proxy client for Windows, macOS, Linux and Android.
It uses [mihomo](https://github.com/MetaCubeX/mihomo) (Clash.Meta) as its data
plane and focuses on a desktop-first experience: an in-app frosted-glass visual
system, top icon navigation, a fixed dashboard layout and a tray panel that can
start, stop and switch nodes without opening the main window.

The project is a modified version of [FlClash](https://github.com/chen08209/FlClash).
It keeps the GPL-3.0 license and documents the upstream attribution in
[NOTICE](NOTICE).

## Features

- Windows, macOS, Linux and Android from one Flutter codebase.
- Frosted-glass UI with light and dark themes, plus a pure-black mode.
- Top icon navigation, fixed desktop dashboard and a magpie-style tray panel.
- Subscription profiles, rule/script overrides, WebDAV sync and system proxy.
- TUN mode, TCP/UDP DNS and an explicit DNS safety model
  (`compatible`, `proxyOnly`, `custom`) with a read-only DNS path diagnostic.
- Manual node-quality checks (Cloudflare and opt-in IPPure) kept separate from
  the default latency ranking.
- Incremental connection inspection and TrafficClass classification are being
  built on top of the existing connection and statistics pipeline.

## Download

Builds are published on the
[Releases](https://github.com/JavayVeneno/QuanClash/releases) page. Each release
contains the Android APKs, Windows installer/portable zip, macOS DMGs and Linux
packages that were built for that tag.

## Build

1. Update submodules:

   ```bash
   git submodule update --init --recursive
   ```

2. Install Flutter and Go. CI uses Flutter 3.44.4 and the Go version declared
   in `core/go.mod`.

3. Build the app for the current platform (or Android):

   ```bash
   dart setup.dart android
   dart setup.dart windows
   dart setup.dart linux
   dart setup.dart macos
   ```

   - **Linux:** install the GTK and keybinder dependencies first:
     `sudo apt-get install libayatana-appindicator3-dev libkeybinder-3.0-dev`
   - **Windows:** install GCC and Inno Setup.
   - **Android:** install the Android SDK and NDK, and set `ANDROID_NDK`.
   - **macOS:** install `appdmg` (`npm install -g appdmg`).

## Project layout

- `lib/` — Flutter application (UI, managers, providers, core transport).
- `core/` — Go wrapper around the mihomo core plus QuanClash-specific actions.
- `core/Clash.Meta/` — mihomo submodule (GPL-3.0).
- `plugins/` — local Flutter plugins (Rust API, setup/build tooling, platform
  helpers).

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the build, test and code-generation workflow, [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
for community expectations, and [SECURITY.md](SECURITY.md) for reporting
vulnerabilities privately.

## License and attribution

QuanClash is free software under the **GNU General Public License v3.0**. See
[LICENSE](LICENSE) and [NOTICE](NOTICE).

- Upstream project: [FlClash](https://github.com/chen08209/FlClash),
  Copyright (C) chen08209 and contributors, GPL-3.0.
- Data plane: [mihomo / Clash.Meta](https://github.com/MetaCubeX/mihomo),
  GPL-3.0.

Changes made in this fork include rebranding, the desktop UI redesign, DNS
safety configuration and diagnostics, node-quality checks, incremental
connection inspection and TrafficClass groundwork. The git history records
the details.
