import 'dart:async';

import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/core/dns_diagnostic.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/dns_diagnostic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

DnsDiagnostic _report({
  String status = 'ready',
  String endpoint = '1.1.1.1:443',
  String path = 'proxy',
  List<String> warnings = const [
    'configuration-only-not-a-leak-test',
    'direct-bootstrap-path-present',
    'configured-proxy-path-not-verified',
  ],
}) => DnsDiagnostic.fromJson({
  'schemaVersion': 1,
  'source': 'active-config',
  'status': status,
  'proxyBootstrap': 'dedicated',
  'directQueries': 'inherits-main',
  'directFollowPolicy': false,
  'warnings': warnings,
  'routes': [
    {
      'role': 'nameserver',
      'serverIndex': 0,
      'endpoint': endpoint,
      'transport': 'https',
      'path': path,
      'target': 'PROXY',
    },
    {
      'role': 'proxy-server-nameserver',
      'serverIndex': 0,
      'endpoint': '9.9.9.9:853',
      'transport': 'tls',
      'path': 'direct',
    },
    {
      'role': 'direct-nameserver',
      'serverIndex': 0,
      'endpoint': '8.8.8.8:53',
      'transport': 'udp',
      'path': 'rules',
    },
  ],
});

Future<ProviderContainer> _mount(
  WidgetTester tester,
  Future<DnsDiagnostic> Function() loader, {
  CoreStatus coreStatus = CoreStatus.connected,
  bool initialized = true,
  Locale locale = const Locale('en'),
  Size size = const Size(1000, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        viewSizeProvider.overrideWithBuild((_, _) => size),
        initProvider.overrideWithBuild((_, _) => initialized),
        coreStatusProvider.overrideWithBuild((_, _) => coreStatus),
      ],
      child: _TestApp(
        locale: locale,
        child: DnsDiagnosticPage(loadDiagnostic: loader),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(
    tester.element(find.byType(DnsDiagnosticPage)),
  );
}

void main() {
  testWidgets(
    'settings entry does not read or render a diagnostic until opened',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: _TestApp(child: Scaffold(body: DnsDiagnosticItem())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Active DNS paths'), findsOneWidget);
      expect(find.byType(DnsDiagnosticPage), findsNothing);
    },
  );

  testWidgets(
    'separates ordinary, bootstrap and direct-traffic paths without a safe verdict',
    (tester) async {
      var reads = 0;
      await _mount(tester, () async {
        reads++;
        return _report();
      });
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;
      expect(reads, 1);
      expect(find.text(l10n.dnsDiagnosticScope), findsWidgets);
      expect(find.text(l10n.dnsDiagnosticReady), findsOneWidget);
      expect(find.text(l10n.dnsDiagnosticOrdinary), findsOneWidget);
      expect(find.text(l10n.dnsDiagnosticBootstrap), findsOneWidget);
      expect(find.text(l10n.dnsDiagnosticDirect), findsOneWidget);
      expect(find.textContaining('https / 1.1.1.1:443'), findsOneWidget);
      expect(find.textContaining(l10n.dnsDiagnosticPathRules), findsOneWidget);
      expect(find.text(l10n.dnsDiagnosticWarningBootstrap), findsOneWidget);
      expect(find.text(l10n.dnsDiagnosticWarningProxy), findsOneWidget);
      // No timer or repeated probe after the page settles.
      await tester.pump(const Duration(seconds: 30));
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('manual refresh clears old results and hides raw errors', (
    tester,
  ) async {
    var reads = 0;
    final retry = Completer<DnsDiagnostic>();
    await _mount(tester, () {
      reads++;
      return reads == 1 ? Future.value(_report()) : retry.future;
    });
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dns-diagnostic-refresh')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('1.1.1.1:443'), findsNothing);
    retry.completeError(const FormatException('secret-auth-token'));
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizations.current.dnsDiagnosticUnavailable),
      findsOneWidget,
    );
    expect(find.textContaining('secret-auth-token'), findsNothing);
    expect(find.textContaining('1.1.1.1:443'), findsNothing);
    expect(reads, 2);
  });

  testWidgets('timeout becomes unavailable and a late reply stays ignored', (
    tester,
  ) async {
    final pending = Completer<DnsDiagnostic>();
    await _mount(tester, () => pending.future);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(
      find.text(AppLocalizations.current.dnsDiagnosticUnavailable),
      findsOneWidget,
    );
    pending.complete(_report());
    await tester.pumpAndSettle();
    expect(find.textContaining('1.1.1.1:443'), findsNothing);
  });

  testWidgets(
    'disconnected and uninitialized cores do not issue diagnostic requests',
    (tester) async {
      var reads = 0;
      final container = await _mount(
        tester,
        () async {
          reads++;
          return _report();
        },
        coreStatus: CoreStatus.disconnected,
        initialized: false,
      );
      await tester.pumpAndSettle();
      expect(reads, 0);
      container.read(coreStatusProvider.notifier).value = CoreStatus.connected;
      await tester.pump();
      expect(reads, 0);
      container.read(initProvider.notifier).value = true;
      await tester.pumpAndSettle();
      expect(reads, 1);
      container.read(coreStatusProvider.notifier).value =
          CoreStatus.disconnected;
      await tester.pumpAndSettle();
      expect(find.textContaining('1.1.1.1:443'), findsNothing);
      expect(
        find.text(AppLocalizations.current.dnsDiagnosticInactive),
        findsOneWidget,
      );
    },
  );

  testWidgets('disconnect invalidates an in-flight snapshot', (tester) async {
    final pending = Completer<DnsDiagnostic>();
    final container = await _mount(tester, () => pending.future);
    container.read(coreStatusProvider.notifier).value = CoreStatus.disconnected;
    pending.complete(_report());
    await tester.pumpAndSettle();
    expect(find.textContaining('1.1.1.1:443'), findsNothing);
    expect(
      find.text(AppLocalizations.current.dnsDiagnosticInactive),
      findsOneWidget,
    );
  });

  testWidgets(
    'configuration events refresh and superseded responses cannot overwrite newer paths',
    (tester) async {
      final first = Completer<DnsDiagnostic>();
      final second = Completer<DnsDiagnostic>();
      var reads = 0;
      final container = await _mount(
        tester,
        () => ++reads == 1 ? first.future : second.future,
      );
      container.read(checkIpNumProvider.notifier).add();
      second.complete(_report(endpoint: 'new.example:443'));
      await tester.pumpAndSettle();
      expect(find.textContaining('new.example:443'), findsOneWidget);
      first.complete(_report(endpoint: 'stale.example:443'));
      await tester.pumpAndSettle();
      expect(find.textContaining('stale.example:443'), findsNothing);
      expect(reads, 2);
    },
  );

  testWidgets(
    'disposed page ignores requests and unsubscribes from core events',
    (tester) async {
      final pending = Completer<DnsDiagnostic>();
      final container = await _mount(tester, () => pending.future);
      // Retain the same ProviderScope while removing only the diagnostic page.
      final scope = tester.widget<ProviderScope>(find.byType(ProviderScope));
      await tester.pumpWidget(
        ProviderScope(
          overrides: scope.overrides,
          child: const _TestApp(child: SizedBox()),
        ),
      );
      container.read(checkIpNumProvider.notifier).add();
      pending.complete(_report());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DnsDiagnosticPage), findsNothing);
    },
  );

  for (final status in ['disabled', 'inactive', 'not-configured', 'future']) {
    testWidgets(
      'non-ready status $status never displays active resolver rows',
      (tester) async {
        await _mount(tester, () async => _report(status: status));
        await tester.pumpAndSettle();
        expect(find.textContaining('1.1.1.1:443'), findsNothing);
        expect(
          find.text(AppLocalizations.current.dnsDiagnosticReady),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'unknown paths and future warning codes are shown as unverified',
    (tester) async {
      await _mount(
        tester,
        () async => _report(path: 'future', warnings: ['new-core-warning']),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Unknown\nhttps'), findsOneWidget);
      expect(
        find.text(AppLocalizations.current.dnsDiagnosticWarningUnknown),
        findsOneWidget,
      );
      expect(find.text('new-core-warning'), findsOneWidget);
    },
  );

  testWidgets('empty warning list never implies leak-free', (tester) async {
    await _mount(tester, () async => _report(warnings: []));
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizations.current.dnsDiagnosticNoWarnings),
      findsOneWidget,
    );
  });

  for (final locale in ['en', 'zh_CN', 'ja', 'ru']) {
    testWidgets('localized diagnostic scrolls at narrow widths: $locale', (
      tester,
    ) async {
      final parts = locale.split('_');
      await _mount(
        tester,
        () async => _report(endpoint: '${'very-long-host.' * 6}example:443'),
        locale: Locale(parts.first, parts.length > 1 ? parts.last : null),
        size: const Size(360, 800),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.current;
      expect(find.text(l10n.dnsDiagnosticTitle), findsOneWidget);
      for (var i = 0; i < 7; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -550));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text(l10n.dnsDiagnosticWarningProxy), findsOneWidget);
    });
  }
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
      return child!;
    },
    home: child,
  );
}
