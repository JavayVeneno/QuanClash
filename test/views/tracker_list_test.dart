import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/connection/tracker_list.dart';
import 'package:fl_clash/widgets/page_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

TrackerInfo _trackerInfo() {
  return TrackerInfo(
    id: '1',
    start: DateTime.now(),
    metadata: const Metadata(
      network: 'tcp',
      host: 'chat.openai.com',
      destinationIP: '104.18.37.228',
      destinationPort: '443',
      process: 'ChatGPT.exe',
    ),
    chains: const ['DIRECT', '直接连接', '其他流量'],
    rule: 'Match',
    rulePayload: '',
    upload: 21 * 1024,
    download: 2 * 1024,
  );
}

void main() {
  testWidgets('list card renders rows and opens the detail modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: [
            PageSearchToolbar(
              query: '',
              onQueryChanged: (_) {},
            ),
            const Divider(height: 1),
            Expanded(
              child: TrackerInfoList(
                items: [_trackerInfo()],
                detailTitle: '连接详情',
                emptyLabel: '暂无连接',
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('chat.openai.com'), findsOneWidget);
    expect(find.text('104.18.37.228:443'), findsOneWidget);
    expect(find.text('ChatGPT.exe'), findsOneWidget);
    expect(find.text('DIRECT'), findsOneWidget);
    expect(find.text('直接连接'), findsOneWidget);

    await tester.tap(find.text('chat.openai.com'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('网络'), findsOneWidget);
    expect(find.text('流量'), findsOneWidget);
    expect(find.text('代理链'), findsOneWidget);
    expect(find.text('复制信息'), findsOneWidget);
    expect(find.text('TCP'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
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
