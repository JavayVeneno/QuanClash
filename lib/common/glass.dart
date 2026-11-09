import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 玻璃材质令牌与基础组件。
///
/// 与上游原版的「平面灰卡 + 1px 描边」不同,这里是一套**自绘毛玻璃**体系:
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
    tint: Color(0xDEFFFFFF),
    tintStrong: Color(0xF5FFFFFF),
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
    tint: Color(0xD914161A),
    tintStrong: Color(0xF214161A),
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
  static const double panel = 8;

  /// 玻璃浮层 / 工具条。
  static const double bar = 8;

  /// 玻璃控件(按钮、输入框)。
  static const double control = 6;

  /// 玻璃标签。
  static const double chip = 4;

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

/// 应用背景:设计稿的纯色底(浅色为浅灰,深色为近黑)。
///
/// 之前这里是渐变 + 柔光色斑,为了让整体更接近设计稿,改为纯色底。
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colorScheme.surface),
        ?child,
      ],
    );
  }
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
    this.blur = false,
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

    panel = ClipRRect(
      borderRadius: borderRadius,
      // 玻璃面板内部补一个透明的 Material:Switch / InkWell / TextButton 等
      // 组件都依赖 Material 祖先,缺失时会直接在 debug 下抛断言。
      child: Material(type: MaterialType.transparency, child: panel),
    );

    if (shadow) {
      panel = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 3),
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
