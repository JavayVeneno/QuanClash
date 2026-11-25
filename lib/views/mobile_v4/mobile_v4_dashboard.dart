import 'dart:async';
import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/common.dart' as common_models;
import 'package:quanclash/models/models.dart' show ProfileExtension;
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/mobile_v4/network_globe.dart';
import 'package:quanclash/views/mobile_v4/radial_fab.dart';
import 'package:quanclash/views/mobile_v4/sheets.dart';
import 'package:quanclash/views/mobile_v4/theme.dart';
import 'package:quanclash/views/mobile_v4/utils.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile v4 single-surface dashboard supporting Dark, Light, and System themes.
///
/// Desktop never builds this widget: [HomePage] and [DashboardView] keep their
/// desktop implementations completely unchanged and only route mobile platforms
/// to this surface.
class MobileV4Dashboard extends ConsumerStatefulWidget {
  const MobileV4Dashboard({super.key});

  @override
  ConsumerState<MobileV4Dashboard> createState() => _MobileV4DashboardState();
}

class _MobileV4DashboardState extends ConsumerState<MobileV4Dashboard> {
  String? _toast;
  Timer? _toastTimer;
  bool _menuOpen = false;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _toast = null);
      }
    });
  }

  void _setMode(Mode next) {
    ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(mode: next));
    HapticFeedback.selectionClick();
    _showToast(mobileV4ModeLabel(next));
  }

  Future<void> _setConnected(bool on, String nodeName) async {
    final hasProfile = ref.read(profilesProvider).isNotEmpty;
    if (!hasProfile) {
      _showToast('请先添加订阅配置');
      return;
    }
    await ref
        .read(setupActionProvider.notifier)
        .updateStatus(on, isInit: !ref.read(initProvider));
    if (!mounted) {
      return;
    }
    if (on) {
      _showToast(nodeName.isNotEmpty ? '已连接 · $nodeName' : '已连接');
    } else {
      _showToast('已断开');
    }
  }

  void _openRiskCheck(String proxyName) {
    if (proxyName.isEmpty) {
      _showToast('请先选择代理节点');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(
        proxyName: proxyName,
        includeRiskByDefault: true,
        autoRun: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final isStart = ref.watch(isStartProvider);
    final mode = ref.watch(patchClashConfigProvider.select((s) => s.mode));
    final activeProfileLabel = ref.watch(
      currentProfileProvider.select((state) => state?.realLabel),
    );
    final preferredGroup = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final selectedMap = ref.watch(selectedMapProvider);
    final group = ref.watch(
      groupsProvider.select(
        (groups) => computeCurrentGroup(
          groups,
          preferredName: preferredGroup,
          selectedMap: selectedMap,
        ),
      ),
    );
    final rawSelected = group == null
        ? ''
        : (selectedMap[group.name]?.isNotEmpty == true
              ? selectedMap[group.name]!
              : group.realNow);
    final resolvedProxy = rawSelected.isEmpty
        ? ''
        : ref.watch(realSelectedProxyStateProvider(rawSelected)).proxyName;
    final activeNode = resolvedProxy.isNotEmpty ? resolvedProxy : rawSelected;
    final groupTag = (group != null &&
            activeNode.isNotEmpty &&
            group.name != activeNode)
        ? group.name
        : null;

    final qualityResult = activeNode.isEmpty
        ? null
        : ref.watch(
            nodeQualityResultsProvider.select((state) => state[activeNode]),
          );
    final qualityFresh =
        qualityResult != null && isNodeQualityFresh(qualityResult);
    final riskScore =
        qualityFresh && qualityResult.quality.status == NodeQualityStatus.ok
        ? qualityResult.quality.riskScore
        : null;

    final traffic = ref.watch(
      trafficsProvider.select(
        (state) => state.list.isEmpty
            ? const common_models.Traffic()
            : state.list.last,
      ),
    );

    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        decoration: p.bgGradient == null
            ? BoxDecoration(color: p.bg)
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: p.bgGradient!,
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(connected: isStart, palette: p),
                  Expanded(
                    child: MobileV4Globe(
                      connected: isStart,
                      activeNodeName: activeNode,
                      onConnectChanged: (on) =>
                          unawaited(_setConnected(on, activeNode)),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _menuOpen ? 0.14 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: _InfoPanel(
                      palette: p,
                      mode: mobileV4ModeLabel(mode),
                      nodeName: activeNode.isNotEmpty ? activeNode : '未选择节点',
                      nodeSubTag: groupTag,
                      connected: isStart,
                      down: traffic.down,
                      up: traffic.up,
                      riskScore: riskScore,
                      onNodeTap: () => showMobileV4Sheet(context, 'proxy'),
                      onRiskTap: () => _openRiskCheck(activeNode),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: MobileV4RadialFab(
                mode: mode,
                onModeChanged: _setMode,
                onOpen: (type) => showMobileV4Sheet(context, type),
                activeNodeLabel: activeNode.isNotEmpty ? activeNode : null,
                activeProfileLabel: activeProfileLabel,
                onMenuOpenChanged: (open) {
                  if (_menuOpen != open) {
                    setState(() => _menuOpen = open);
                  }
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 34 + MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(child: _Toast(text: _toast, palette: p)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.connected, required this.palette});

  final bool connected;
  final MobileV4Palette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Row(
          children: [
            Text('QUANCLASH', style: palette.wordmark),
            const Spacer(),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: connected ? palette.signal : palette.faint,
                boxShadow: connected
                    ? [
                        BoxShadow(
                          color: palette.signal.withValues(alpha: .18),
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: palette.signal.withValues(alpha: .45),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              connected ? 'VPN 已连接' : 'VPN 未连接',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: .9,
                color: connected ? palette.text2 : palette.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.palette,
    required this.mode,
    required this.nodeName,
    required this.nodeSubTag,
    required this.connected,
    required this.down,
    required this.up,
    required this.riskScore,
    required this.onNodeTap,
    required this.onRiskTap,
  });

  final MobileV4Palette palette;
  final String mode;
  final String nodeName;
  final String? nodeSubTag;
  final bool connected;
  final num down;
  final num up;
  final int? riskScore;
  final VoidCallback onNodeTap;
  final VoidCallback onRiskTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onNodeTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(
                                    alpha: palette.isDark ? .8 : .45,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            mode,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: palette.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              nodeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: palette.nodeTitle,
                            ),
                          ),
                          if (nodeSubTag != null && nodeSubTag!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              nodeSubTag!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    QuanXIcons.chevronRight,
                    size: 18,
                    color: palette.faint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SpeedStat(
                  palette: palette,
                  down: connected ? down : 0,
                  up: connected ? up : 0,
                ),
              ),
              Container(width: 1, height: 54, color: palette.lineSoft),
              const SizedBox(width: 20),
              Expanded(
                child: _RiskStat(
                  palette: palette,
                  score: riskScore,
                  onTap: onRiskTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedStat extends StatelessWidget {
  const _SpeedStat({
    required this.palette,
    required this.down,
    required this.up,
  });

  final MobileV4Palette palette;
  final num down;
  final num up;

  @override
  Widget build(BuildContext context) {
    final downFormatted = mobileV4FormatSpeed(down);
    final upFormatted = mobileV4FormatSpeed(up);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('实时速度', style: palette.micro),
        const SizedBox(height: 11),
        _SpeedLine(
          arrow: QuanXIcons.arrowDown,
          arrowSize: 11,
          arrowColor: palette.muted,
          value: downFormatted.$1,
          unit: downFormatted.$2,
          color: palette.text,
          unitColor: palette.faint,
          fontSize: 25,
        ),
        const SizedBox(height: 5),
        _SpeedLine(
          arrow: QuanXIcons.arrowUp,
          arrowSize: 9.5,
          arrowColor: palette.faint,
          value: upFormatted.$1,
          unit: upFormatted.$2,
          color: palette.text2,
          unitColor: palette.faint,
          fontSize: 12,
        ),
      ],
    );
  }
}

class _SpeedLine extends StatelessWidget {
  const _SpeedLine({
    required this.arrow,
    required this.arrowSize,
    required this.arrowColor,
    required this.value,
    required this.unit,
    required this.color,
    required this.unitColor,
    required this.fontSize,
  });

  final IconData arrow;
  final double arrowSize;
  final Color arrowColor;
  final String value;
  final String unit;
  final Color color;
  final Color unitColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(arrow, size: arrowSize, color: arrowColor),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: fontSize > 16 ? -1 : -0.2,
            height: 1,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: TextStyle(
            fontSize: 8.5,
            letterSpacing: 0.3,
            color: unitColor,
          ),
        ),
      ],
    );
  }
}

class _RiskStat extends StatelessWidget {
  const _RiskStat({
    required this.palette,
    required this.score,
    required this.onTap,
  });

  final MobileV4Palette palette;
  final int? score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = score;
    final (String tag, Color tagColor) = s == null
        ? ('点击检测', palette.faint)
        : s <= 30
            ? ('低', palette.signal.withValues(alpha: .95))
            : s <= 60
                ? ('中', palette.warn)
                : ('高', palette.danger);
    final progress = s == null ? 0.0 : (s / 100.0).clamp(0.06, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('风险指数', style: palette.micro),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                s == null ? '—' : '$s',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                  height: 1,
                  color: palette.text,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: .9,
                  color: tagColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: palette.barTrack),
                  ),
                  if (progress > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(
                                  alpha: palette.isDark ? .55 : .38,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text, required this.palette});

  final String? text;
  final MobileV4Palette palette;

  @override
  Widget build(BuildContext context) {
    final visible = text != null;
    return Center(
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, .4),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.toastFill,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: palette.toastBorder),
                  boxShadow: [
                    BoxShadow(
                      color: palette.toastShadow,
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.accent,
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(
                              alpha: palette.isDark ? .9 : .5,
                            ),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      text ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .8,
                        color: palette.toastText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
