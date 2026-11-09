import 'package:quanclash/common/common.dart';
import 'package:quanclash/views/dashboard/widgets/connection_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: quanXThemeData(
      colorScheme: quanXColorScheme(
        ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Widget _surface({
  VoidCallback? onToggle,
  String runTime = '00:12:34',
  String nodeName = 'HK-01',
}) {
  return ConnectionHeroSurface(
    statusText: 'Connected',
    statusColor: Colors.green,
    connected: true,
    mode: 'global',
    runTime: runTime,
    isStart: true,
    actionLabel: 'Stop',
    nodeName: nodeName,
    groupName: 'Auto',
    delay: 42,
    upload: '1.2 MB',
    download: '8.4 MB',
    onToggle: onToggle ?? () {},
  );
}

void main() {
  testWidgets('wide hero shows connection status and action', (tester) async {
    tester.view.physicalSize = const Size(1100, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(SizedBox(width: 1000, child: _surface())));
    expect(find.textContaining('Connected'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow hero stacks without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(SizedBox(width: 320, child: _surface())));
    expect(find.textContaining('Connected'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle hero keeps the action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 800,
          child: _surface(onToggle: () => taps++, runTime: '--:--:--'),
        ),
      ),
    );
    await tester.tap(find.text('Stop'));
    expect(taps, 1);
  });
}
