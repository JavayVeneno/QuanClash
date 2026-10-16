# Quantumult X UI 分析与复刻规范（FlClash Windows 版）

> 本文是「QuanClash」视觉复刻的设计依据。所有结论来自 Quantumult X 官方站点与公开教程/文档，
> 并已映射为 FlClash 现有的 Flutter 表现层结构，不做任何业务逻辑改动。

## 1. 观察来源

- Quantumult X 官方站点：<https://quantumult.app/x/>
- Quantumult X 使用文档（社区整理）：<https://repcz.github.io/quantumult-x/getting-started/start>
- 公开教程对首页/节点页/网络活动页的结构描述（见第 3 节）

## 2. 视觉语言提取

| 维度 | Quantumult X 的做法 | 复刻结论 |
| --- | --- | --- |
| 底色 | 深色近黑，浅色为 iOS 分组背景灰 | 深色 `#0B0C0E`，浅色 `#F2F2F6` |
| 卡片 | 系统灰卡片，无投影，靠 1px 分隔线区分层级 | 深色卡片 `#14161A`，浅色纯白 |
| 分隔线 | 极细（1px），低对比 | `#262A30`（深）/ `#E2E3E8`（浅） |
| 圆角 | iOS 连续圆角（squircle） | 复用 Flutter `RoundedSuperellipseBorder`，卡片 12 |
| 强调色 | 青绿＝代理开启，黄＝直连，蓝＝交互，红＝异常 | `accent/info/warning/danger` 语义色令牌 |
| 排版 | 标题 15–17 加粗，辅助信息 12–13 次要灰 | 标题 `w600`，辅助 `textSecondary` |
| 层级 | 扁平、少阴影、少渐变 | 全部 `elevation: 0`，禁用 surfaceTint |
| 状态 | 行右侧延迟标签、状态图标（锁/笔/地球） | 语义色 + 细标签 |

## 3. Quantumult X 页面结构（用于后续首页/列表页复刻）

### 3.1 首页

- 顶部：连接开关 + 连接状态。
- 中部：连接时长、上下行流量、实时速率。
- 节点区：当前节点/策略组信息，可点击切换。
- 快捷区：右下角「风车」按钮承担模式切换/更新等动作。

映射到 FlClash：现有 Dashboard 网格（`lib/views/dashboard/`）已经承载
「速率 / 流量 / 模式 / 快速开关 / 网络检测」等卡片，本轮先统一它们的视觉语言，
后续阶段再按 QuanX 首页结构重排网格与主控位置。

### 3.2 节点页

- 顶部分段控件（节点 / 订阅）。
- 列表行 = 名称 + 延迟标签，右侧更多操作。
- 底部/顶部工具条：测速、排序、添加。

映射到 FlClash：`lib/views/proxies/`，复用 `CommonCard` 与延迟配色。

### 3.3 网络活动页

- 顶部分段：TCP / UDP / DNS / 脚本。
- 行内信息：主机名、命中规则、策略、流量、节点、重写。

映射到 FlClash：`lib/views/connection/`（连接）与 `lib/views/logs.dart`。

## 4. 设计令牌（已实现于 `lib/common/quanx.dart`）

### 4.1 颜色

| 令牌 | 深色 | 浅色 | 用途 |
| --- | --- | --- | --- |
| `background` | `#0B0C0E` | `#F2F2F6` | 页面底色 |
| `surface` | `#14161A` | `#FFFFFF` | 卡片 |
| `surfaceElevated` | `#1C1F24` | `#F7F7FA` | 悬浮/次级容器 |
| `surfaceSunken` | `#101216` | `#EAEAEF` | 侧边栏/下沉容器 |
| `separator` | `#262A30` | `#E2E3E8` | 1px 分隔线、卡片描边 |
| `textPrimary` | `#F2F3F5` | `#131519` | 主文本 |
| `textSecondary` | `#9BA1AA` | `#6C727A` | 次要文本 |
| `textTertiary` | `#6B7178` | `#9AA0A8` | 弱化文本 |
| `accent` | `#2ED3C0` | `#0FA795` | 代理开启/主控 |
| `onAccent` | `#04211E` | `#FFFFFF` | 强调色上的文本 |
| `info` | `#3B9CFF` | `#0A7AFF` | 链接/交互 |
| `success` | `#34C759` | `#1FA84E` | 成功 |
| `warning` | `#FFC53D` | `#E9A100` | 直连/警告 |
| `danger` | `#FF5A5F` | `#E03B41` | 失败/错误 |

### 4.2 形状与排版

| 令牌 | 值 | 用途 |
| --- | --- | --- |
| `QuanXRadius.group` | `12` | 卡片/分组 |
| `QuanXRadius.control` | `10` | 按钮/指示器 |
| `QuanXRadius.chip` | `6` | 标签 |
| 页面标题 | `20 / w600` | AppBar |
| 分组标题 | `titleSmall / w600` | InfoHeader |

### 4.3 ColorScheme 映射

FlClash 现有组件大量依赖 `ColorScheme` 的 surface 家族，因此复刻通过
`quanXColorScheme()` 把 QuanX 令牌映射回 Material 语义位，保证不改动业务组件：

| ColorScheme 位 | 映射 |
| --- | --- |
| `surface` | QuanX `background`（纯黑模式为 `Colors.black`） |
| `surfaceContainerLowest` | QuanX `surfaceSunken` / 纯白 |
| `surfaceContainerLow` | QuanX `surface`（卡片） |
| `surfaceContainer` | QuanX `surfaceSunken`（侧边栏） |
| `surfaceContainerHigh` | QuanX `surfaceElevated` |
| `surfaceContainerHighest` | QuanX `separator`（描边） |
| `onSurface` / `onSurfaceVariant` | `textPrimary` / `textSecondary` |
| `outline` / `outlineVariant` | `separator` |
| `secondaryContainer` | 主题色与卡片色的 15% 混合（选中态） |

> 说明：`primary` 仍然来自用户主题设置（动态取色 / 自定义主色），
> 保证 FlClash 既有「主题色设置」功能不被破坏；QuanX 的固定语义色
> （青绿/黄/红/蓝）通过 `context.quanX` 单独取用。

## 5. 桌面化修订(2026-10-15)

> 本节修订第 3 节中与「侧边栏」相关的结论;当前设计依据为 `design-mockup-desktop.html`。

### 5.1 外壳

- **顶部图标导航条**(高 40):仅图标(18px),悬停 Tooltip 显示名称;选中项 `accent-soft` 底 + `accent` 图标,未选中 `textSecondary`;右端可放置搜索等全局入口。
- **窗口标题栏**(40px):左 = 品牌(图标 + 名称),右 = 窗口按钮(pin/min/max/close);下缘 1px 分隔线。
- **底部状态栏**(27px):左 = 内核状态/端口/TUN,右 = 版本号。

### 5.2 桌面密度

- 行高 26–36px;卡片内边距 12/14;基准字号 12.5;
- **连接控制条**:状态 | 连接时长 | 实时速率 | 当前节点 | 暂停按钮,横向分段、1px 分隔;
- 卡片网格:≥700px 时 3 列,间隔 12。

### 5.3 托盘面板(magpie 式)

- 宽约 348;结构:头部(品牌 + 打开/设置/关闭图标)→ 状态区(状态/时长/速率 + 暂停按钮)→ 列表行(当前节点/出站模式/系统代理/TUN)→ 底栏(「打开 QuanClash」强调按钮 + 「退出」);
- 交互:点托盘图标弹出、失焦自动隐藏;「打开 QuanClash」进入主窗口。


## 6. 毛玻璃材质体系(2026-10-16)

> 为与 FlClash 原生「平面灰卡 + 1px 描边」彻底拉开差异,引入应用内毛玻璃体系。
> 全部由 Flutter 自绘,不依赖原生能力;窗口级真亚克力留作后续可选。

### 6.1 分层结构

1. **氛围背景**(`GlassBackdrop`):底部渐变 + 4 颗柔光色斑(自绘 `RadialGradient`),铺满窗口最底层。
2. **玻璃层叠**(`GlassPanel`):`阴影 → 圆角裁剪 → 背景模糊(BackdropFilter)→ 半透明填充 + 高光描边`。
3. **主题色联动**:色斑向主题色谐调 50%,玻璃填充再叠 6% 主题色;调整主题色时整个界面随动。

### 6.2 令牌(双主题)

| 维度 | 浅色 | 深色 |
| --- | --- | --- |
| 背景渐变 | `#F7F8FC → #E8EDF6` | `#0D1220 → #090C14` |
| 色斑 | 青绿/蓝/紫/暖橙 @30% | 同色系 @24% |
| 玻璃填充 | 白 45%→65% | 白 8%→14% |
| 描边 | 白 75% | 白 18% |
| 阴影 | 深蓝黑 @8% | 黑 @40% |
| 分隔线 | 黑 @20% | 白 @10% |

### 6.3 已玻璃化的面

外壳(标题栏/顶部导航/底部状态栏)、连接控制条、全部 `CommonCard` 与设置分组、
弹层与侧边面板、弹出菜单(真模糊玻璃)、对话框、代理页吸顶分组头、页面转场。

### 6.4 图标系统

Material 图标整体替换为 **Lucide** 线性图标(子集化 115 字形,~44KB,ISC 许可),
`lib/common/quanx_icons.dart` 提供 `QuanXIcons` 常量;统一 1.5px 圆头细线风格。

### 6.5 纯黑模式

纯黑模式(`pureBlack`)下关闭氛围色斑,仅保留玻璃层叠本身。
