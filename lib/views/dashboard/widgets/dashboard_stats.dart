import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/proxies/grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

/// 仪表盘第二行：可用节点、覆盖地区、节点更新、稳定运行。
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

  String _formatUpdate(DateTime? date) {
    if (date == null) {
      return '—';
    }
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final groups = ref.watch(groupsProvider);
    final profile = ref.watch(currentProfileProvider);
    final runTime = ref.watch(runTimeProvider);
    final isStart = ref.watch(isStartProvider);
    final nodeNames = _collectNodeNames(groups);
    final countries = _collectCountries(nodeNames);
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
            icon: QuanXIcons.clock,
            color: DashboardPalette.green,
            label: appLocalizations.dashboardNodeUpdate,
            value: _formatUpdate(profile?.lastUpdateDate),
            caption: profile?.label ?? '',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: QuanXIcons.chartLine,
            color: DashboardPalette.orange,
            label: appLocalizations.dashboardUptime,
            value: !isStart || runTime == null
                ? '—'
                : utils.getTimeText(runTime),
            caption: '',
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
  final String caption;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124.ap,
      child: DashboardCard(
        padding: EdgeInsets.all(14.ap),
        onPressed: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DashboardIconTile(icon: icon, color: color, size: 36),
                const Spacer(),
                DashboardMiniBars(color: color, height: 20),
              ],
            ),
            const Spacer(),
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
                  color: context.quanX.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
