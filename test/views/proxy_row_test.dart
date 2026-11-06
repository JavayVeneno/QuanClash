import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/proxies/card.dart';
import 'package:fl_clash/views/proxies/tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('list mode keeps region sections and renders rows', (tester) async {
    const group = Group(
      type: GroupType.Selector,
      name: 'G',
      all: [
        Proxy(name: '香港A1', type: 'Vmess'),
        Proxy(name: '日本A1', type: 'Vmess'),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        groupsProvider.overrideWithBuild((_, _) => [group]),
        selectedMapProvider.overrideWithValue(const {}),
        currentProfileIdProvider.overrideWithBuild((_, _) => 1),
        currentProfileProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    globalState.container = container;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(
          child: ProxyGroupView(
            group: group,
            columns: 5,
            cardType: ProxyCardType.expand,
            mode: ProxiesGroupMode.region,
            listMode: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('香港', findRichText: true), findsWidgets);
    expect(find.text('日本', findRichText: true), findsWidgets);
    expect(find.text('香港A1', findRichText: true), findsOneWidget);
    expect(find.text('日本A1', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('proxy row renders compactly without overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsProvider.overrideWithBuild((_, _) => []),
          selectedMapProvider.overrideWithValue(const {}),
          realSelectedProxyStateProvider('node').overrideWith(
            (_) => const SelectedProxyState(proxyName: 'node'),
          ),
        ],
        child: const _TestApp(
          child: Center(
            child: SizedBox(
              width: 360,
              height: 44,
              child: ProxyRow(
                groupName: 'group',
                testUrl: null,
                proxy: Proxy(name: 'node', type: 'Shadowsocks'),
                groupType: GroupType.Selector,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('node', findRichText: true), findsOneWidget);
    expect(find.text('Shadowsocks'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.delegate.supportedLocales,
      builder: (context, child) {
        globalState.theme = CommonTheme.of(context, 1);
        globalState.measure = Measure.of(context, 1);
        return child!;
      },
      home: Scaffold(body: child),
    );
  }
}
