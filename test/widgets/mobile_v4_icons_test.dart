import 'package:quanclash/common/common.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/mobile_v4/mobile_v4_dashboard.dart';
import 'package:quanclash/views/mobile_v4/network_globe.dart';
import 'package:quanclash/views/mobile_v4/radial_fab.dart';
import 'package:quanclash/views/mobile_v4/theme.dart';
import 'package:quanclash/views/mobile_v4/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile v4 radial fab uses the project icon font', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MobileV4RadialFab(onOpen: (_) {})),
      ),
    );

    final icons = tester.widgetList<Icon>(find.byType(Icon));
    expect(icons, isNotEmpty);
    for (final icon in icons) {
      expect(icon.icon?.fontFamily, QuanXIcons.waypoints.fontFamily);
      expect(icon.size, greaterThan(0));
    }
  });

  testWidgets('mobile v4 globe handles tap and vertical drag', (tester) async {
    var tapped = 0;
    bool? connected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 400,
            child: MobileV4Globe(
              connected: false,
              onTap: () => tapped++,
              onConnectChanged: (value) => connected = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('上滑连接'), findsOneWidget);
    await tester.tap(find.byType(MobileV4Globe));
    await tester.pump();
    expect(tapped, 1);

    await tester.drag(find.byType(MobileV4Globe), const Offset(0, -120));
    await tester.pump();
    expect(connected, isTrue);
  });

  testWidgets(
    'mobile v4 dashboard renders single surface in both dark and light themes',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              profilesStreamProvider.overrideWith(
                (_) => Stream.value(const []),
              ),
            ],
            child: MaterialApp(
              key: ValueKey(brightness),
              theme: ThemeData(brightness: brightness),
              locale: const Locale('zh', 'CN'),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
              home: const MobileV4Dashboard(),
            ),
          ),
        );
        await tester.pump();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(
          scaffold.backgroundColor,
          brightness == Brightness.dark
              ? MobileV4Palette.dark.bg
              : MobileV4Palette.light.bg,
        );
        expect(find.text('QUANCLASH'), findsOneWidget);
        expect(find.text('VPN 未连接'), findsOneWidget);
        expect(find.text('实时速度'), findsOneWidget);
        expect(find.text('风险指数'), findsOneWidget);
        expect(find.text('未选择节点'), findsOneWidget);

        for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(icon.size, isNotNull);
          expect(icon.size!, greaterThan(0));
          expect(icon.icon?.fontFamily, QuanXIcons.waypoints.fontFamily);
        }
      }
    },
  );

  test('mobileV4FormatSpeed formats idle, KB/s, and MB/s values', () {
    expect(mobileV4FormatSpeed(0), ('0.0', 'KB/s'));
    expect(mobileV4FormatSpeed(2458), ('2.4', 'KB/s'));
    expect(mobileV4FormatSpeed(2 * 1024 * 1024), ('2.0', 'MB/s'));
  });
}
