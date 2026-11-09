import 'package:quanclash/common/common.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// 仪表盘配色，对齐设计稿 mockup_dashboard.html。
class DashboardPalette {
  const DashboardPalette._();

  static const primary = Color(0xFF6C5CE7);
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFFF9500);
  static const purple = Color(0xFF9333EA);

  static const backgroundLight = Color(0xFFF2F2F7);
  static const backgroundDark = Color(0xFF0F0F12);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1E1E24);

  static Color background(BuildContext context) =>
      Theme.brightnessOf(context) == Brightness.dark
      ? backgroundDark
      : backgroundLight;

  static Color surface(BuildContext context) =>
      Theme.brightnessOf(context) == Brightness.dark
      ? surfaceDark
      : surfaceLight;
}

/// 仪表盘统一图标块：彩色底 + 同色图标，对应设计稿里的圆角图标格。
class DashboardIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const DashboardIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

/// 统计卡右上角的装饰性迷你柱状图。
class DashboardMiniBars extends StatelessWidget {
  final Color color;
  final List<double> values;
  final double height;

  const DashboardMiniBars({
    super.key,
    required this.color,
    this.values = const [0.35, 0.6, 0.45, 0.8, 0.65, 1.0],
    this.height = 22,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i != 0) const SizedBox(width: 3),
            Container(
              width: 4,
              height: (height * values[i]).clamp(4.0, height),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.20 + 0.55 * values[i]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 仪表盘卡片：设计稿里的白底圆角卡片（深色模式使用深色表面）。
class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onPressed;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final radius = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: DashboardPalette.surface(context),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// 卡片标题行：图标块 + 标题 + 可选尾部。
class DashboardCardTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;

  const DashboardCardTitle({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DashboardIconTile(icon: icon, color: color, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.quanX.textSecondary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
