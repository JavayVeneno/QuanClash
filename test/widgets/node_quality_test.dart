import 'dart:async';

import 'package:quanclash/common/theme.dart';
import 'package:quanclash/common/measure.dart';
import 'package:quanclash/core/node_quality.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/proxies/card.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

NodeQualityResult _report({
  bool includeIpPure = false,
  bool failed = false,
  String ip = '203.0.113.1',
  DateTime? sampledAt,
}) => NodeQualityResult.fromJson({
  'schemaVersion': 1,
  'source': 'selected-proxy',
  'proxyName': 'node',
  'sampledAt':
      (sampledAt ?? DateTime.utc(2026, 10, 30, 1, 2, 3)).toIso8601String(),
  'network': {
    'provider': 'cloudflare',
    'status': 'ok',
    'egressIp': ip,
    'colo': 'HKG',
    'country': 'HK',
    'ttfbMs': 42,
  },
  'quality': includeIpPure
      ? {
          'provider': 'ippure',
          'status': failed ? 'timeout' : 'ok',
          if (!failed) ...{
            'egressIp': '203.0.113.2',
            'riskScore': 75,
            'isResidential': false,
          },
        }
      : {'provider': 'ippure', 'status': 'not-requested'},
});

Future<ProviderContainer> _mount(
  WidgetTester tester,
  NodeQualityLoader loader, {
  CoreStatus status = CoreStatus.connected,
  bool initialized = true,
  Locale locale = const Locale('en'),
  Size size = const Size(1000, 1600),
  NodeQualityCooldown? cooldown,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        coreStatusProvider.overrideWithBuild((_, _) => status),
        initProvider.overrideWithBuild((_, _) => initialized),
        currentProfileIdProvider.overrideWithBuild((_, _) => 1),
        selectedMapProvider.overrideWithValue(const {}),
      ],
      child: _TestApp(
        locale: locale,
        child: NodeQualityDialog(
          proxyName: 'node',
          loadQuality: loader,
          cooldown: cooldown ?? NodeQualityCooldown(interval: Duration.zero),
          autoCloseOnSuccess: false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
    tester.element(find.byType(NodeQualityDialog)),
  );
}

Future<void> _run(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('node-quality-run')));
  await tester.pump();
}

Future<void> _consent(WidgetTester tester) async {
  final control = find.byType(Switch);
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opening is offline; explicit default check excludes IPPure', (
    tester,
  ) async {
    var reads = 0;
    await _mount(tester, (name, {required includeIpPure}) async {
      reads++;
      expect(name, 'node');
      expect(includeIpPure, isFalse);
      return _report();
    });
    expect(reads, 0);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    await _run(tester);
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(find.textContaining('203.0.113.1'), findsOneWidget);
    expect(
      find.text(AppLocalizations.current.nodeQualityNotRequested),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 30));
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'consent alone does not send requests; results distinguish egress IPs',
    (tester) async {
      var reads = 0;
      await _mount(tester, (_, {required includeIpPure}) async {
        reads++;
        expect(includeIpPure, isTrue);
        return _report(includeIpPure: true);
      });
      await _consent(tester);
      await tester.pumpAndSettle();
      expect(reads, 0);
      await _run(tester);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;
      expect(find.textContaining('203.0.113.2'), findsOneWidget);
      expect(find.text(l10n.nodeQualityRiskScore), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text(' / 100'), findsOneWidget);
      expect(find.text(l10n.riskIndexHigh), findsOneWidget);
      expect(find.text(l10n.nodeQualityMismatch), findsOneWidget);
      expect(
        find.textContaining(l10n.nodeQualityNonResidential),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'provider timeout preserves Cloudflare success but never scores zero',
    (tester) async {
      await _mount(
        tester,
        (_, {required includeIpPure}) async =>
            _report(includeIpPure: true, failed: true),
      );
      await _consent(tester);
      await _run(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('203.0.113.1'), findsOneWidget);
      expect(
        find.text(AppLocalizations.current.nodeQualityStatusTimeout),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizations.current.nodeQualityRiskScore),
        findsNothing,
      );
    },
  );

  testWidgets('retry clears stale results; raw errors are hidden', (
    tester,
  ) async {
    var reads = 0;
    final retry = Completer<NodeQualityResult>();
    await _mount(tester, (_, {required includeIpPure}) {
      reads++;
      return reads == 1 ? Future.value(_report()) : retry.future;
    });
    await _run(tester);
    await tester.pumpAndSettle();
    await _run(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('203.0.113.1'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('node-quality-run')))
          .onPressed,
      isNull,
    );
    retry.completeError(const FormatException('secret-auth-token'));
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizations.current.nodeQualityFailed),
      findsOneWidget,
    );
    expect(find.textContaining('secret-auth-token'), findsNothing);
  });

  testWidgets('profile switch drops late result and resets consent', (
    tester,
  ) async {
    final pending = Completer<NodeQualityResult>();
    final container = await _mount(
      tester,
      (_, {required includeIpPure}) => pending.future,
    );
    await _consent(tester);
    await _run(tester);
    container.read(currentProfileIdProvider.notifier).update((_) => 2);
    await tester.pump();
    pending.complete(_report(includeIpPure: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('203.0.113.1'), findsNothing);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('disconnect clears the result and disables checking', (
    tester,
  ) async {
    final container = await _mount(
      tester,
      (_, {required includeIpPure}) async => _report(),
    );
    await _run(tester);
    await tester.pumpAndSettle();
    container
        .read(coreStatusProvider.notifier)
        .update((_) => CoreStatus.disconnected);
    await tester.pumpAndSettle();
    expect(find.textContaining('203.0.113.1'), findsNothing);
    expect(
      find.text(AppLocalizations.current.nodeQualityInactive),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('node-quality-run')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('uninitialized core never invokes a check', (tester) async {
    await _mount(
      tester,
      (_, {required includeIpPure}) async => throw StateError('must not run'),
      initialized: false,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('node-quality-run')))
          .onPressed,
      isNull,
    );
    expect(
      find.text(AppLocalizations.current.nodeQualityInactive),
      findsOneWidget,
    );
  });

  testWidgets(
    'dialog timeout is explicit and late completion cannot replace it',
    (tester) async {
      final pending = Completer<NodeQualityResult>();
      await _mount(tester, (_, {required includeIpPure}) => pending.future);
      await _run(tester);
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations.current.nodeQualityTimeout),
        findsOneWidget,
      );
      pending.complete(_report());
      await tester.pumpAndSettle();
      expect(find.textContaining('203.0.113.1'), findsNothing);
    },
  );

  testWidgets('closing discards in-flight results', (tester) async {
    final pending = Completer<NodeQualityResult>();
    await _mount(tester, (_, {required includeIpPure}) => pending.future);
    await _run(tester);
    await tester.pumpWidget(const SizedBox());
    pending.complete(_report());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final locale in const [
    Locale('en'),
    Locale('zh', 'CN'),
    Locale('ja'),
    Locale('ru'),
  ]) {
    testWidgets('narrow ${locale.toLanguageTag()} dialog wraps and scrolls', (
      tester,
    ) async {
      await _mount(
        tester,
        (_, {required includeIpPure}) async => _report(includeIpPure: true),
        locale: locale,
        size: const Size(360, 800),
      );
      await _consent(tester);
      await _run(tester);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(AppLocalizations.current.nodeQualityMismatch),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in ProxyCardType.values) {
    testWidgets(
      'quality entry fits $type proxy card without changing selection',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              groupsProvider.overrideWithBuild((_, _) => []),
              selectedMapProvider.overrideWithValue(const {}),
              realSelectedProxyStateProvider('node').overrideWith(
                (_) => const SelectedProxyState(proxyName: 'node'),
              ),
            ],
            child: _TestApp(
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 140,
                  child: ProxyCard(
                    groupName: 'group',
                    testUrl: null,
                    proxy: const Proxy(name: 'node', type: 'Shadowsocks'),
                    groupType: GroupType.Selector,
                    type: type,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byTooltip(AppLocalizations.current.nodeQualityTitle),
          findsOneWidget,
        );
        await tester.tap(
          find.byTooltip(AppLocalizations.current.nodeQualityTitle),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NodeQualityDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fresh risk score is shown on the node card', (tester) async {
    final report = _report(
      includeIpPure: true,
      sampledAt: DateTime.now().toUtc(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsProvider.overrideWithBuild((_, _) => []),
          selectedMapProvider.overrideWithValue(const {}),
          realSelectedProxyStateProvider('node').overrideWith(
            (_) => const SelectedProxyState(proxyName: 'node'),
          ),
          nodeQualityResultsProvider.overrideWithBuild(
            (_, _) => {'node': report},
          ),
        ],
        child: const _TestApp(
          child: Center(
            child: SizedBox(
              width: 240,
              height: 140,
              child: ProxyCard(
                groupName: 'group',
                testUrl: null,
                proxy: Proxy(name: 'node', type: 'Shadowsocks'),
                groupType: GroupType.Selector,
                type: ProxyCardType.expand,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('75/100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale risk score is hidden on the node card', (tester) async {
    final report = _report(
      includeIpPure: true,
      sampledAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupsProvider.overrideWithBuild((_, _) => []),
          selectedMapProvider.overrideWithValue(const {}),
          realSelectedProxyStateProvider('node').overrideWith(
            (_) => const SelectedProxyState(proxyName: 'node'),
          ),
          nodeQualityResultsProvider.overrideWithBuild(
            (_, _) => {'node': report},
          ),
        ],
        child: const _TestApp(
          child: Center(
            child: SizedBox(
              width: 240,
              height: 140,
              child: ProxyCard(
                groupName: 'group',
                testUrl: null,
                proxy: Proxy(name: 'node', type: 'Shadowsocks'),
                groupType: GroupType.Selector,
                type: ProxyCardType.expand,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('75/100'), findsNothing);
  });

  test('cooldown is per node and provider and expires', () {
    var now = DateTime.utc(2026, 11, 2, 12);
    final cooldown = NodeQualityCooldown(
      interval: const Duration(seconds: 30),
      clock: () => now,
    );
    expect(cooldown.remaining('a', 'cloudflare'), Duration.zero);
    cooldown.record('a', 'cloudflare');
    expect(cooldown.remaining('a', 'cloudflare'), const Duration(seconds: 30));
    expect(cooldown.remaining('a', 'ippure'), Duration.zero);
    expect(cooldown.remaining('b', 'cloudflare'), Duration.zero);
    now = now.add(const Duration(seconds: 10));
    expect(cooldown.remaining('a', 'cloudflare'), const Duration(seconds: 20));
    now = now.add(const Duration(seconds: 20));
    expect(cooldown.remaining('a', 'cloudflare'), Duration.zero);
  });

  test('cooldown stays bounded and drops the oldest entry', () {
    var now = DateTime.utc(2026, 11, 2, 12);
    final cooldown = NodeQualityCooldown(
      interval: const Duration(minutes: 5),
      clock: () => now,
      maxEntries: 2,
    );
    cooldown.record('a', 'cloudflare');
    now = now.add(const Duration(seconds: 1));
    cooldown.record('b', 'cloudflare');
    now = now.add(const Duration(seconds: 1));
    cooldown.record('c', 'cloudflare');
    expect(cooldown.remaining('a', 'cloudflare'), Duration.zero);
    expect(cooldown.remaining('b', 'cloudflare').inSeconds, greaterThan(0));
    expect(cooldown.remaining('c', 'cloudflare').inSeconds, greaterThan(0));
  });

  testWidgets(
    'Cloudflare score is explicitly unavailable and never fabricated',
    (tester) async {
      await _mount(tester, (_, {required includeIpPure}) async => _report());
      await _run(tester);
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;
      expect(find.text(l10n.nodeQualityProbeFootprint), findsOneWidget);
      expect(
        find.text(l10n.nodeQualityCloudflareScore),
        findsOneWidget,
      );
      expect(
        find.text(l10n.nodeQualityCloudflareScoreUnavailable),
        findsOneWidget,
      );
      expect(find.text('0'), findsNothing);
    },
  );

  testWidgets(
    'repeated checks are throttled per node without another request',
    (tester) async {
      var now = DateTime.utc(2026, 11, 2, 12);
      var reads = 0;
      final cooldown = NodeQualityCooldown(
        interval: const Duration(seconds: 30),
        clock: () => now,
      );
      await _mount(tester, (_, {required includeIpPure}) async {
        reads++;
        return _report();
      }, cooldown: cooldown);
      await _run(tester);
      await tester.pumpAndSettle();
      expect(reads, 1);
      await _run(tester);
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(
        find.text(AppLocalizations.current.nodeQualityCooldown(30)),
        findsOneWidget,
      );
      now = now.add(const Duration(seconds: 31));
      await _run(tester);
      await tester.pumpAndSettle();
      expect(reads, 2);
    },
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.locale = const Locale('en')});
  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: locale,
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
