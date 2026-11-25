import 'package:quanclash/common/common.dart';
import 'package:quanclash/manager/window_manager.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'window header renders crisp Fluent caption glyphs and reacts to maximize state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isMaximizedProvider.overrideWithBuild((_, _) => true),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: const Scaffold(
              body: Column(
                children: [WindowHeader()],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(appName), findsOneWidget);
      expect(find.byIcon(QuanXIcons.pin), findsOneWidget);
      // Native geometric caption glyphs replace the old Lucide squareStack/minus/x.
      expect(find.byIcon(QuanXIcons.squareStack), findsNothing);
      expect(find.byIcon(QuanXIcons.minus), findsNothing);
      expect(find.byIcon(QuanXIcons.x), findsNothing);
      // Three 10x10 CustomPaint caption glyphs: minimize, restore, close.
      final captionPaints = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((cp) => cp.size == const Size(10, 10))
          .toList();
      expect(captionPaints, hasLength(3));
    },
  );
}
