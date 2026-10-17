import 'package:fl_clash/common/glass.dart';
import 'package:fl_clash/common/quanx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quanXThemeData', () {
    test('builds without throwing for windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final theme = quanXThemeData(
          colorScheme: scheme,
          pageTransitionsTheme: const PageTransitionsTheme(),
        );
        expect(theme.textTheme.bodyMedium, isNotNull);
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('renders and applies the density font scale', (tester) async {
      late TextTheme resolved;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        await tester.pumpWidget(
          MaterialApp(
            theme: quanXThemeData(
              colorScheme: scheme,
              pageTransitionsTheme: const PageTransitionsTheme(),
            ),
            home: Builder(
              builder: (context) {
                resolved = Theme.of(context).textTheme;
                return const Scaffold(body: Text('density'));
              },
            ),
          ),
        );
      } finally {
        // 必须在测试体结束前复位,否则 framework 会判定调试变量被污染
        debugDefaultTargetPlatformOverride = null;
      }

      expect(tester.takeException(), isNull);
      // 默认 bodyMedium 为 14,收紧 8% 后应约为 12.88
      expect(resolved.bodyMedium?.fontSize, isNotNull);
      expect(resolved.bodyMedium!.fontSize!, lessThan(14));
      expect(resolved.bodyMedium!.fontSize!, closeTo(14 * 0.92, 0.01));
      // 几何主题的字号必须完整,不能出现 null(否则 TextStyle.apply 会崩)
      for (final style in [
        resolved.displayLarge,
        resolved.headlineMedium,
        resolved.titleLarge,
        resolved.titleMedium,
        resolved.bodyLarge,
        resolved.bodyMedium,
        resolved.bodySmall,
        resolved.labelLarge,
        resolved.labelSmall,
      ]) {
        expect(style?.fontSize, isNotNull);
      }
      debugPrint(
        'bodyMedium=${resolved.bodyMedium?.fontSize} '
        'titleMedium=${resolved.titleMedium?.fontSize} '
        'GlassRadius.panel=${GlassRadius.panel}',
      );
    });
  });
}
