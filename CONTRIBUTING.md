# Contributing to QuanClash

Thanks for taking the time to contribute. QuanClash is a modified version of
[FlClash](https://github.com/chen08209/FlClash) and is distributed under the
GNU General Public License v3.0. By contributing you agree that your changes
are licensed under the same terms.

## Before you start

- Search the [existing issues](https://github.com/JavayVeneno/QuanClash/issues)
  first.
- For anything larger than a bug fix, open an issue to discuss the approach
  before writing code.
- Security problems must not be reported in public issues; see
  [SECURITY.md](SECURITY.md).

## Prerequisites

- Flutter 3.44.4 (the version used by CI) with the desktop toolchain for your
  platform.
- Go, matching the version declared in `core/go.mod`.
- Platform extras:
  - **Linux:** `sudo apt-get install libkeybinder-3.0-dev` plus the GTK
    development packages.
  - **Windows:** GCC and Inno Setup.
  - **macOS:** `npm install -g appdmg`.
  - **Android:** Android SDK/NDK and `ANDROID_NDK`.

## Set up

```bash
git clone --recursive https://github.com/JavayVeneno/QuanClash.git
cd QuanClash
git submodule update --init --recursive
flutter pub get
```

Android builds also need `android/app/google-services.json`, which is not
committed. CI generates it from the `SERVICE_JSON` secret; use your own
Firebase configuration locally.

## Generated code

Do not edit generated files by hand; regenerate them:

```bash
dart run intl_utils:generate                              # arb/ -> lib/l10n
dart run build_runner build --delete-conflicting-outputs  # freezed, riverpod, drift
```

## Build and run

```bash
dart setup.dart windows      # or linux / macos / android
make core PLATFORM=windows   # rebuild only the Go core
```

## Checks

Every pull request must pass:

```bash
flutter analyze --no-fatal-infos
flutter test
dart format --output=none --set-exit-if-changed .
```

## Localization

Translations live in `arb/intl_*.arb` (`en`, `ja`, `ru`, `zh_CN`). When you add
or change a string, update every locale and regenerate with
`dart run intl_utils:generate`.

## Pull requests

- Branch from `main` and keep the change focused.
- Use the prefixes already present in the history: `feat:`, `fix:`,
  `fix(ui):`, `chore:`, `docs:`.
- Include tests for behaviour changes, and a screenshot or short recording for
  UI changes.
- Do not commit build output (`dist/`, `build/`, `libclash/`), local
  configuration, or Firebase credentials.

## 中文说明

- 提交前先跑 `flutter analyze` 和 `flutter test`。
- 改动 `arb/` 后要执行 `dart run intl_utils:generate`；`freezed`、`riverpod`、
  `drift` 的生成文件不要手改，用 `build_runner` 重新生成。
- 不要提交 `dist/`、`build/`、`libclash/`、`android/app/google-services.json`。
- 安全漏洞请走私密报告，不要开公开 issue。
