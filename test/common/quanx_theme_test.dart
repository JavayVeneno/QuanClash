import 'package:quanclash/common/glass.dart';
import 'package:quanclash/common/quanx.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quanXThemeData', () {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('resolves sized and coloured text for $brightness', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        late TextTheme text;
        late ColorScheme scheme;
        try {
          final base = ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: brightness,
          );
          scheme = quanXColorScheme(base);
          await tester.pumpWidget(
            MaterialApp(
              theme: quanXThemeData(
                colorScheme: scheme,
                pageTransitionsTheme: const PageTransitionsTheme(),
              ),
              home: Builder(
                builder: (context) {
                  text = Theme.of(context).textTheme;
                  return const Scaffold(body: Text('probe'));
                },
              ),
            ),
          );
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
        expect(tester.takeException(), isNull);

        final styles = <String, TextStyle?>{
          'displayLarge': text.displayLarge,
          'headlineMedium': text.headlineMedium,
          'titleLarge': text.titleLarge,
          'titleMedium': text.titleMedium,
          'bodyLarge': text.bodyLarge,
          'bodyMedium': text.bodyMedium,
          'bodySmall': text.bodySmall,
          'labelLarge': text.labelLarge,
          'labelSmall': text.labelSmall,
        };
        styles.forEach((name, style) {
          // 字号必须存在(否则 TextStyle.apply 会崩)
          expect(style?.fontSize, isNotNull, reason: '$name fontSize');
          // 颜色必须存在(否则正文在界面上不可见)
          expect(style?.color, isNotNull, reason: '$name color');
        });
        // 密度:bodyMedium 14 -> 12.88
        expect(text.bodyMedium!.fontSize!, closeTo(14 * 0.92, 0.01));
        debugPrint(
          '[$brightness] bodyMedium size=${text.bodyMedium!.fontSize} '
          'color=${text.bodyMedium!.color}',
        );
      });
    }

    testWidgets('glass panel provides a Material ancestor for Switch', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      var value = false;
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: quanXThemeData(
              colorScheme: quanXColorScheme(
                ColorScheme.fromSeed(seedColor: Colors.blue),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(),
            ),
            home: Scaffold(
              body: Center(
                child: GlassPanel(
                  child: StatefulBuilder(
                    builder: (context, setState) => Switch(
                      value: value,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // 之前 GlassPanel 缺少 Material,Switch 会抛 debugCheckHasMaterial
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(value, isTrue);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('glass panel forwards taps to its child', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassPanel(
                child: SizedBox(
                  width: 80,
                  height: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SizedBox).last);
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(GlassRadius.panel, 8);
    });
  });
}
