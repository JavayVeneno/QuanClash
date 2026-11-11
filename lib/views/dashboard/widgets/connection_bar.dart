import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dashboard_style.dart';

/// Desktop connection summary: status, session, selected node and throughput.
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

  String _tagline(AppLocalizations appLocalizations) {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) {
      return appLocalizations.overviewPhraseMorning;
    }
    if (hour >= 12 && hour < 18) {
      return appLocalizations.overviewPhraseAfternoon;
    }
    if (hour >= 18 && hour < 22) {
      return appLocalizations.overviewPhraseEvening;
    }
    return appLocalizations.overviewPhraseNight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    final isStart = ref.watch(isStartProvider);
    final coreStatus = ref.watch(coreStatusProvider);
    final runTime = ref.watch(runTimeProvider);
    final traffics = ref.watch(trafficsProvider).list;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
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
    return ConnectionHeroSurface(
      statusText: statusText,
      statusColor: statusColor,
      tagline: coreStatus == CoreStatus.connected
          ? _tagline(appLocalizations)
          : '',
      serviceRunning: appLocalizations.serviceRunning,
      connected: coreStatus == CoreStatus.connected,
      mode: Intl.message(mode.name),
      runTime: isStart ? utils.getTimeText(runTime) : '--:--:--',
      isStart: isStart,
      actionLabel: isStart ? appLocalizations.stop : appLocalizations.start,
      nodeName: group?.now ?? '',
      groupName: group?.name ?? '',
      delay: delay,
      upload: lastTraffic.up.traffic.show,
      download: lastTraffic.down.traffic.show,
      onToggle: () => _handleSwitchStart(ref),
    );
  }
}

/// Presentational surface so the layout can be verified without the core.
class ConnectionHeroSurface extends StatelessWidget {
  const ConnectionHeroSurface({
    super.key,
    required this.statusText,
    required this.statusColor,
    this.tagline = '',
    this.serviceRunning = 'Service running',
    required this.connected,
    required this.mode,
    required this.runTime,
    required this.isStart,
    required this.actionLabel,
    required this.nodeName,
    required this.groupName,
    required this.delay,
    required this.upload,
    required this.download,
    required this.onToggle,
  });

  final String statusText;
  final Color statusColor;
  final String tagline;
  final String serviceRunning;
  final bool connected;
  final String mode;
  final String runTime;
  final bool isStart;
  final String actionLabel;
  final String nodeName;
  final String groupName;
  final int? delay;
  final String upload;
  final String download;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    const primary = DashboardPalette.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final stacked = width < 720;
        return GlassPanel(
          radius: 20,
          blurSigma: 20,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.13),
              isDark
                  ? context.glass.tint
                  : Colors.white.withValues(alpha: 0.90),
              primary.withValues(alpha: 0.05),
            ],
            stops: const [0, 0.55, 1],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HeroGridPainter(
                      quanX.textTertiary.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: stacked ? _buildStacked(context) : _buildWide(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWide(BuildContext context) {
    final quanX = context.quanX;
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _StatusBlock(
              statusText: statusText,
              statusColor: statusColor,
              tagline: tagline,
              serviceRunning: serviceRunning,
              connected: connected,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            height: 88,
            child: CustomPaint(
              painter: _HeroNetworkPainter(
                color: DashboardPalette.primary,
                guideColor: quanX.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          _ActionButton(
            isStart: isStart,
            actionLabel: actionLabel,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildStacked(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusBlock(
            statusText: statusText,
            statusColor: statusColor,
            tagline: tagline,
            serviceRunning: serviceRunning,
            connected: connected,
          ),
        ),
        const SizedBox(width: 12),
        _ActionButton(
          isStart: isStart,
          actionLabel: actionLabel,
          onToggle: onToggle,
        ),
      ],
    );
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.statusText,
    required this.statusColor,
    required this.tagline,
    required this.serviceRunning,
    required this.connected,
  });

  final String statusText;
  final Color statusColor;
  final String tagline;
  final String serviceRunning;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final statusLine = connected ? '$serviceRunning · $statusText' : statusText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusOrb(color: statusColor, connected: connected),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (tagline.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: quanX.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusOrb extends StatelessWidget {
  const _StatusOrb({required this.color, required this.connected});

  final Color color;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (connected)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.18)),
              ),
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.isStart,
    required this.actionLabel,
    required this.onToggle,
  });

  final bool isStart;
  final String actionLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return FilledButton.icon(
      onPressed: onToggle,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: isStart ? quanX.accent : DashboardPalette.primary,
        foregroundColor: isStart ? quanX.onAccent : Colors.white,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(QuanXRadius.control)),
        ),
      ),
      icon: Icon(isStart ? QuanXIcons.pause : QuanXIcons.play, size: 17),
      label: Text(actionLabel),
    );
  }
}

class _HeroGridPainter extends CustomPainter {
  const _HeroGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 22.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeroGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 运行概览右侧的抽象网络拓扑装饰。
class _HeroNetworkPainter extends CustomPainter {
  const _HeroNetworkPainter({required this.color, required this.guideColor});

  final Color color;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.68, size.height * 0.5);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final factor in const [0.44, 0.32, 0.20]) {
      ringPaint.color = color.withValues(alpha: 0.14);
      canvas.drawCircle(center, size.height * factor, ringPaint);
    }
    final guidePaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final nodePaint = Paint()..color = color.withValues(alpha: 0.45);
    final nodes = [
      Offset(size.width * 0.24, size.height * 0.20),
      Offset(size.width * 0.92, size.height * 0.24),
      Offset(size.width * 0.86, size.height * 0.82),
      Offset(size.width * 0.14, size.height * 0.78),
    ];
    for (final node in nodes) {
      canvas.drawLine(center, node, guidePaint);
      canvas.drawCircle(node, 2.5, nodePaint);
    }
    canvas.drawCircle(
      center,
      8,
      Paint()..color = color.withValues(alpha: 0.12),
    );
    canvas.drawCircle(center, 4, nodePaint);
    final dotPaint = Paint()..color = guideColor.withValues(alpha: 0.18);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.10 + i * 0.15),
          size.height * (0.12 + (i % 3) * 0.30),
        ),
        1.2,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroNetworkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.guideColor != guideColor;
}
