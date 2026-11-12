# Security Policy

## Supported versions

Only the latest release (`0.0.x`) receives security fixes.

## Reporting a vulnerability

Please use GitHub's private vulnerability reporting: open the **Security** tab
of this repository and choose **Report a vulnerability**. Do not open a public
issue for a security problem.

Include:

- QuanClash version and platform (Windows / macOS / Linux / Android).
- Steps to reproduce and the affected component (Flutter app, DNS handling,
  IPC or the Go core wrapper).
- Relevant logs with subscription URLs, tokens and node credentials removed.

We aim to acknowledge a report within 7 days and to publish a fix and advisory
once a patch is available.

## Scope

- In scope: the Flutter application, the Go wrapper in `core/`, DNS safety
  configuration, IPC and local data handling.
- Out of scope: vulnerabilities in [mihomo](https://github.com/MetaCubeX/mihomo)
  and in the upstream [FlClash](https://github.com/chen08209/FlClash) project;
  please report those upstream.

## 中文说明

请通过仓库 **Security** 页的 “Report a vulnerability” 私密报告，不要在公开
issue 中披露漏洞细节。提交日志前请先去掉订阅地址、token 和节点密码。
