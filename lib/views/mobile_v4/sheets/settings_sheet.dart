import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/access.dart';
import 'package:quanclash/views/backup_and_restore.dart';
import 'package:quanclash/views/config/advanced.dart';
import 'package:quanclash/views/config/config.dart';
import 'package:quanclash/views/config/dns_diagnostic.dart';
import 'package:quanclash/views/config/on_demand.dart';
import 'package:quanclash/views/config/rules.dart';
import 'package:quanclash/views/config/scripts.dart';
import 'package:quanclash/views/connection/connections.dart';
import 'package:quanclash/views/connection/requests.dart';
import 'package:quanclash/views/logs.dart';
import 'package:quanclash/views/resources.dart';
import 'package:quanclash/views/settings/settings_modals.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../theme.dart';
import '../utils.dart';
import 'sheet_primitives.dart';

class MobileV4SettingsSheet extends ConsumerWidget {
  const MobileV4SettingsSheet({super.key, required this.controller});

  final ScrollController controller;

  String _dnsSafetyLabel(BuildContext context, DnsSafetyMode mode) {
    final l10n = context.appLocalizations;
    return switch (mode) {
      DnsSafetyMode.compatible => l10n.dnsSafetyModeCompatible,
      DnsSafetyMode.proxyOnly => l10n.dnsSafetyModeProxyOnly,
      DnsSafetyMode.custom => l10n.dnsSafetyModeCustom,
    };
  }

  Future<void> _showAppearancePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(
      themeSettingProvider.select((state) => state.themeMode),
    );
    const options = [
      (ThemeMode.system, QuanXIcons.sunMoon, '跟随系统', '自动同步设备浅色或深色外观'),
      (ThemeMode.light, QuanXIcons.sun, '浅色', '白瓷玻璃质感，参考桌面浅色体系'),
      (ThemeMode.dark, QuanXIcons.moon, '深色', '纯黑画布与星阵玻璃质感'),
    ];
    return showMobileV4ActionSheet(
      context: context,
      title: '外观',
      subtitle: '仅影响移动端与系统同步的外观主题',
      items: [
        for (final (mode, icon, title, sub) in options)
          MobileV4ActionItem(
            icon: icon,
            title: title,
            sub: sub,
            showRadio: true,
            selected: current == mode,
            onTap: () {
              ref
                  .read(themeSettingProvider.notifier)
                  .update((state) => state.copyWith(themeMode: mode));
            },
          ),
      ],
    );
  }

  Future<void> _editRiskApiUrl(
    BuildContext context,
    WidgetRef ref,
    String currentUrl,
  ) async {
    final l10n = context.appLocalizations;
    final value = await globalState.showCommonDialog<String>(
      child: InputDialog(
        title: l10n.riskApiUrl,
        labelText: l10n.url,
        description: l10n.riskApiUrlDesc,
        value: currentUrl,
        resetValue: '',
        inputFormatters: TextInputLimits.limit(TextInputLimits.url),
        validator: (text) {
          if (text == null || text.trim().isEmpty) {
            return null;
          }
          if (!utils.isValidRiskApiUrl(text)) {
            return l10n.riskApiUrlInvalid;
          }
          return null;
        },
      ),
    );
    if (value != null) {
      ref
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(riskApiUrl: value.trim()));
    }
  }

  Future<void> _checkForUpdate(BuildContext context) async {
    final l10n = context.appLocalizations;
    final data = await globalState.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: l10n.checkUpdate,
    );
    await globalState.container
        .read(commonActionProvider.notifier)
        .checkUpdateResultHandle(data: data, isUser: true);
  }

  Future<void> _showAboutSheet(
    BuildContext context,
    String coreVersion,
  ) {
    final l10n = context.appLocalizations;
    final versionSubtitle = coreVersion.isEmpty
        ? 'App $appVersion'
        : 'App $appVersion · Core $coreVersion';
    return showMobileV4ActionSheet(
      context: context,
      title: '关于 $appName',
      subtitle: versionSubtitle,
      items: [
        MobileV4ActionItem(
          icon: QuanXIcons.refreshCw,
          title: l10n.checkUpdate,
          sub: '检查 GitHub 最新发行版',
          onTap: () => _checkForUpdate(context),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.externalLink,
          title: l10n.project,
          sub: 'github.com/$repository',
          onTap: () => globalState.openUrl('https://github.com/$repository'),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.cpu,
          title: l10n.core,
          sub: coreVersion.isEmpty ? 'MetaCubeX / mihomo' : 'mihomo $coreVersion',
          onTap: () =>
              globalState.openUrl('https://github.com/MetaCubeX/mihomo'),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.info,
          title: l10n.disclaimer,
          sub: '查看使用声明与网络合规提示',
          onTap: () => globalState.showDisclaimer(),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.scale,
          title: '开源许可',
          sub: '查看第三方依赖许可信息',
          onTap: () => showLicensePage(
            context: context,
            applicationName: appName,
            applicationVersion: appVersion,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final l10n = context.appLocalizations;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final vpnProps = ref.watch(vpnSettingProvider);
    final accessControl = vpnProps.accessControlProps;
    final patch = ref.watch(patchClashConfigProvider);
    final dnsSafetyMode = ref.watch(
      networkSettingProvider.select((state) => state.dnsSafetyMode),
    );
    final excludeSsidsCount = ref.watch(
      excludeSSIDsProvider.select((state) => state.length),
    );
    final appSetting = ref.watch(appSettingProvider);
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final rulesCount = ref.watch(globalRulesProvider).value?.length ?? 0;
    final scriptsCount = ref.watch(scriptsProvider).value?.length ?? 0;
    final requestsCount = ref.watch(
      requestsProvider.select((state) => state.length),
    );
    final logsCount = ref.watch(logsProvider.select((state) => state.length));
    final coreVersion = ref.watch(coreRuntimeVersionProvider).value ?? '';
    final languageLabel = appSetting.locale == null
        ? l10n.defaultText
        : Intl.message(appSetting.locale!);
    final riskApiSubtitle = appSetting.riskApiUrl.isEmpty
        ? l10n.riskApiUrlDefault
        : appSetting.riskApiUrl;

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: [
        const MobileV4GroupLabel('连接', topPadding: 8),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.shield,
              title: '虚拟网卡',
              sub: vpnProps.enable ? 'VPN 已开启' : 'VPN 已关闭',
              trailing: MobileV4MiniSwitch(
                value: vpnProps.enable,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(vpnSettingProvider.notifier)
                      .update((state) => state.copyWith(enable: value));
                },
              ),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.layoutDashboard,
              title: '分应用代理',
              sub: accessControl.enable
                  ? '${accessControl.currentList.length} 个应用'
                  : '未启用',
              onTap: () => pushMobileV4Subpage(context, const AccessView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.zap,
              title: '出站模式',
              sub: mobileV4ModeShortLabel(patch.mode),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = mobileV4Modes[
                    (mobileV4Modes.indexOf(patch.mode) + 1) %
                        mobileV4Modes.length];
                ref
                    .read(patchClashConfigProvider.notifier)
                    .update((state) => state.copyWith(mode: next));
              },
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.lock,
              title: 'DNS 安全模式',
              sub: _dnsSafetyLabel(context, dnsSafetyMode),
              onTap: () {
                HapticFeedback.selectionClick();
                const modes = DnsSafetyMode.values;
                final next =
                    modes[(modes.indexOf(dnsSafetyMode) + 1) % modes.length];
                ref
                    .read(networkSettingProvider.notifier)
                    .update((state) => state.copyWith(dnsSafetyMode: next));
              },
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.radar,
              title: 'DNS 诊断',
              sub: '检查解析器健康状态与防泄漏',
              onTap: () =>
                  pushMobileV4Subpage(context, const DnsDiagnosticPage()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.wifi,
              title: '按需连接',
              sub: excludeSsidsCount == 0
                  ? 'Wi-Fi 自动排除与权限'
                  : '已排除 $excludeSsidsCount 个 Wi-Fi',
              onTap: () => pushMobileV4Subpage(context, const OnDemandView()),
            ),
          ],
        ),
        const MobileV4GroupLabel('监控与诊断'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.activity,
              title: '实时连接',
              sub: '查看活跃会话、规则命中与断流',
              onTap: () =>
                  pushMobileV4Subpage(context, const ConnectionsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.chartLine,
              title: '请求记录',
              sub: '$requestsCount 条记录',
              onTap: () => pushMobileV4Subpage(context, const RequestsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.scrollText,
              title: '运行日志',
              sub: '$logsCount 条日志',
              onTap: () => pushMobileV4Subpage(context, const LogsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.fileText,
              title: '日志记录',
              sub: appSetting.openLogs ? '已开启核心日志采集' : '已暂停记录',
              trailing: MobileV4MiniSwitch(
                value: appSetting.openLogs,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(openLogs: value));
                },
              ),
            ),
          ],
        ),
        const MobileV4GroupLabel('规则与配置'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.waypoints,
              title: '分流规则',
              sub: '$rulesCount 条',
              onTap: () => pushMobileV4Subpage(context, const AddedRulesView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.slidersHorizontal,
              title: '基础配置',
              sub: '端口 ${patch.mixedPort}',
              onTap: () => pushMobileV4Subpage(context, const ConfigView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.wrench,
              title: '高级配置',
              sub: '网络、DNS 与核心参数',
              onTap: () =>
                  pushMobileV4Subpage(context, const AdvancedConfigView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.braces,
              title: '脚本',
              sub: '$scriptsCount 个',
              onTap: () => pushMobileV4Subpage(context, const ScriptsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.shield,
              title: '风险检测接口',
              sub: riskApiSubtitle,
              onTap: () => _editRiskApiUrl(context, ref, appSetting.riskApiUrl),
            ),
          ],
        ),
        const MobileV4GroupLabel('通用与数据'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: p.isDark ? QuanXIcons.moon : QuanXIcons.sun,
              title: '外观',
              sub: mobileV4ThemeModeLabel(themeMode),
              onTap: () => _showAppearancePicker(context, ref),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.globe,
              title: '语言',
              sub: languageLabel,
              onTap: () => showLanguageSettingsModal(context),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.circlePlay,
              title: '启动时连接',
              trailing: MobileV4MiniSwitch(
                value: appSetting.autoRun,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(autoRun: value));
                },
              ),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.cloudSync,
              title: '备份与恢复',
              sub: '本地文件 / WebDAV 同步',
              onTap: () =>
                  pushMobileV4Subpage(context, const BackupAndRestore()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.database,
              title: 'Geo 资源管理',
              sub: 'GeoIP / GeoSite / ASN 数据库',
              onTap: () => pushMobileV4Subpage(context, const ResourcesView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.info,
              title: '关于与更新',
              sub: coreVersion.isEmpty
                  ? 'QuanClash $appVersion'
                  : 'App $appVersion · Core $coreVersion',
              onTap: () => _showAboutSheet(context, coreVersion),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'QUANCLASH $appVersion',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 1.6,
              color: p.faint,
            ),
          ),
        ),
      ],
    );
  }
}
