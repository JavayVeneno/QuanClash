import 'package:quanclash/common/common.dart';
import 'package:quanclash/providers/config.dart';
import 'package:quanclash/views/config/network.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class TUNButton extends ConsumerWidget {
  const TUNButton({super.key});

  void _toggle(WidgetRef ref) {
    ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: !state.tun.enable));
  }

  void _showOptions(BuildContext context) {
    _showOptionsDialog(
      context,
      icon: QuanXIcons.chartLine,
      color: DashboardPalette.blue,
      title: context.appLocalizations.tun,
      items: [
        if (system.isDesktop) const TUNItem(),
        if (system.isMacOS) const AutoSetSystemDnsItem(),
        const TunStackItem(),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final enable = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    final stack = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.stack),
    );
    return SizedBox(
      height: getWidgetHeight(1) + 16.ap,
      child: DashboardCard(
        // 卡片主体直接开关,设置项收进右上角的「更多」。
        onPressed: () => _toggle(ref),
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.chartLine,
              color: DashboardPalette.blue,
              title: appLocalizations.tun,
              trailing: _CardSwitchTrailing(
                value: enable,
                onChanged: (value) {
                  ref
                      .read(patchClashConfigProvider.notifier)
                      .update((state) => state.copyWith.tun(enable: value));
                },
                onMore: () => _showOptions(context),
              ),
            ),
            const Spacer(),
            Text(
              stack.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.quanX.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemProxyButton extends ConsumerWidget {
  const SystemProxyButton({super.key});

  void _toggle(WidgetRef ref) {
    ref
        .read(networkSettingProvider.notifier)
        .update((state) => state.copyWith(systemProxy: !state.systemProxy));
  }

  void _showOptions(BuildContext context) {
    _showOptionsDialog(
      context,
      icon: QuanXIcons.shuffle,
      color: DashboardPalette.primary,
      title: context.appLocalizations.systemProxy,
      items: [const SystemProxyItem(), const BypassDomainItem()],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final port = ref.watch(
      patchClashConfigProvider.select((state) => state.mixedPort),
    );
    return SizedBox(
      height: getWidgetHeight(1) + 16.ap,
      child: DashboardCard(
        // 卡片主体直接开关,设置项收进右上角的「更多」。
        onPressed: () => _toggle(ref),
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.shuffle,
              color: DashboardPalette.primary,
              title: appLocalizations.systemProxy,
              trailing: _CardSwitchTrailing(
                value: systemProxy,
                onChanged: (value) {
                  ref
                      .read(networkSettingProvider.notifier)
                      .update((state) => state.copyWith(systemProxy: value));
                },
                onMore: () => _showOptions(context),
              ),
            ),
            const Spacer(),
            Text(
              '${appLocalizations.port} $port',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.quanX.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 卡片标题右侧的开关 + 「更多」入口。
class _CardSwitchTrailing extends StatelessWidget {
  const _CardSwitchTrailing({
    required this.value,
    required this.onChanged,
    required this.onMore,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: value,
          thumbColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? Colors.white : null,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? DashboardPalette.green
                : null,
          ),
          onChanged: onChanged,
        ),
        const SizedBox(width: 2),
        Tooltip(
          message: context.appLocalizations.more,
          child: InkResponse(
            onTap: onMore,
            radius: 14,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                QuanXIcons.ellipsisVertical,
                size: 16,
                color: context.quanX.textTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 仪表盘卡片的设置弹窗。
///
/// 与「节点质量检测」等新弹窗保持一致的居中对话框，替换旧的左侧抽屉式弹窗。
void _showOptionsDialog(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required List<Widget> items,
}) {
  showDialog<void>(
    context: context,
    builder: (_) {
      return QuanXDialog(
        icon: icon,
        color: color,
        title: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [...items.separated(const Divider(height: 0))],
        ),
      );
    },
  );
}

class VpnButton extends StatelessWidget {
  const VpnButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return AdaptiveSheetScaffold(
                body: generateListView(
                  generateSection(
                    items: [
                      const VPNItem(),
                      const VpnSystemProxyItem(),
                      const TunStackItem(),
                    ],
                  ),
                ),
                title: 'VPN',
              );
            },
          );
        },
        info: const Info(label: 'VPN', iconData: QuanXIcons.chartLine),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    vpnSettingProvider.select((state) => state.enable),
                  );
                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(vpnSettingProvider.notifier)
                          .update((state) => state.copyWith(enable: value));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
