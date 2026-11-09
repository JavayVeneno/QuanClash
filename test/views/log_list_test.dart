import 'package:quanclash/common/measure.dart';
import 'package:quanclash/common/theme.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/logs.dart';
import 'package:quanclash/widgets/page_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('log rows render and open the detail modal', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final logs = [
      const Log(
        payload: '[APP] focus',
        logLevel: LogLevel.info,
        dateTime: '2026-11-05 15:59:16',
      ),
      const Log(
        payload: 'something failed',
        logLevel: LogLevel.error,
        dateTime: '2026-11-05 15:59:17',
      ),
    ];
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: [
            PageSearchToolbar(query: '', onQueryChanged: (_) {}),
            const Divider(height: 1),
            Expanded(
              child: LogList(items: logs, emptyLabel: '暂无日志'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('[APP] focus'), findsOneWidget);
    expect(find.text('something failed'), findsOneWidget);
    expect(find.text('info'), findsOneWidget);
    expect(find.text('error'), findsOneWidget);
    expect(find.text('2026-11-05 15:59:16'), findsOneWidget);

    await tester.tap(find.text('[APP] focus'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('复制信息'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('zh', 'CN'),
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
