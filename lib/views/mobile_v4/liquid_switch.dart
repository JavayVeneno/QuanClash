import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// iOS 26 Liquid Glass switch featuring an elongated pill thumb that blooms
/// into a crystal-clear, oversized transparent glass lens when pressed,
/// dragged, or toggled.
///
/// Used across Android Mobile v4 surfaces and Android-gated shared list items
/// without affecting Windows/Desktop switches.
class MobileV4LiquidSwitch extends StatefulWidget {
  const MobileV4LiquidSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<MobileV4LiquidSwitch> createState() => _MobileV4LiquidSwitchState();
}

class _MobileV4LiquidSwitchState extends State<MobileV4LiquidSwitch>
    with TickerProviderStateMixin {
  static const double _trackWidth = 54;
  static const double _trackHeight = 28;
  static const double _thumbRestWidth = 32;
  static const double _thumbRestHeight = 22;
  static const double _thumbLensWidth = 42;
  static const double _thumbLensHeight = 32;
  static const double _trackPadding = 3;

  late final AnimationController _posController = AnimationController(
    vsync: this,
    value: widget.value ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 220),
  );

  late final AnimationController _lensController = AnimationController(
    vsync: this,
    value: 0.0,
    duration: const Duration(milliseconds: 170),
    reverseDuration: const Duration(milliseconds: 220),
  );

  bool _dragging = false;
  bool _crossedHalf = false;

  bool get _enabled => widget.onChanged != null;

  @override
  void didUpdateWidget(covariant MobileV4LiquidSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_dragging) {
      _posController.animateTo(
        widget.value ? 1.0 : 0.0,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _posController.dispose();
    _lensController.dispose();
    super.dispose();
  }

  void _triggerTapToggle() {
    if (!_enabled) {
      return;
    }
    HapticFeedback.selectionClick();
    // Brief liquid-glass bloom pulse on tap so even quick clicks show the
    // transparent glass lens transition.
    _lensController.forward().then((_) {
      if (mounted && !_dragging) {
        _lensController.reverse();
      }
    });
    widget.onChanged!(!widget.value);
  }

  void _handleDragStart(DragStartDetails _) {
    if (!_enabled) {
      return;
    }
    _dragging = true;
    _crossedHalf = _posController.value >= 0.5;
    _lensController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_enabled || !_dragging) {
      return;
    }
    const travel = _trackWidth - _thumbRestWidth - _trackPadding * 2;
    final next = (_posController.value + details.delta.dx / travel).clamp(
      0.0,
      1.0,
    );
    _posController.value = next;
    final overHalf = next >= 0.5;
    if (overHalf != _crossedHalf) {
      _crossedHalf = overHalf;
      HapticFeedback.selectionClick();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_enabled || !_dragging) {
      return;
    }
    _dragging = false;
    _lensController.reverse();
    final vx = details.primaryVelocity ?? 0;
    final nextValue = vx.abs() > 120 ? vx > 0 : _posController.value >= 0.5;
    _posController.animateTo(
      nextValue ? 1.0 : 0.0,
      curve: Curves.easeOutCubic,
    );
    if (nextValue != widget.value) {
      widget.onChanged!(nextValue);
    }
  }

  void _handleDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _lensController.reverse();
    _posController.animateTo(
      widget.value ? 1.0 : 0.0,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final onTrackColor = p.isDark
        ? const Color(0xFF8C73FF)
        : const Color(0xFF6C5CE7);
    final offTrackColor = p.isDark
        ? const Color(0x2BFFFFFF)
        : const Color(0xFFDAD9E5);

    return Opacity(
      opacity: _enabled ? 1.0 : 0.45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _lensController.forward() : null,
        onTapCancel: _enabled
            ? () {
                if (!_dragging) {
                  _lensController.reverse();
                }
              }
            : null,
        onTap: _triggerTapToggle,
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onHorizontalDragCancel: _handleDragCancel,
        child: SizedBox(
          width: _trackWidth + 8,
          height: _thumbLensHeight + 4,
          child: AnimatedBuilder(
            animation: Listenable.merge([_posController, _lensController]),
            builder: (context, _) {
              final pos = _posController.value;
              final lens = Curves.easeOutCubic.transform(_lensController.value);
              final trackColor = Color.lerp(offTrackColor, onTrackColor, pos)!;

              final thumbW = ui.lerpDouble(
                _thumbRestWidth,
                _thumbLensWidth,
                lens,
              )!;
              final thumbH = ui.lerpDouble(
                _thumbRestHeight,
                _thumbLensHeight,
                lens,
              )!;

              const minCenterX =
                  4.0 + _trackPadding + _thumbRestWidth / 2;
              const maxCenterX =
                  4.0 + _trackWidth - _trackPadding - _thumbRestWidth / 2;
              final centerX = ui.lerpDouble(minCenterX, maxCenterX, pos)!;
              const centerY = (_thumbLensHeight + 4) / 2;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track pill
                  Positioned(
                    left: 4,
                    top: centerY - _trackHeight / 2,
                    width: _trackWidth,
                    height: _trackHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(_trackHeight / 2),
                        border: Border.all(
                          color: p.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          width: 0.7,
                        ),
                      ),
                    ),
                  ),
                  // Liquid Glass thumb / transparent lens
                  Positioned(
                    left: centerX - thumbW / 2,
                    top: centerY - thumbH / 2,
                    width: thumbW,
                    height: thumbH,
                    child: _LiquidThumb(
                      lens: lens,
                      isDark: p.isDark,
                      width: thumbW,
                      height: thumbH,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiquidThumb extends StatelessWidget {
  const _LiquidThumb({
    required this.lens,
    required this.isDark,
    required this.width,
    required this.height,
  });

  final double lens;
  final bool isDark;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = height / 2;
    // Rest state: crisp opaque white pill (`alpha: 1.0`).
    // Active/dragging state (`lens -> 1`): crystal-clear transparent glass lens
    // (`alpha: 0.14`) so the colored track shines directly through the center!
    final centerAlpha = ui.lerpDouble(1.0, isDark ? 0.12 : 0.14, lens)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45 + 0.15 * lens)
                : const Color(0xFF181622)
                    .withValues(alpha: 0.18 + 0.06 * lens),
            blurRadius: ui.lerpDouble(5, 14, lens)!,
            offset: Offset(0, ui.lerpDouble(1.5, 4, lens)!),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 1.4 * lens,
            sigmaY: 1.4 * lens,
          ),
          child: CustomPaint(
            size: Size(width, height),
            painter: _LiquidLensPainter(
              lens: lens,
              centerAlpha: centerAlpha,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiquidLensPainter extends CustomPainter {
  const _LiquidLensPainter({
    required this.lens,
    required this.centerAlpha,
    required this.isDark,
  });

  final double lens;
  final double centerAlpha;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.height / 2),
    );

    // Base pill fill: solid white at rest, transparent optical glass when pressed.
    final baseColor = isDark ? const Color(0xFFF6F6FA) : Colors.white;
    canvas.drawRRect(
      rrect,
      Paint()..color = baseColor.withValues(alpha: centerAlpha),
    );

    if (lens > 0.02) {
      // Soft radial edge frost inside the lens rim to mimic curved glass thickness.
      final edgeFrost = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2 * lens
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [
            Colors.white.withValues(alpha: (isDark ? 0.52 : 0.72) * lens),
            Colors.white.withValues(alpha: (isDark ? 0.14 : 0.22) * lens),
            Colors.white.withValues(alpha: (isDark ? 0.42 : 0.65) * lens),
          ],
          const [0.0, 0.5, 1.0],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
      canvas.drawRRect(rrect.deflate(1.6), edgeFrost);

      // Crisp specular glass rim border (top & bottom bright highlights).
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          Offset(0, size.height),
          [
            Colors.white.withValues(alpha: 0.96 * lens),
            Colors.white.withValues(alpha: 0.35 * lens),
            Colors.white.withValues(alpha: 0.88 * lens),
          ],
          const [0.0, 0.48, 1.0],
        );
      canvas.drawRRect(rrect.deflate(0.8), rimPaint);

      // Subtle top inner glass specular highlight bar.
      final highlightRect = Rect.fromLTWH(
        size.height * 0.35,
        2.4,
        size.width - size.height * 0.7,
        2.2,
      );
      if (highlightRect.width > 4) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(highlightRect, const Radius.circular(2)),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55 * lens)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidLensPainter oldDelegate) =>
      oldDelegate.lens != lens ||
      oldDelegate.centerAlpha != centerAlpha ||
      oldDelegate.isDark != isDark;
}
