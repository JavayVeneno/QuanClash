import 'dart:math' as math;

import 'package:quanclash/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'globe_painter.dart';
import 'theme.dart';

/// Interactive pseudo-3D dot-matrix globe used by the v4 single-surface
/// dashboard.
///
/// - tap        -> cycle proxy mode
/// - drag up    -> connect
/// - drag down  -> disconnect
class MobileV4Globe extends StatefulWidget {
  const MobileV4Globe({
    super.key,
    required this.connected,
    required this.onTap,
    required this.onConnectChanged,
  });

  final bool connected;
  final VoidCallback onTap;
  final ValueChanged<bool> onConnectChanged;

  @override
  State<MobileV4Globe> createState() => _MobileV4GlobeState();
}

class _MobileV4GlobeState extends State<MobileV4Globe>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 80),
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _aura = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  double _dragDy = 0;

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _aura.dispose();
    super.dispose();
  }

  void _endDrag() {
    final dy = _dragDy;
    setState(() => _dragDy = 0);
    if (dy < -60) {
      HapticFeedback.mediumImpact();
      widget.onConnectChanged(true);
    } else if (dy > 60) {
      HapticFeedback.mediumImpact();
      widget.onConnectChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final dragging = _dragDy.abs() > 12;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onVerticalDragUpdate: (d) => setState(() => _dragDy += d.delta.dy),
      onVerticalDragEnd: (_) => _endDrag(),
      onVerticalDragCancel: () => setState(() => _dragDy = 0),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _aura,
                builder: (context, _) {
                  final wave = 0.5 - 0.5 * math.cos(_aura.value * math.pi * 2);
                  final auraOpacity = widget.connected
                      ? 0.55 + 0.45 * wave
                      : (p.isDark ? 0.12 : 0.08);
                  final auraScale = widget.connected
                      ? 0.93 + 0.12 * wave
                      : 0.95;
                  return AnimatedOpacity(
                    opacity: auraOpacity,
                    duration: const Duration(milliseconds: 420),
                    child: Center(
                      child: Transform.scale(
                        scale: auraScale,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final diameter =
                                math.min(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ) *
                                0.98;
                            return SizedBox(
                              width: diameter,
                              height: diameter,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: p.isDark
                                        ? const [
                                            Color(0x339678FF),
                                            Color(0x0D9678FF),
                                            Colors.transparent,
                                          ]
                                        : const [
                                            Color(0x2E6C5CE7),
                                            Color(0x0D7B61FF),
                                            Colors.transparent,
                                          ],
                                    stops: const [0.0, 0.54, 0.72],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_spin, _pulse]),
              builder: (context, _) {
                return AnimatedOpacity(
                  opacity: widget.connected ? 1 : (p.isDark ? .32 : .42),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOut,
                  child: Transform.translate(
                    offset: Offset(0, _dragDy * .1),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: MobileV4GlobePainter(
                          rotation: _spin.value * math.pi * 2,
                          pulse: _pulse.value,
                          connected: widget.connected,
                          isDark: p.isDark,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: dragging ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _dragDy < 0 ? QuanXIcons.arrowUp : QuanXIcons.arrowDown,
                      size: 12,
                      color: p.accent,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      _dragDy < 0 ? '松手连接' : '松手断开',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: p.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.connected && !dragging)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '上滑连接',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.6,
                      color: p.faint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
