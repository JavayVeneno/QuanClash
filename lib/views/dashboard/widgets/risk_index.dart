import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

/// 仪表盘「风险指数」卡片。
///
/// 展示最近一次经用户主动发起的节点质量检测结果（IPPure 风险分）。
/// 结果仅保存在内存中，超过 10 分钟或节点已切换时视为未检测。
class RiskIndex extends ConsumerWidget {
  const RiskIndex({super.key});

  void _openDialog(BuildContext context, String proxyName) {
    if (proxyName.isEmpty) {
      globalState.showNotifier(context.appLocalizations.nodeQualityPickNode);
      return;
    }
    // Opening the risk card is an explicit request for a risk score: preselect
    // IPPure and start immediately instead of leaving the user with a
    // Cloudflare-only result and no score.
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(
        proxyName: proxyName,
        includeIpPureByDefault: true,
        autoRun: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final preferredGroup = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final selectedMap = ref.watch(selectedMapProvider);
    // Probe the node rule mode actually uses, not mihomo's GLOBAL/DIRECT
    // selector; the risk score is meaningless when measured from the local IP.
    final group = ref.watch(
      groupsProvider.select(
        (groups) => computeCurrentGroup(
          groups,
          preferredName: preferredGroup,
          selectedMap: selectedMap,
        ),
      ),
    );
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
    // A completed probe that returned no usable score is "no score", not
    // "not checked"; otherwise a failed IPPure request silently looked idle.
    final checked = fresh;
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
      return appLocalizations.riskIndexTapToCheck;
    }
    final quality = result.quality;
    final ip = quality.egressIp ?? appLocalizations.unknown;
    return 'IPPure · $ip · ${result.sampledAt.toLocal().showTime.trim()}';
  }
}
