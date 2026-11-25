import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/mobile_v4/liquid_switch.dart';
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
  testWidgets(
    'mobile v4 obsidian hub cycles mode on tap and opens Liquid Glass L-Dock on long press',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var mode = Mode.rule;
      String? openedSheet;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: ThemeData(brightness: Brightness.dark),
              home: Scaffold(
                body: MobileV4RadialFab(
                  mode: mode,
                  activeNodeLabel: '🇭🇰 香港 01',
                  activeProfileLabel: 'Primary Sub',
                  onModeChanged: (next) => setState(() => mode = next),
                  onOpen: (sheet) => openedSheet = sheet,
                ),
              ),
            );
          },
        ),
      );
      await tester.pump();

      // Uses real app icon asset inside ColorFiltered obsidian glass orb.
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(
        image.image,
        isA<AssetImage>().having(
          (a) => a.assetName,
          'assetName',
          'assets/images/icon.png',
        ),
      );

      // Single tap cycles proxy mode directly: rule -> global -> direct.
      await tester.tap(imageFinder);
      await tester.pump(const Duration(milliseconds: 100));
      expect(mode, Mode.global);

      await tester.tap(imageFinder);
      await tester.pump(const Duration(milliseconds: 100));
      expect(mode, Mode.direct);

      // Long press opens the Liquid Glass L-Dock with 4 horizontal pages + 3 vertical modes.
      await tester.longPress(imageFinder);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('代理'), findsOneWidget);
      expect(find.text('配置'), findsOneWidget);
      expect(find.text('监控'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('全局'), findsOneWidget);
      expect(find.text('规则'), findsOneWidget);
      expect(find.text('直连'), findsOneWidget);

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        expect(icon.icon?.fontFamily, QuanXIcons.waypoints.fontFamily);
        expect(icon.size, greaterThan(0));
      }

      // Tapping mode rail switches mode directly.
      await tester.tap(find.text('全局'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(mode, Mode.global);

      // Long press + slide left selects a horizontal dock item on release.
      final hubCenter = tester.getCenter(imageFinder);
      final gesture = await tester.startGesture(hubCenter);
      await tester.pump(const Duration(milliseconds: 650));
      await gesture.moveTo(hubCenter + const Offset(-130, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 250));
      expect(openedSheet, isIn(['proxy', 'config', 'monitor', 'settings']));
    },
  );

  testWidgets(
    'mobile v4 globe handles vertical drag without accidental mode tap',
    (tester) async {
      bool? connected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 400,
              child: MobileV4Globe(
                connected: false,
                onConnectChanged: (value) => connected = value,
              ),
            ),
          ),
        ),
      );

      expect(find.text('上滑连接'), findsOneWidget);
      await tester.drag(find.byType(MobileV4Globe), const Offset(0, -120));
      await tester.pump();
      expect(connected, isTrue);
    },
  );

  testWidgets(
    'mobile v4 dashboard renders single surface in both dark and light themes and guards against globe taps',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(brightness),
            overrides: [
              profilesStreamProvider.overrideWith(
                (_) => Stream.value(const []),
              ),
            ],
            child: MaterialApp(
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
        expect(find.text('规则模式'), findsOneWidget);

        // Tapping the globe should NOT accidentally switch proxy mode.
        await tester.tap(find.byType(MobileV4Globe));
        await tester.pump();
        expect(find.text('规则模式'), findsOneWidget);

        // Tapping the bottom-right QuanClash icon cycles mode cleanly.
        await tester.tap(find.byType(Image));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('全局模式'), findsWidgets);

        for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(icon.size, isNotNull);
          expect(icon.size!, greaterThan(0));
          expect(icon.icon?.fontFamily, QuanXIcons.waypoints.fontFamily);
        }
      }
    },
  );

  testWidgets('mobile v4 liquid switch toggles on tap and horizontal drag', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Scaffold(
              body: Center(
                child: MobileV4LiquidSwitch(
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.byType(MobileV4LiquidSwitch));
    await tester.pump(const Duration(milliseconds: 250));
    expect(value, isTrue);

    await tester.drag(
      find.byType(MobileV4LiquidSwitch),
      const Offset(-36, 0),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(value, isFalse);
  });

  test('mobileV4FormatSpeed formats idle, KB/s, and MB/s values', () {
    expect(mobileV4FormatSpeed(0), ('0.0', 'KB/s'));
    expect(mobileV4FormatSpeed(2458), ('2.4', 'KB/s'));
    expect(mobileV4FormatSpeed(2 * 1024 * 1024), ('2.0', 'MB/s'));
  });
}
