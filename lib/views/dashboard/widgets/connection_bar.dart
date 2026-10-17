import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 桌面版连接控制条:状态 / 时长 / 速率 / 当前节点 / 启停主控
class ConnectionBar extends ConsumerWidget {
  const ConnectionBar({super.key});

  void _handleSwitchStart(WidgetRef ref) {
    final isStart = ref.read(isStartProvider);
    debouncer.call(FunctionTag.updateStatus, () {
      globalState.container
          .read(setupActionProvider.notifier)
          .updateStatus(!isStart, isInit: !ref.read(initProvider));
    }, duration: commonDuration);
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
    final group = ref.watch(
      groupsProvider.select((groups) => _getCurrentGroup(groups)),
    );
    final delayMap = ref.watch(delayDataSourceProvider);
    final lastTraffic = traffics.isNotEmpty ? traffics.last : const Traffic();
    final (statusText, statusColor) = switch (coreStatus) {
      CoreStatus.connecting => (appLocalizations.connecting, quanX.warning),
      CoreStatus.connected => (appLocalizations.connected, quanX.success),
      _ => (appLocalizations.disconnected, quanX.textTertiary),
    };
    final delay = switch (group) {
      Group(:final name, :final now) when now != null => delayMap[name]?[now],
      _ => null,
    };
    final separator = Container(
      width: 1,
      height: double.infinity,
      color: quanX.separator.opacity60,
    );
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final showSpeeds = width >= 560;
        final showNode = width >= 680;
        return GlassPanel(
          radius: GlassRadius.bar,
          blurSigma: 18,
          child: SizedBox(
            height: 62,
            child: Row(
            children: [
              _BarSegment(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Intl.message(mode.name),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: quanX.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              separator,
              _BarSegment(
                child: Text(
                  isStart ? utils.getTimeText(runTime) : '--:--:--',
                  style: context.textTheme.titleMedium?.adjustSize(2).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showSpeeds) ...[
                separator,
                _BarSegment(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(QuanXIcons.arrowUp, size: 13, color: quanX.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${lastTraffic.up.traffic.show}/s',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: quanX.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(QuanXIcons.arrowDown, size: 13, color: quanX.info),
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
                ),
              ],
              if (showNode)
                Expanded(
                  child: _BarSegment(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            group?.now ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (delay != null && delay > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (delay < 200 ? quanX.success : quanX.warning)
                                      .opacity12,
                              borderRadius: BorderRadius.circular(
                                QuanXRadius.chip,
                              ),
                            ),
                            child: Text(
                              '${delay}ms',
                              style: context.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: delay < 200
                                    ? quanX.success
                                    : quanX.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            group?.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: quanX.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              separator,
              _BarSegment(
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
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(
                    isStart ? QuanXIcons.pause : QuanXIcons.play,
                    size: 18,
                  ),
                  label: Text(
                    isStart ? appLocalizations.stop : appLocalizations.start,
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _BarSegment extends StatelessWidget {
  final Widget child;

  const _BarSegment({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}
