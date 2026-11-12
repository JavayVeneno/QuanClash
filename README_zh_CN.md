<div align="center">

# QuanClash

基于 mihomo 的桌面优先、多平台代理客户端。

[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/JavayVeneno/QuanClash)](https://github.com/JavayVeneno/QuanClash/releases)

[English](README.md)

</div>

## 项目简介

QuanClash 是一个 **Windows 优先**的桌面代理客户端，数据面使用
[mihomo](https://github.com/MetaCubeX/mihomo)（Clash.Meta）。它把桌面端当作
主目标，而不是给手机应用套一层桌面外壳：应用内毛玻璃视觉体系、顶部图标导航、
固定仪表盘布局，以及可直接启停和切换节点的托盘面板。

多数开源 Clash 客户端本质上是手机应用——触屏尺寸的布局、过时的视觉，几乎没有
考虑桌面上的实际使用方式。QuanClash 基于 FlClash，围绕窗口、托盘和桌面工作流
重新设计这套体验。

本项目是 [FlClash](https://github.com/chen08209/FlClash) 的修改版本，继续采用
GPL-3.0 许可证，上游署名与修改说明见 [NOTICE](NOTICE)。

## 平台支持

| 平台 | 状态 |
|---|---|
| Windows | 主要目标平台，每次发布都会构建并测试 |
| macOS、Linux、Android | 同一套代码可以构建（继承自 FlClash），但目前未测试、未维护 |

当前只发布 Windows 产物。其他平台保留可构建状态，避免把路走死，但请视为未经验证。

## 功能

- 面向 Windows 的桌面优先界面；代码库仍保留 macOS、Linux 和 Android 目标。
- 毛玻璃界面，支持浅色/深色主题与纯黑模式。
- 顶部图标导航、桌面固定仪表盘、magpie 式托盘面板。
- 订阅配置、规则/脚本覆写、WebDAV 同步与系统代理。
- TUN、TCP/UDP DNS，以及显式的 DNS 安全模式
  （`compatible`、`proxyOnly`、`custom`）和只读 DNS 路径诊断。
- 手动节点质量检测（Cloudflare 与可选 IPPure），与默认延迟排序分离。
- 增量连接检查与 TrafficClass 分类正在现有连接/统计管线之上逐步接入。

## 下载

构建产物发布在 [Releases](https://github.com/JavayVeneno/QuanClash/releases)
页面，目前每个版本提供 Windows 安装包和便携包。

## 构建

1. 更新子模块：

   ```bash
   git submodule update --init --recursive
   ```

2. 安装 Flutter 与 Go。CI 使用 Flutter 3.44.4，Go 版本以 `core/go.mod` 为准。

3. 构建当前平台（或 Android）：

   ```bash
   dart setup.dart android
   dart setup.dart windows
   dart setup.dart linux
   dart setup.dart macos
   ```

   - **Linux**：先安装 GTK 与 keybinder 依赖：
     `sudo apt-get install libayatana-appindicator3-dev libkeybinder-3.0-dev`
   - **Windows**：安装 GCC 与 Inno Setup。
   - **Android**：安装 Android SDK/NDK，并设置 `ANDROID_NDK`。
   - **macOS**：安装 `appdmg`（`npm install -g appdmg`）。

## 目录结构

- `lib/`：Flutter 应用（界面、管理器、Provider、核心通信）。
- `core/`：mihomo 内核的 Go 封装，以及 QuanClash 自有动作。
- `core/Clash.Meta/`：mihomo 子模块（GPL-3.0）。
- `plugins/`：本地 Flutter 插件（Rust API、构建工具、平台辅助）。

## 参与贡献

欢迎提交 issue 和 pull request。构建、测试与代码生成流程见
[CONTRIBUTING.md](CONTRIBUTING.md)，社区规范见
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)，安全漏洞请按
[SECURITY.md](SECURITY.md) 私密报告。

## 许可证与署名

QuanClash 以 **GNU General Public License v3.0** 发布，详见
[LICENSE](LICENSE) 与 [NOTICE](NOTICE)。

- 上游项目：[FlClash](https://github.com/chen08209/FlClash)，
  Copyright (C) chen08209 及贡献者，GPL-3.0。
- 数据面：[mihomo / Clash.Meta](https://github.com/MetaCubeX/mihomo)，GPL-3.0。

本分支的修改包括品牌替换、桌面界面重做、DNS 安全配置与诊断、节点质量检测、
增量连接检查以及 TrafficClass 基础工作；具体变更记录在 git 历史中。
