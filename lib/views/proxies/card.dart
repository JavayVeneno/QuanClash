import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/dashboard/widgets/dashboard_style.dart';
import 'package:quanclash/views/proxies/common.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void openNodeQualityDialog(
  BuildContext context,
  WidgetRef ref,
  String proxyName,
) {
  final name = ref.read(realSelectedProxyStateProvider(proxyName)).proxyName;
  showDialog<void>(
    context: context,
    builder: (_) => NodeQualityDialog(proxyName: name),
  );
}

Future<void> changeProxyForNode(
  WidgetRef ref,
  String groupName,
  Proxy proxy,
  GroupType groupType,
) async {
  final isComputedSelected = groupType.isComputedSelected;
  final isSelector = groupType == GroupType.Selector;
  final container = globalState.container;
  if (isComputedSelected || isSelector) {
    final currentProxyName = container.read(proxyNameProvider(groupName));
    final nextProxyName = switch (isComputedSelected) {
      true => currentProxyName == proxy.name ? '' : proxy.name,
      false => proxy.name,
    };
    if (nextProxyName.isNotEmpty) {
      ref.read(nodeUsageProvider.notifier).record(proxy.name);
    }
    container
        .read(profilesActionProvider.notifier)
        .updateCurrentSelectedMap(groupName, nextProxyName);
    container
        .read(proxiesActionProvider.notifier)
        .changeProxyDebounce(groupName, nextProxyName);
    return;
  }
  globalState.showNotifier(currentAppLocalizations.notSelectedTip);
}

/// 代理节点卡片。
///
/// 视觉与仪表盘统一：白底圆角卡片 + 靛蓝选中态；延迟、风险指数和节点质量
/// 入口都收在卡片底部一行，尽量不增加卡片高度。
class ProxyCard extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final ProxyCardType type;
  final String? testUrl;

  const ProxyCard({
    super.key,
    required this.groupName,
    required this.testUrl,
    required this.proxy,
    required this.groupType,
    required this.type,
  });

  Measure get measure => globalState.measure;

  void _handleTestCurrentDelay() {
    proxyDelayTest(proxy, testUrl);
  }

  Widget _buildDelayText() {
    return SizedBox(
      height: measure.labelSmallHeight,
      child: Consumer(
        builder: (context, ref, _) {
          final delay = ref.watch(
            delayProvider(proxyName: proxy.name, testUrl: testUrl),
          );
          return FadeThroughBox(
            alignment: Alignment.centerRight,
            child: delay == 0 || delay == null
                ? SizedBox(
                    height: measure.labelSmallHeight,
                    width: measure.labelSmallHeight,
                    child: delay == 0
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : IconButton(
                            icon: const Icon(QuanXIcons.zap),
                            iconSize: globalState.measure.labelSmallHeight,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints.tightFor(
                              width: measure.labelSmallHeight,
                              height: measure.labelSmallHeight,
                            ),
                            onPressed: _handleTestCurrentDelay,
                          ),
                  )
                : GestureDetector(
                    onTap: _handleTestCurrentDelay,
                    child: Text(
                      delay > 0 ? '$delay ms' : 'Timeout',
                      style: context.textTheme.labelSmall?.copyWith(
                        overflow: TextOverflow.ellipsis,
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w600,
                        color: utils.getDelayColor(delay),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildProxyNameText(BuildContext context) {
    final maxLines = type == ProxyCardType.min ? 1 : 2;
    return EmojiText(
      proxy.name,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: context.quanX.textPrimary,
      ),
    );
  }

  void _openNodeQuality(BuildContext context, WidgetRef ref) {
    openNodeQualityDialog(context, ref, proxy.name);
  }

  Widget _buildQualityEntry(BuildContext context, WidgetRef ref) {
    return ProxyQualityButton(
      proxyName: proxy.name,
      size: measure.labelSmallHeight - 1,
    );
  }

  Future<void> _changeProxy(WidgetRef ref) async {
    await changeProxyForNode(ref, groupName, proxy, groupType);
  }

  Widget _buildRiskBadge(BuildContext context, WidgetRef ref) {
    return ProxyRiskBadge(
      proxyName: proxy.name,
      onPressed: () {
        _openNodeQuality(context, ref);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final selectedProxyName = ref.watch(selectedProxyNameProvider(groupName));
    final manualProxyName = ref.watch(proxyNameProvider(groupName));
    final selected = selectedProxyName == proxy.name;
    final showMark = groupType.isComputedSelected
        ? manualProxyName == proxy.name
        : selected;
    final radius = BorderRadius.circular(14);
    final borderColor = selected
        ? DashboardPalette.primary.withValues(alpha: 0.55)
        : isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final background = selected
        ? Color.alphaBlend(
            DashboardPalette.primary.withValues(alpha: 0.06),
            DashboardPalette.surface(context),
          )
        : DashboardPalette.surface(context);
    final delayText = _buildDelayText();
    final qualityEntry = _buildQualityEntry(context, ref);
    final riskBadge = _buildRiskBadge(context, ref);
    final showType = type != ProxyCardType.expand;
    final bottomRow = Row(
      children: [
        if (showType)
          Expanded(
            child: Text(
              proxy.type,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: quanX.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          const Spacer(),
        riskBadge,
        qualityEntry,
        const SizedBox(width: 2),
        delayText,
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: background,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            _changeProxy(ref);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildProxyNameText(context)),
                        if (showMark) const _SelectedMark(),
                      ],
                    ),
                    if (type == ProxyCardType.expand) ...[
                      const SizedBox(height: 3),
                      SizedBox(
                        height: measure.bodySmallHeight,
                        child: _ProxyDesc(proxy: proxy),
                      ),
                    ],
                  ],
                ),
                SizedBox(
                  height: measure.labelSmallHeight + 2,
                  child: bottomRow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6, top: 1),
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        color: DashboardPalette.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 10, color: Colors.white),
    );
  }
}

class _ProxyDesc extends ConsumerWidget {
  final Proxy proxy;

  const _ProxyDesc({required this.proxy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desc = ref.watch(proxyDescProvider(proxy));
    return EmojiText(
      desc,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.quanX.textTertiary,
      ),
    );
  }
}

/// 列表模式下的紧凑节点行。
class ProxyRow extends ConsumerWidget {
  final String groupName;
  final Proxy proxy;
  final GroupType groupType;
  final String? testUrl;

  const ProxyRow({
    super.key,
    required this.groupName,
    required this.proxy,
    required this.groupType,
    required this.testUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final selectedProxyName = ref.watch(selectedProxyNameProvider(groupName));
    final manualProxyName = ref.watch(proxyNameProvider(groupName));
    final selected = selectedProxyName == proxy.name;
    final showMark = groupType.isComputedSelected
        ? manualProxyName == proxy.name
        : selected;
    final radius = BorderRadius.circular(10);
    final background = selected
        ? Color.alphaBlend(
            DashboardPalette.primary.withValues(alpha: 0.06),
            DashboardPalette.surface(context),
          )
        : DashboardPalette.surface(context);
    final borderColor = selected
        ? DashboardPalette.primary.withValues(alpha: 0.55)
        : isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: () {
          changeProxyForNode(ref, groupName, proxy, groupType);
        },
        borderRadius: radius,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (showMark) ...[
                const Icon(
                  QuanXIcons.check,
                  size: 14,
                  color: DashboardPalette.primary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: EmojiText(
                  proxy.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: quanX.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                proxy.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              ProxyRiskBadge(proxyName: proxy.name),
              ProxyQualityButton(proxyName: proxy.name, size: 15),
              const SizedBox(width: 2),
              _ProxyRowDelay(proxy: proxy, testUrl: testUrl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProxyRowDelay extends ConsumerWidget {
  final Proxy proxy;
  final String? testUrl;

  const _ProxyRowDelay({required this.proxy, required this.testUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: testUrl),
    );
    return SizedBox(
      width: 52,
      height: 20,
      child: FadeThroughBox(
        alignment: Alignment.centerRight,
        child: delay == 0 || delay == null
            ? SizedBox(
                width: 20,
                height: 20,
                child: delay == 0
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : IconButton(
                        icon: const Icon(QuanXIcons.zap),
                        iconSize: 15,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 20,
                          height: 20,
                        ),
                        onPressed: () {
                          proxyDelayTest(proxy, testUrl);
                        },
                      ),
              )
            : GestureDetector(
                onTap: () {
                  proxyDelayTest(proxy, testUrl);
                },
                child: Text(
                  delay > 0 ? '$delay ms' : 'Timeout',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: utils.getDelayColor(delay),
                  ),
                ),
              ),
      ),
    );
  }
}

/// 节点风险指数徽标，卡片和列表行共用。
class ProxyRiskBadge extends ConsumerWidget {
  final String proxyName;
  final VoidCallback? onPressed;

  const ProxyRiskBadge({
    super.key,
    required this.proxyName,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      nodeQualityResultsProvider.select((state) => state[proxyName]),
    );
    final score = result?.quality.riskScore;
    if (result == null || score == null || !isNodeQualityFresh(result)) {
      return const SizedBox.shrink();
    }
    final color = nodeRiskColor(score);
    return Tooltip(
      message:
          '${context.appLocalizations.nodeQualityRiskScore} · $score / 100',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(QuanXIcons.shield, size: 10, color: color),
              const SizedBox(width: 2),
              Text(
                '$score/100',
                style: TextStyle(
                  fontSize: 9.5,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 节点质量检测入口，卡片和列表行共用。
class ProxyQualityButton extends ConsumerWidget {
  final String proxyName;
  final double size;

  const ProxyQualityButton({
    super.key,
    required this.proxyName,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: context.appLocalizations.nodeQualityTitle,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size + 4, height: size + 2),
        iconSize: size,
        onPressed: () {
          openNodeQualityDialog(context, ref, proxyName);
        },
        icon: const Icon(QuanXIcons.shield),
      ),
    );
  }
}
