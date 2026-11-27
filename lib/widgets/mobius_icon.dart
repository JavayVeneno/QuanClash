import 'package:flutter/material.dart';

/// Vector Möbius strip (twisted infinity ribbon) icon for Proxy Chains.
///
/// Renders cleanly at any desktop DPI scale (100%–200%+) and inherits
/// [IconTheme] color and size when omitted.
class MobiusIcon extends StatelessWidget {
  const MobiusIcon({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  final double? size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size ?? 18.0;
    final resolvedColor =
        color ?? iconTheme.color ?? Theme.of(context).colorScheme.onSurface;
    final resolvedStroke = strokeWidth ?? (resolvedSize * 0.115).clamp(1.4, 3.0);

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: CustomPaint(
        painter: _MobiusPainter(
          color: resolvedColor,
          strokeWidth: resolvedStroke,
        ),
      ),
    );
  }
}

class _MobiusPainter extends CustomPainter {
  const _MobiusPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.5;
    final rx = w * 0.42;
    final ry = h * 0.27;

    final primaryPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final subtlePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Back-passing ribbon segment (bottom-left to top-right, with center gap
    // to convey the half-twist overlap of a Möbius strip).
    final backLeft = Path()
      ..moveTo(cx - rx * 0.14, cy + ry * 0.24)
      ..cubicTo(
        cx - rx * 0.55,
        cy + ry * 1.18,
        cx - rx * 1.05,
        cy + ry * 0.72,
        cx - rx,
        cy,
      )
      ..cubicTo(
        cx - rx * 1.05,
        cy - ry * 0.72,
        cx - rx * 0.48,
        cy - ry * 1.12,
        cx,
        cy,
      );

    final backRight = Path()
      ..moveTo(cx + rx * 0.14, cy - ry * 0.24)
      ..cubicTo(
        cx + rx * 0.55,
        cy - ry * 1.18,
        cx + rx * 1.05,
        cy - ry * 0.72,
        cx + rx,
        cy,
      )
      ..cubicTo(
        cx + rx * 1.05,
        cy + ry * 0.72,
        cx + rx * 0.48,
        cy + ry * 1.12,
        cx,
        cy,
      );

    // Continuous front-crossing strand (top-left -> center -> bottom-right).
    final frontCross = Path()
      ..moveTo(cx - rx * 0.28, cy - ry * 0.52)
      ..cubicTo(
        cx - rx * 0.08,
        cy - ry * 0.14,
        cx + rx * 0.08,
        cy + ry * 0.14,
        cx + rx * 0.28,
        cy + ry * 0.52,
      );

    canvas.drawPath(backLeft, subtlePaint);
    canvas.drawPath(backRight, subtlePaint);
    canvas.drawPath(frontCross, primaryPaint);

    // Emphasize outer ribbon edges for crispness at small sizes.
    final outerLeft = Path()
      ..moveTo(cx - rx * 0.62, cy - ry * 0.76)
      ..cubicTo(
        cx - rx * 1.04,
        cy - ry * 0.64,
        cx - rx * 1.04,
        cy + ry * 0.64,
        cx - rx * 0.62,
        cy + ry * 0.76,
      );
    final outerRight = Path()
      ..moveTo(cx + rx * 0.62, cy - ry * 0.76)
      ..cubicTo(
        cx + rx * 1.04,
        cy - ry * 0.64,
        cx + rx * 1.04,
        cy + ry * 0.64,
        cx + rx * 0.62,
        cy + ry * 0.76,
      );
    canvas.drawPath(outerLeft, primaryPaint);
    canvas.drawPath(outerRight, primaryPaint);
  }

  @override
  bool shouldRepaint(_MobiusPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
