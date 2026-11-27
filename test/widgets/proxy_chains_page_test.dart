import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanclash/common/quanx.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/proxies/chains/chains_page.dart';
import 'package:quanclash/widgets/mobius_icon.dart';

class _FakeProfileProxyChains extends ProfileProxyChains {
  _FakeProfileProxyChains(this._initial);

  final List<ProxyChain> _initial;

  @override
  List<ProxyChain> build(int profileId) => _initial;

  @override
  Future<void> put(ProxyChain chain) async {
    final idx = state.indexWhere((c) => c.id == chain.id);
    if (idx == -1) {
      state = [...state, chain];
    } else {
      final next = List<ProxyChain>.from(state);
      next[idx] = chain;
      state = next;
    }
  }

  @override
  Future<void> deleteChain(int id) async {
    state = state.where((c) => c.id != id).toList();
  }
}

class _FakeProfiles extends Profiles {
  _FakeProfiles(this._initial);

  final List<Profile> _initial;

  @override
  List<Profile> build() => _initial;

  @override
  void updateProfile(int profileId, Profile Function(Profile profile) builder) {
    state = [
      for (final p in state) p.id == profileId ? builder(p) : p,
    ];
  }
}

Map<String, dynamic> _sampleRawConfig() {
  return {
    'proxies': [
      {
        'name': 'HK-01',
        'type': 'vless',
        'server': '1.1.1.1',
        'port': 443,
        'udp': true,
      },
      {
        'name': 'US-Res-A',
        'type': 'ss',
        'server': '2.2.2.1',
        'port': 8388,
        'udp': true,
      },
    ],
    'proxy-groups': [
      {
        'name': 'Proxy',
        'type': 'select',
        'proxies': ['HK-01', 'US-Res-A'],
      },
    ],
    'rules': ['MATCH,Proxy'],
  };
}

Widget _wrapPage({
  required List<ProxyChain> chains,
  bool chainsEnabled = true,
}) {
  final profile = Profile(
    id: 1,
    label: 'TestProfile',
    autoUpdateDuration: const Duration(hours: 24),
    chainsEnabled: chainsEnabled,
  );
  return ProviderScope(
    overrides: [
      profilesProvider.overrideWith(() => _FakeProfiles([profile])),
      profileProxyChainsProvider(
        1,
      ).overrideWith(() => _FakeProfileProxyChains(chains)),
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
      home: ProxyChainsPage(
        initialProfileId: 1,
        initialRawConfig: _sampleRawConfig(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders MobiusIcon, single-node direct badge, and node pool cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const chain = ProxyChain(
      id: 100,
      profileId: 1,
      name: '美国住宅',
      entry: ChainHop(members: ['HK-01']),
      exit: ChainHop(members: ['US-Res-A']),
    );

    await tester.pumpWidget(_wrapPage(chains: const [chain]));
    await tester.pumpAndSettle();

    expect(find.byType(MobiusIcon), findsWidgets);
    expect(find.text('美国住宅'), findsWidgets);
    expect(find.text('单节点直挂'), findsNWidgets(2));
    expect(find.text('香港'), findsOneWidget);
    expect(find.text('美国'), findsOneWidget);
    expect(find.text('HK-01'), findsWidgets);
    expect(find.text('US-Res-A'), findsWidgets);
    // Exit container must never expose load-balance or url-test.
    expect(find.text('load-balance'), findsNothing);
    expect(find.text('select'), findsOneWidget);
  });

  testWidgets('shows missing-node error banner when node is absent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const broken = ProxyChain(
      id: 101,
      profileId: 1,
      name: '失效链',
      entry: ChainHop(members: ['HK-01']),
      exit: ChainHop(members: ['GoneNode']),
    );

    await tester.pumpWidget(_wrapPage(chains: const [broken]));
    await tester.pumpAndSettle();

    expect(find.textContaining('GoneNode'), findsWidgets);
    expect(find.text('定位'), findsOneWidget);
  });

  testWidgets('shows disabled overlay when profile chainsEnabled is false', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrapPage(chains: const [], chainsEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text('本配置已关闭链式代理'), findsOneWidget);
    expect(find.text('重新开启'), findsOneWidget);
  });
}
