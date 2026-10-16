import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/window_manager.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 托盘小面板(magpie 式):点托盘图标弹出,「打开 QuanClash」进入主窗口
class PanelView extends ConsumerWidget {
  const PanelView({super.key});

  void _handleSwitchStart(WidgetRef ref) {
    final isStart = ref.read(isStartProvider);
    debouncer.call(FunctionTag.updateStatus, () {
      globalState.container
          .read(setupActionProvider.notifier)
          .updateStatus(!isStart, isInit: !ref.read(initProvider));
    }, duration: commonDuration);
  }

  void _handleOpen([PageLabel? pageLabel]) {
    window?.showMain();
    if (pageLabel != null) {
      globalState.container
          .read(currentPageLabelProvider.notifier)
          .toPage(pageLabel);
    }
  }

  Group? _getCurrentGroup(List<Group> groups) {
    for (final group in groups) {
      if (group.type == GroupType.Selector && (group.now?.isNotEmpty ?? false)) {
        return group;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    final colorScheme = context.colorScheme;
    final isStart = ref.watch(isStartProvider);
    final coreStatus = ref.watch(coreStatusProvider);
    final runTime = ref.watch(runTimeProvider);
    final traffics = ref.watch(trafficsProvider).list;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tunEnable = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    final group = ref.watch(
      groupsProvider.select((groups) => _getCurrentGroup(groups)),
    );
    final lastTraffic = traffics.isNotEmpty ? traffics.last : const Traffic();
    final (statusText, statusColor) = switch (coreStatus) {
      CoreStatus.connecting => (appLocalizations.connecting, quanX.warning),
      CoreStatus.connected => (appLocalizations.connected, quanX.success),
      _ => (appLocalizations.disconnected, quanX.textTertiary),
    };
    return GlassPanel(
      radius: 0,
      blurSigma: 24,
      shadow: false,
      child: Column(
        children: [
          _buildHeader(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isStart ? utils.getTimeText(runTime) : '',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Intl.message(mode.name),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 13, color: quanX.accent),
                    const SizedBox(width: 4),
                    Text(
                      '${lastTraffic.up.traffic.show}/s',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Icon(Icons.arrow_downward, size: 13, color: quanX.info),
                    const SizedBox(width: 4),
                    Text(
                      '${lastTraffic.down.traffic.show}/s',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: () {
                      _handleSwitchStart(ref);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: isStart
                          ? quanX.accent
                          : colorScheme.surfaceContainerHigh,
                      foregroundColor: isStart
                          ? quanX.onAccent
                          : colorScheme.onSurfaceVariant,
                    ),
                    icon: Icon(
                      isStart ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 17,
                    ),
                    label: Text(
                      isStart ? appLocalizations.stop : appLocalizations.start,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: quanX.separator),
                  bottom: BorderSide(color: quanX.separator),
                ),
              ),
              child: Column(
                children: [
                  _buildRow(
                    context,
                    label: appLocalizations.proxyGroup,
                    value: group?.now ?? '—',
                    onTap: () => _handleOpen(PageLabel.proxies),
                  ),
                  const Divider(),
                  _buildRow(
                    context,
                    label: appLocalizations.outboundMode,
                    value: Intl.message(mode.name),
                    onTap: () => _handleOpen(PageLabel.dashboard),
                  ),
                  const Divider(),
                  _buildSwitchRow(
                    context,
                    label: appLocalizations.systemProxy,
                    value: systemProxy,
                    onChanged: (value) {
                      ref
                          .read(networkSettingProvider.notifier)
                          .update(
                            (state) => state.copyWith(systemProxy: value),
                          );
                    },
                  ),
                  const Divider(),
                  _buildSwitchRow(
                    context,
                    label: appLocalizations.tun,
                    value: tunEnable,
                    onChanged: (value) {
                      ref
                          .read(patchClashConfigProvider.notifier)
                          .update((state) => state.copyWith.tun(enable: value));
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      _handleOpen();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: quanX.accent,
                      foregroundColor: quanX.onAccent,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 15),
                    label: Text('打开 $appName'),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () {
                      globalState.container
                          .read(systemActionProvider.notifier)
                          .handleExit();
                    },
                    child: Text(appLocalizations.exit),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: quanX.separator)),
      ),
      child: Row(
        children: [
          const AppIcon(),
          const SizedBox(width: 7),
          Text(
            appName,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            context,
            Icons.open_in_new,
            () {
              _handleOpen();
            },
          ),
          _buildIconButton(
            context,
            Icons.settings_outlined,
            () {
              _handleOpen(PageLabel.tools);
            },
          ),
          _buildIconButton(
            context,
            Icons.close,
            () {
              window?.hide();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final quanX = context.quanX;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 38,
        child: Row(
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: quanX.textSecondary,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 15, color: quanX.textTertiary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.quanX.textSecondary,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
