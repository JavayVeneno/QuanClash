import 'package:flutter/material.dart';

import 'color.dart';
import 'glass.dart';

/// Quantumult X 风格的视觉令牌与主题组装。
///
/// 该文件只承载表现层定义（颜色、圆角、ThemeData），不参与状态管理、
/// Core 通信或持久化，因此不会影响代理逻辑与平台能力。
@immutable
class QuanXColors {
  const QuanXColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceSunken,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
  });

  /// QuanX 深色：近黑底色 + 分层灰卡片。
  static const QuanXColors dark = QuanXColors(
    background: Color(0xFF0B0C0E),
    surface: Color(0xFF14161A),
    surfaceElevated: Color(0xFF1C1F24),
    surfaceSunken: Color(0xFF101216),
    separator: Color(0xFF262A30),
    textPrimary: Color(0xFFF2F3F5),
    textSecondary: Color(0xFF9BA1AA),
    textTertiary: Color(0xFF6B7178),
    accent: Color(0xFF2ED3C0),
    onAccent: Color(0xFF04211E),
    info: Color(0xFF3B9CFF),
    success: Color(0xFF34C759),
    warning: Color(0xFFFFC53D),
    danger: Color(0xFFFF5A5F),
  );

  /// QuanX 浅色：iOS 分组背景 + 纯白卡片。
  static const QuanXColors light = QuanXColors(
    background: Color(0xFFF2F2F6),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF7F7FA),
    surfaceSunken: Color(0xFFEAEAEF),
    separator: Color(0xFFE2E3E8),
    textPrimary: Color(0xFF131519),
    textSecondary: Color(0xFF6C727A),
    textTertiary: Color(0xFF9AA0A8),
    accent: Color(0xFF0FA795),
    onAccent: Color(0xFFFFFFFF),
    info: Color(0xFF0A7AFF),
    success: Color(0xFF1FA84E),
    warning: Color(0xFFE9A100),
    danger: Color(0xFFE03B41),
  );

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceSunken;
  final Color separator;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color info;
  final Color success;
  final Color warning;
  final Color danger;

  static QuanXColors of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}

class QuanXRadius {
  static const double group = 14;
  static const double control = 11;
  static const double chip = 7;

  const QuanXRadius._();
}

extension QuanXColorsContextExtension on BuildContext {
  QuanXColors get quanX {
    return QuanXColors.of(Theme.of(this).colorScheme.brightness);
  }

  bool get isQuanXDark {
    return Theme.of(this).colorScheme.brightness == Brightness.dark;
  }
}

/// 把 QuanX 令牌映射回 Material 语义位，避免改动现有业务组件。
ColorScheme quanXColorScheme(ColorScheme base, {bool pureBlack = false}) {
  final colors = QuanXColors.of(base.brightness);
  final isDark = base.brightness == Brightness.dark;
  final background = pureBlack ? Colors.black : colors.background;
  final container = pureBlack
      ? Colors.black
      : isDark
      ? colors.surfaceSunken
      : Colors.white;
  return base.copyWith(
    surface: background,
    onSurface: colors.textPrimary,
    surfaceContainerLowest: container,
    surfaceContainerLow: colors.surface,
    surfaceContainer: container,
    surfaceContainerHigh: colors.surfaceElevated,
    surfaceContainerHighest: colors.separator,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.separator,
    outlineVariant: colors.separator,
    secondaryContainer: Color.alphaBlend(
      base.primary.opacity15,
      colors.surface,
    ),
    surfaceTint: Colors.transparent,
  );
}

/// 组装 QuanX 风格的 [ThemeData]，只覆盖表现层属性。
ThemeData quanXThemeData({
  required ColorScheme colorScheme,
  required PageTransitionsTheme pageTransitionsTheme,
}) {
  final colors = QuanXColors.of(colorScheme.brightness);
  final glass = GlassColors.of(colorScheme.brightness);
  final textTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
  ).textTheme;
  const controlShape = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.all(Radius.circular(QuanXRadius.control)),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    pageTransitionsTheme: pageTransitionsTheme,
    // 透明底色,让氛围背景透出,毛玻璃层叠才有取景对象
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: glass.divider,
      space: 1,
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      iconTheme: IconThemeData(color: colors.textSecondary, size: 20),
      actionsIconTheme: IconThemeData(color: colors.textSecondary, size: 20),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      useIndicator: true,
      indicatorColor: colorScheme.primary.opacity15,
      indicatorShape: controlShape,
      selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 22),
      unselectedIconTheme: IconThemeData(color: colors.textSecondary, size: 22),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: colors.textSecondary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.textSecondary,
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        shape: controlShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: controlShape),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: controlShape,
        side: BorderSide(color: colors.separator),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: controlShape),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: glass.tintStrong,
        borderRadius: BorderRadius.circular(QuanXRadius.chip),
        border: Border.all(color: glass.stroke),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      waitDuration: const Duration(milliseconds: 500),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll<double?>(6),
      radius: const Radius.circular(3),
      crossAxisMargin: 2,
      mainAxisMargin: 2,
      thumbColor: WidgetStatePropertyAll<Color?>(
        colors.textTertiary.opacity60,
      ),
      trackColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
    ),
  );
}
