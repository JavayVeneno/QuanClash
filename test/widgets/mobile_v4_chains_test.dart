import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanclash/common/quanx.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/mobile_v4/globe_painter.dart';
import 'package:quanclash/views/mobile_v4/radial_fab.dart';
import 'package:quanclash/views/mobile_v4/sheets/chains_sheet.dart';
import 'package:quanclash/widgets/mobius_icon.dart';

class _FakeChains extends ProfileProxyChains {
  _FakeChains(this._initial);

  final List<ProxyChain> _initial;

  @override
  List<ProxyChain> build(int profileId) => _initial;
}

class _FakeProfiles extends Profiles {
  _FakeProfiles(this._initial);

  final List<Profile> _initial;

  @override
  List<Profile> build() => _initial;
}

Widget _wrapMobile(Widget child, {List<ProxyChain> chains = const []}) {
  const profile = Profile(
    id: 1,
    label: 'CY',
    autoUpdateDuration: Duration(hours: 24),
  );
  return ProviderScope(
    overrides: [
      profilesProvider.overrideWith(() => _FakeProfiles([profile])),
      profileProxyChainsProvider(1).overrideWith(() => _FakeChains(chains)),
    ],
    child: MaterialApp(
      theme: quanXThemeData(
        colorScheme: quanXColorScheme(
          ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.dark,
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      locale: const Locale('zh', 'CN'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('L-Dock places Mobius chains item next to Proxy and opens chains', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? openedType;
    await tester.pumpWidget(
      _wrapMobile(
        MobileV4RadialFab(
          mode: Mode.rule,
          onModeChanged: (_) {},
          onOpen: (type) => openedType = type,
        ),
      ),
    );
    await tester.pump();

    // Long press the hub to open the horizontal Liquid Glass L-Dock.
    await tester.longPressAt(const Offset(340, 780));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('代理'), findsOneWidget);
    expect(find.text('链路'), findsOneWidget);
    expect(find.byType(MobiusIcon), findsOneWidget);

    await tester.tap(find.text('链路'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(openedType, 'chains');
  });

  testWidgets('MobileV4ChainsSheet lists chains and opens vertical editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const chain = ProxyChain(
      id: 10,
      profileId: 1,
      name: '香港-日本家宽',
      entry: ChainHop(members: ['HK-01']),
      exit: ChainHop(members: ['JP-01']),
    );
    final rawConfig = {
      'proxies': [
        {'name': 'HK-01', 'type': 'vless', 'server': '1.1.1.1', 'port': 443},
        {'name': 'JP-01', 'type': 'ss', 'server': '2.2.2.2', 'port': 8388},
      ],
      'proxy-groups': const <dynamic>[],
      'rules': const <String>[],
    };

    final scrollCtrl = ScrollController();
    addTearDown(scrollCtrl.dispose);

    await tester.pumpWidget(
      _wrapMobile(
        MobileV4ChainsSheet(
          controller: scrollCtrl,
          initialProfileId: 1,
          initialRawConfig: rawConfig,
        ),
        chains: const [chain],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('香港-日本家宽'), findsOneWidget);
    expect(find.byType(MobiusIcon), findsWidgets);

    await tester.tap(find.text('香港-日本家宽'));
    await tester.pumpAndSettle();

    expect(find.text('单节点直挂'), findsNWidgets(2));
    expect(find.text('load-balance'), findsNothing);
    expect(find.text('dialer-proxy · YAML'), findsOneWidget);
  });

  test('globe projects East to the right and North to the top (no mirror flip)', () {
    // Center the globe on Beijing (39.9N, 116.4E).
    final yaw = MobileV4GlobePainter.yawForLatLon(39.9, 116.4);
    final beijing = MobileV4GlobePainter.projectLatLonForTest(
      39.9,
      116.4,
      yaw: yaw,
    );
    final tokyo = MobileV4GlobePainter.projectLatLonForTest(
      35.68,
      139.69,
      yaw: yaw,
    );
    final hongKong = MobileV4GlobePainter.projectLatLonForTest(
      22.32,
      114.17,
      yaw: yaw,
    );
    final india = MobileV4GlobePainter.projectLatLonForTest(
      20.59,
      78.96,
      yaw: yaw,
    );

    // Tokyo (east) must be to the RIGHT of Beijing; India (west) to the LEFT.
    expect(tokyo.dx, greaterThan(beijing.dx));
    expect(india.dx, lessThan(beijing.dx));
    // Hong Kong (south) must be BELOW Beijing (larger screen y).
    expect(hongKong.dy, greaterThan(beijing.dy));
  });
}
