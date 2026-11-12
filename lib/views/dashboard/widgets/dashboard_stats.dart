import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/proxies/grouping.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

/// 仪表盘第二行：可用节点、覆盖地区、当前节点、节点测速。
class DashboardStats extends ConsumerWidget {
  const DashboardStats({super.key});

  static final _flagPattern = RegExp(
    r'[\u{1F1E6}-\u{1F1FF}]{2}',
    unicode: true,
  );

  static const _pseudoNames = {
    'DIRECT',
    'REJECT',
    'GLOBAL',
    'PASS',
    'COMPATIBLE',
  };

  Set<String> _collectNodeNames(List<Group> groups) {
    final groupNames = groups.map((group) => group.name).toSet();
    final names = <String>{};
    for (final group in groups) {
      for (final proxy in group.all) {
        final name = proxy.name;
        if (name.isEmpty || groupNames.contains(name)) {
          continue;
        }
        if (_pseudoNames.contains(name.toUpperCase())) {
          continue;
        }
        names.add(name);
      }
    }
    return names;
  }

  Set<String> _collectCountries(Set<String> nodeNames) {
    final countries = <String>{};
    for (final name in nodeNames) {
      final region = regionOfProxyName(name);
      if (region != null) {
        countries.add(region.id);
        continue;
      }
      final match = _flagPattern.firstMatch(name);
      if (match != null) {
        countries.add(match.group(0)!);
      }
    }
    return countries;
  }

  void _runSpeedTest(
    BuildContext context,
    WidgetRef ref, {
    required bool available,
    required String groupName,
    required String proxyName,
  }) {
    final l10n = context.appLocalizations;
    if (!available) {
      globalState.showNotifier(l10n.speedTestInactive);
      return;
    }
    if (proxyName.isEmpty || isReservedProxyName(proxyName)) {
      globalState.showNotifier(l10n.nodeQualityPickNode);
      return;
    }
    ref
        .read(speedTestProvider.notifier)
        .run(
          target: SpeedTestTarget(groupName: groupName, proxyName: proxyName),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final groups = ref.watch(groupsProvider);
    final selectedMap = ref.watch(selectedMapProvider);
    final preferredGroup = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final nodeNames = _collectNodeNames(groups);
    final countries = _collectCountries(nodeNames);
    final group = computeCurrentGroup(
      groups,
      preferredName: preferredGroup,
      selectedMap: selectedMap,
    );
    final proxyName = group == null
        ? ''
        : computeRealSelectedProxyState(
            group.now ?? '',
            groups: groups,
            selectedMap: selectedMap,
          ).proxyName;
    final delay = ref.watch(delayProvider(proxyName: proxyName));
    final nodeCaption = [
      if (group != null && group.name.isNotEmpty) group.name,
      if (delay != null) '$delay ms',
    ].join(' · ');
    final speedTest = ref.watch(speedTestProvider);
    final speedAvailable = ref.watch(speedTestAvailableProvider);
    final speedRunning = speedTest.phase == SpeedTestPhase.running;
    final speedResult = speedTest.result;
    final speedMatchesNode =
        speedTest.target?.proxyName == proxyName &&
        (speedResult == null || speedResult.proxyName == proxyName);
    final speedFailed =
        speedTest.phase == SpeedTestPhase.failed && speedMatchesNode;
    final speedMeasured =
        speedMatchesNode && speedResult?.hasMeasurement == true
        ? speedResult
        : null;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: QuanXIcons.waypoints,
            color: DashboardPalette.primary,
            label: appLocalizations.dashboardAvailableNodes,
            value: '${nodeNames.length}',
            caption: '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: QuanXIcons.globe,
            color: DashboardPalette.blue,
            label: appLocalizations.dashboardCoverage,
            value: countries.isEmpty ? '—' : '${countries.length}',
            caption: '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: QuanXIcons.router,
            color: DashboardPalette.green,
            label: appLocalizations.dashboardCurrentNode,
            value: proxyName.isEmpty ? '—' : proxyName,
            valueWidget: proxyName.isEmpty
                ? null
                : EmojiText(
                    proxyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
            caption: nodeCaption,
            onPressed: () {
              ref
                  .read(currentPageLabelProvider.notifier)
                  .toPage(PageLabel.proxies);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: QuanXIcons.gauge,
            color: DashboardPalette.orange,
            label: appLocalizations.dashboardNodeSpeed,
            value: '—',
            valueWidget: speedMeasured == null
                ? null
                : _SpeedValue(download: speedMeasured.downloadMbps),
            caption: speedRunning
                ? appLocalizations.speedTestRunning
                : speedFailed
                ? appLocalizations.speedTestFailed
                : speedMeasured == null
                ? appLocalizations.speedTestTapToRun
                : _speedCaption(speedMeasured),
            captionColor: speedFailed ? context.quanX.danger : null,
            trailing: speedRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : speedMeasured != null
                ? Icon(
                    QuanXIcons.refreshCw,
                    size: 14,
                    color: context.quanX.textTertiary,
                  )
                : null,
            onPressed: () {
              _runSpeedTest(
                context,
                ref,
                available: speedAvailable,
                groupName: group?.name ?? '',
                proxyName: proxyName,
              );
            },
          ),
        ),
      ],
    );
  }

  String _speedCaption(SpeedTestResult result) {
    final parts = [
      if (result.uploadMbps != null) '↑ ${_formatMbps(result.uploadMbps)} Mbps',
      if (result.latencyMs != null) '${result.latencyMs} ms',
    ];
    return parts.isEmpty ? '' : parts.join(' · ');
  }
}

String _formatMbps(double? value) {
  if (value == null) {
    return '—';
  }
  if (value >= 100) {
    return value.toStringAsFixed(0);
  }
  if (value >= 10) {
    return value.toStringAsFixed(1);
  }
  return value.toStringAsFixed(2);
}

/// 测速结果的大号数字,单位用小字跟在后面。
class _SpeedValue extends StatelessWidget {
  const _SpeedValue({required this.download});

  final double? download;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            '↓ ${_formatMbps(download)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.headlineSmall?.copyWith(
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 2),
          child: Text(
            'Mbps',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.quanX.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Widget? valueWidget;
  final String caption;
  final Color? captionColor;
  final Widget? trailing;
  final VoidCallback? onPressed;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.valueWidget,
    required this.caption,
    this.captionColor,
    this.trailing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124.ap,
      child: DashboardCard(
        padding: EdgeInsets.all(14.ap),
        onPressed: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DashboardIconTile(icon: icon, color: color, size: 36),
                const Spacer(),
                trailing ?? DashboardMiniBars(color: color, height: 20),
              ],
            ),
            const Spacer(),
            valueWidget ??
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: context.quanX.textSecondary,
              ),
            ),
            if (caption.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: captionColor ?? context.quanX.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
