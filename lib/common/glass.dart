import 'dart:ui' as ui;

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

/// 玻璃材质令牌与基础组件。
///
/// 与 FlClash 原始的「平面灰卡 + 1px 描边」不同,这里是一套**自绘毛玻璃**体系:
/// 应用底部铺一层氛围背景(渐变 + 色斑),其上用半透明层叠 + 背景模糊 +
/// 高光描边 + 柔和阴影构成玻璃卡片与玻璃浮层。
///
/// 全部由 Flutter 绘制,不依赖任何原生能力,因此不影响代理逻辑与平台编译。
@immutable
class GlassColors {
  const GlassColors({
    required this.backdropTop,
    required this.backdropBottom,
    required this.blobs,
    required this.blobOpacity,
    required this.tint,
    required this.tintStrong,
    required this.stroke,
    required this.highlight,
    required this.shadow,
    required this.divider,
  });

  /// 氛围背景的渐变起止色。
  final Color backdropTop;
  final Color backdropBottom;

  /// 氛围色斑(自绘柔光,不参与业务语义)。
  final List<Color> blobs;
  final double blobOpacity;

  /// 玻璃填充色。`tintStrong` 用于顶部高光方向。
  final Color tint;
  final Color tintStrong;

  /// 玻璃描边与顶部高光。
  final Color stroke;
  final Color highlight;

  /// 玻璃阴影。
  final Color shadow;

  /// 玻璃界面里的分隔线(比原 QuanX 描边更淡)。
  final Color divider;

  /// 浅色玻璃:明亮通透,冷调氛围色斑。
  static const GlassColors light = GlassColors(
    backdropTop: Color(0xFFF7F8FC),
    backdropBottom: Color(0xFFE8EDF6),
    blobs: [
      Color(0xFF2ED3C0),
      Color(0xFF6FA8FF),
      Color(0xFFC08CFF),
      Color(0xFFFFC46B),
    ],
    blobOpacity: 0.30,
    tint: Color(0x73FFFFFF),
    tintStrong: Color(0xA6FFFFFF),
    stroke: Color(0xBFFFFFFF),
    highlight: Color(0x99FFFFFF),
    shadow: Color(0x14101828),
    divider: Color(0x33000000),
  );

  /// 深色玻璃:深色底 + 低透明度彩色柔光。
  static const GlassColors dark = GlassColors(
    backdropTop: Color(0xFF0D1220),
    backdropBottom: Color(0xFF090C14),
    blobs: [
      Color(0xFF2ED3C0),
      Color(0xFF3B7CFF),
      Color(0xFFA66BFF),
      Color(0xFFFF9F43),
    ],
    blobOpacity: 0.24,
    tint: Color(0x14FFFFFF),
    tintStrong: Color(0x24FFFFFF),
    stroke: Color(0x2EFFFFFF),
    highlight: Color(0x1FFFFFFF),
    shadow: Color(0x66000000),
    divider: Color(0x1AFFFFFF),
  );

  static GlassColors of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

/// 纯黑模式使用的「无氛围」令牌:保留玻璃层叠,但去掉彩色色斑。
class _PlainGlassColors {
  const _PlainGlassColors._();

  static GlassColors of(GlassColors base) {
    return GlassColors(
      backdropTop: Colors.black,
      backdropBottom: Colors.black,
      blobs: base.blobs,
      blobOpacity: 0,
      tint: base.tint,
      tintStrong: base.tintStrong,
      stroke: base.stroke,
      highlight: base.highlight,
      shadow: base.shadow,
      divider: base.divider,
    );
  }
}

/// 玻璃材质的形状令牌。
class GlassRadius {
  /// 玻璃卡片。
  static const double panel = 20;

  /// 玻璃浮层 / 工具条。
  static const double bar = 16;

  /// 玻璃控件(按钮、输入框)。
  static const double control = 12;

  /// 玻璃标签。
  static const double chip = 9;

  const GlassRadius._();
}

extension GlassContextExtension on BuildContext {
  /// 当前主题对应的玻璃令牌。
  GlassColors get glass {
    final theme = Theme.of(this);
    final base = GlassColors.of(theme.colorScheme.brightness);
    return glassPlain ? _PlainGlassColors.of(base) : base;
  }

  /// 纯黑模式(由主题作用域注入,默认关闭)。
  bool get glassPlain => GlassScope.of(this)?.plain ?? false;
}

/// 让纯黑模式能关闭氛围色斑,同时不影响其他玻璃表现。
class GlassScope extends InheritedWidget {
  const GlassScope({super.key, required this.plain, required super.child});

  final bool plain;

  static GlassScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassScope>();
  }

  @override
  bool updateShouldNotify(GlassScope oldWidget) => plain != oldWidget.plain;
}

/// 应用氛围背景:底部渐变 + 若干柔光色斑。
///
/// 它铺在整棵界面树的最底层,玻璃层叠通过 [BackdropFilter] 对它取景,
/// 从而得到毛玻璃观感。色斑会向主题色谐调,调整主题色时整体观感随动。
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.glass;
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: _AmbientPainter(colors, primary)),
        ),
        ?child,
      ],
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter(this.colors, this.primary);

  final GlassColors colors;
  final Color primary;

  /// 色斑位置(x, y, 半径系数),均为相对尺寸的比例。
  static const List<List<double>> _spots = [
    [-0.05, 0.02, 0.62],
    [0.66, -0.12, 0.55],
    [1.02, 0.52, 0.66],
    [0.28, 0.98, 0.60],
    [0.78, 1.08, 0.48],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.backdropTop, colors.backdropBottom],
        ).createShader(rect),
    );

    if (colors.blobOpacity <= 0) {
      return;
    }

    final baseRadius = ui.lerpDouble(size.width, size.height, 0.5) ?? size.width;
    final blobs = colors.blobs;
    for (var i = 0; i < blobs.length && i < _spots.length; i++) {
      final spot = _spots[i];
      final center = Offset(size.width * spot[0], size.height * spot[1]);
      final radius = baseRadius * spot[2];
      // 每颗色斑向主题色方向谐调一半,保证既有个性又随主题而动
      final harmonized = Color.lerp(blobs[i], blobs[i].harmonizeWith(primary), 0.5)!;
      final color = harmonized.withValues(alpha: colors.blobOpacity);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.primary != primary;
}

/// 玻璃面板:毛玻璃卡片 / 浮层的基础构件。
///
/// 结构为 `阴影 → 圆角裁剪 → 背景模糊 → 半透明填充 + 高光描边`,
/// 可按需关闭模糊(纯色面上的小控件无需模糊,省一次取景)。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = GlassRadius.panel,
    this.blurSigma = 12,
    this.blur = true,
    this.shadow = true,
    this.tint,
    this.stroke,
    this.padding,
    this.margin,
    this.gradient,
  });

  final Widget child;

  /// 圆角半径。
  final double radius;

  /// 背景模糊强度。
  final double blurSigma;

  /// 是否启用背景模糊。纯色背景上的小控件可关闭。
  final bool blur;

  /// 是否绘制柔和投影。
  final bool shadow;

  /// 覆盖填充色。
  final Color? tint;

  /// 覆盖描边色。
  final Color? stroke;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 覆盖填充渐变。默认由 `tint` 生成轻微的上亮下暗。
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.glass;
    final primary = Theme.of(context).colorScheme.primary;
    final borderRadius = BorderRadius.circular(radius);
    final resolvedTint = tint ?? colors.tint;
    // 主题色对玻璃的轻微染色:调整主题色时,所有玻璃面随之变化
    final tintedTint = Color.alphaBlend(
      primary.withValues(alpha: 0.06),
      resolvedTint,
    );
    final tintedStrong = Color.alphaBlend(
      primary.withValues(alpha: 0.06),
      colors.tintStrong,
    );

    Widget panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                tintedStrong,
                tintedTint,
              ],
            ),
        border: Border.all(color: stroke ?? colors.stroke),
      ),
      child: child,
    );

    if (blur) {
      panel = BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: panel,
      );
    }

    panel = ClipRRect(borderRadius: borderRadius, child: panel);

    if (shadow) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: panel,
      );
    }

    if (padding != null || margin != null) {
      panel = Padding(
        padding: (padding ?? EdgeInsets.zero).add(margin ?? EdgeInsets.zero),
        child: panel,
      );
    }

    return panel;
  }
}
