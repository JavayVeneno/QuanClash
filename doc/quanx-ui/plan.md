# QuanClash 开发计划(桌面版:顶部导航 + 托盘面板)

> 2026-10-15 更新:设计方向从「QuanX 风格复刻(左侧栏)」调整为「QuanX 视觉 × Windows 桌面交互」。
> 本文件替代此前的 QuanX UI 改造计划;设计依据见 `design-spec.md`,设计图:
>
> - `design-mockup-desktop.html`(当前方向:顶部图标导航 + 托盘面板)
> - `design-mockup.html`(已废弃:左侧栏方案,留档对比)

## 目标

在 FlClash 基础上,把 UI 改造为「QuanX 视觉语言 × Windows 桌面交互」:

- **顶部图标导航**:替换左侧边栏,仅图标、悬停显示文字。
- **桌面密度**:连接控制条、紧凑网格、底部状态栏,不做移动端式大卡片。
- **仪表盘固定布局**:按 QuanX 结构固定排布,取消自定义网格编辑。
- **托盘面板(magpie 式)**:点托盘图标弹出小面板,面板内可直接启停/切换节点;点「打开 QuanClash」进入主窗口。
- 深色/浅色双主题,令牌统一走 `lib/common/quanx.dart`。

## 边界

- 以表现层为主:`lib/` 下 UI、widgets、manager 外壳;
- 托盘面板明确纳入本计划,涉及 `lib/manager/tray_manager.dart`、`lib/manager/window_manager.dart` 与 `lib/common/window.dart` 的窗口行为调整;
- 不动 `core/`、`lib/core/`、平台原生目录(`windows/` `android/` `macos/` `linux/`)、`plugins/`、`services/`、依赖清单与生成文件;
- 品牌替换(应用名/图标/包名)不在本计划,另行立项。

## 已完成(前序,留档)

- P0–P5:QuanX 令牌层(`lib/common/quanx.dart`)与主题接入、标题栏、侧边栏、卡片、首页主控的视觉改造(其中侧边栏部分将被 S1 替换)。
- 设计图迭代三版(含对 codex 对比稿的评估),最终方向见 `design-mockup-desktop.html`。

## 阶段

### S0 验证基线与文档(进行中)

- 沙箱安装 Flutter 3.44.4(对齐 CI),对现状跑 `flutter pub get` → `flutter analyze --no-fatal-infos` → `flutter test --reporter expanded`;
- 修正 `.agents/project.md` 中的过期版本信息;
- 更新本计划与 `design-spec.md`。

### S1 顶部图标导航

- `lib/manager/app_manager.dart`:`AppSidebarContainer` 的 NavigationRail 侧边栏 → 顶部图标条(悬停 Tooltip 显示名称、选中态用主题色;移动端布局不受影响);
- `lib/manager/window_manager.dart`:标题栏加入品牌区(应用图标 + 名称,取 `appName`);
- 侧边栏宽度归零,避免影响 `contentWidth` 计算;
- 受影响:所有桌面页面的顶部布局。

### S2 桌面密度 + 仪表盘固定布局

- 新增组件:连接控制条(状态/时长/速率/节点/暂停)、底部状态栏;
- `lib/views/dashboard/dashboard.dart`:改为固定 QuanX 布局,移除编辑模式与 SuperGrid 依赖(保留底层设置字段,避免动模型/生成文件);
- 卡片密度:`lib/widgets/card.dart` 收紧内边距与行高;
- 网络检测卡扩充(出口 IP/地区/延迟)。

### S3 托盘面板(magpie 式)

- 托盘左键点击 → 显示小面板窗口(定位到托盘上方,失焦自动隐藏);
- 面板内容:状态/速率/暂停/当前节点/出站模式/系统代理/TUN + 「打开 QuanClash」「退出」;
- 「打开」切换为主窗口全尺寸;主窗口关闭与托盘联动(沿用现有 `handleClose` 逻辑);
- 文件:`lib/manager/tray_manager.dart`、`lib/manager/window_manager.dart`、`lib/common/window.dart`、`lib/pages/home.dart`、新增面板视图;
- 必须 Windows 实机验证。

### S4 收尾

- 其余页面密度走查(代理/配置/连接/日志/工具);
- 深色主题走查;
- 行尾规范化(`.gitattributes` + `git add --renormalize` 单独提交)与分阶段提交。

## 验证

- 每阶段:沙箱 `flutter analyze --no-fatal-infos` + `flutter test --reporter expanded`;
- 里程碑:Windows 实机(本机)跑 `flutter run -d windows`,重点验证 S1 导航、S2 布局、S3 托盘行为;
- 提交策略:先做行尾规范化提交,再按阶段独立提交,便于回退。

## 执行状态(2026-10-15)

- [x] S0 验证基线:沙箱 Flutter 3.44.4;analyze 0 错、417 测试全过
- [x] 基线提交:`032a3a0`(.gitattributes)/ `031682b`(P0–P5)/ `e807f81`(docs)
- [x] S1 顶部图标导航:`e5beecb`
- [x] S2 桌面仪表盘(连接控制条 + 固定布局 + 状态栏):`8b2a7e9`
- [x] S3 托盘面板:`48f0da1`
- [x] G1–G5 应用内毛玻璃体系 + Lucide 图标替换(2026-10-16,commits 6ab52c3 → 1f50eaa)
- [x] B1–B4 品牌替换(2026-10-17,commit 4441125):图标(极简线框云)+ 显示名 + 包名(com.quanclash.app)+ 内部组件名四端同步
- [ ] S4 其余页面密度走查(建议 Windows 实机验证后再做)
- [ ] Windows 实机验证(待本机环境)

## Windows 实机验证清单

前置:Windows 上安装 Flutter 3.44.4(对齐 CI)与 Visual Studio 2022(C++ 桌面开发负载),仓库根目录执行:

```bash
flutter pub get
flutter run -d windows
```

重点检查:

1. **S1**:顶部导航悬停显示名称、选中态;标题栏品牌区;窗口拖拽/双击最大化正常。
2. **S2**:连接控制条(状态/时长/速率/节点/启停按钮);仪表盘固定布局(宽窗口 3+4 列、窄窗口堆叠);底部状态栏;无溢出条纹。
3. **S3**:点托盘图标弹出小面板;点击别处自动收起;面板内启停/节点跳转/模式/开关生效;「打开 QuanClash」恢复主窗口尺寸;「退出」正常。

已知待调项:面板高度(当前 380)、失焦收起 600ms 防抖、「打开 FlClash」按钮文案暂为硬编码。
