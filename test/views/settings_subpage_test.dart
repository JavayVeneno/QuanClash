import 'package:quanclash/common/common.dart';
import 'package:quanclash/common/theme.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('settings card hosts basic config as a nested subpage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
            return child!;
          },
          home: const SettingsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.current;
    expect(
      find.byKey(const ValueKey('settings-page-next')),
      findsOneWidget,
    );

    // The bottom bar steps the deck one card at a time.
    await tester.tap(find.byKey(const ValueKey('settings-page-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.basicConfig));
    await tester.pumpAndSettle();

    expect(find.text(l10n.basicConfig), findsOneWidget);

    // A legacy ListItem.open entry becomes another level of the same stack.
    await tester.tap(find.text('Hosts'));
    await tester.pumpAndSettle();

    expect(find.text('Hosts'), findsOneWidget);
    expect(find.text(l10n.add), findsOneWidget);
    expect(find.text(l10n.basicConfig), findsNothing);

    await tester.tap(find.byIcon(QuanXIcons.arrowLeft));
    await tester.pumpAndSettle();
    expect(find.text(l10n.basicConfig), findsOneWidget);

    await tester.tap(find.byIcon(QuanXIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-page-next')),
      findsOneWidget,
    );
  });
}
