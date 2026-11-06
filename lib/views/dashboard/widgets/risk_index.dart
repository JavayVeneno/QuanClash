import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/node_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

/// 仪表盘「风险指数」卡片。
///
/// 展示最近一次经用户主动发起的节点质量检测结果（IPPure 风险分）。
/// 结果仅保存在内存中，超过 10 分钟或节点已切换时视为未检测。
class RiskIndex extends ConsumerWidget {
  const RiskIndex({super.key});

  Group? _currentGroup(List<Group> groups) {
    for (final group in groups) {
      if (group.type == GroupType.Selector &&
          (group.now?.isNotEmpty ?? false)) {
        return group;
      }
    }
    return null;
  }

  void _openDialog(BuildContext context, String proxyName) {
    if (proxyName.isEmpty) {
      globalState.showNotifier(context.appLocalizations.nodeQualityPickNode);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(proxyName: proxyName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final group = ref.watch(groupsProvider.select(_currentGroup));
    final selected = group?.now ?? '';
    final proxyName = selected.isEmpty
        ? ''
        : ref.watch(realSelectedProxyStateProvider(selected)).proxyName;
    final result = proxyName.isEmpty
        ? null
        : ref.watch(
            nodeQualityResultsProvider.select((state) => state[proxyName]),
          );
    final fresh = result != null && isNodeQualityFresh(result);
    final quality = result?.quality;
    final score = fresh && quality?.status == NodeQualityStatus.ok
        ? quality?.riskScore
        : null;
    final checked = fresh && quality?.status == NodeQualityStatus.ok;
    final egressIp = fresh ? quality?.egressIp : null;
    final quanX = context.quanX;
    final color = score != null ? nodeRiskColor(score) : quanX.textTertiary;
    return SizedBox(
      height: 96.ap,
      child: DashboardCard(
        onPressed: () {
          _openDialog(context, proxyName);
        },
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.shield,
              color: DashboardPalette.green,
              title: appLocalizations.riskIndex,
            ),
            const Spacer(),
            Tooltip(
              message: _tooltip(appLocalizations, result, fresh),
              child: score != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$score',
                          style: context.textTheme.titleMedium?.copyWith(
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w700,
                            height: 1,
                            color: color,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: Text(
                            ' / 100',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: quanX.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      checked
                          ? appLocalizations.riskIndexNoScore
                          : appLocalizations.riskIndexNotChecked,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: quanX.textTertiary,
                      ),
                    ),
            ),
            if (egressIp != null) ...[
              const SizedBox(height: 2),
              Text(
                egressIp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _tooltip(
    AppLocalizations appLocalizations,
    NodeQualityResult? result,
    bool fresh,
  ) {
    if (!fresh || result == null) {
      return appLocalizations.riskIndexNotChecked;
    }
    final quality = result.quality;
    final ip = quality.egressIp ?? appLocalizations.unknown;
    return 'IPPure · $ip · ${result.sampledAt.toLocal().showTime.trim()}';
  }
}
