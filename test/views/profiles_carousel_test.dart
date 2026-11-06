import 'package:fl_clash/common/measure.dart';
import 'package:fl_clash/common/theme.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/profiles/profiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _urlProfile(int id, String label) {
  final now = DateTime.now();
  return Profile(
    id: id,
    label: label,
    url: 'https://$label.example.com/subscribe',
    lastUpdateDate: now,
    autoUpdateDuration: const Duration(hours: 24),
    subscriptionInfo: SubscriptionInfo(
      upload: 50 * 1024 * 1024 * 1024,
      download: 50 * 1024 * 1024 * 1024,
      total: 200 * 1024 * 1024 * 1024,
      expire: now.add(const Duration(days: 365)).millisecondsSinceEpoch ~/ 1000,
    ),
  );
}

Profile _fileProfile(int id, String label) {
  return Profile(
    id: id,
    label: label,
    autoUpdateDuration: const Duration(hours: 24),
    lastUpdateDate: DateTime.now(),
  );
}

final _profiles = [
  _urlProfile(1, 'Alpha'),
  _fileProfile(2, 'Beta'),
  _urlProfile(3, 'Gamma'),
  _urlProfile(4, 'Delta'),
];

Future<void> _pump(
  WidgetTester tester, {
  List<Profile>? profiles,
  int currentId = 1,
  GlobalKey<ProfilesCarouselState>? carouselKey,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentProfileIdProvider.overrideWithBuild((_, _) => currentId),
        groupsProvider.overrideWithBuild((_, _) => []),
      ],
      child: _TestApp(
        child: ProfilesCarousel(
          key: carouselKey,
          profiles: profiles ?? _profiles,
          currentProfileId: currentId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _cardText(int id, String text) {
  return find.descendant(
    of: find.byKey(ValueKey('profile-card-$id')),
    matching: find.text(text),
  );
}

void main() {
  testWidgets('shows active summary and expands details on tap', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text(l10n.profileActive), findsOneWidget);
    expect(find.text(l10n.profileTapToExpand), findsOneWidget);
    expect(find.text(l10n.profileRemainingTraffic), findsWidgets);

    await tester.tap(_cardText(1, 'Alpha'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileSubscriptionUrl), findsOneWidget);
    expect(find.text(l10n.profileNodeCount), findsOneWidget);
    expect(find.text(l10n.profileCurrentConfig), findsOneWidget);
    expect(find.text(l10n.profileCollapse), findsOneWidget);

    await tester.tap(_cardText(1, l10n.profileCollapse));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileSubscriptionUrl), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('side cards navigate and wrap around', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;

    await tester.tap(_cardText(2, 'Beta'));
    await tester.pumpAndSettle();
    expect(_cardText(2, l10n.profileTapToExpand), findsOneWidget);
    expect(_cardText(1, l10n.profileTapToExpand), findsNothing);

    await tester.tap(_cardText(1, 'Alpha'));
    await tester.pumpAndSettle();
    expect(_cardText(1, l10n.profileTapToExpand), findsOneWidget);

    await tester.tap(_cardText(4, 'Delta'));
    await tester.pumpAndSettle();
    expect(_cardText(4, l10n.profileTapToExpand), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit button opens and closes the inline editor', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;
    await tester.tap(find.byTooltip(l10n.edit));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileEditTitle), findsOneWidget);
    expect(find.text(l10n.profileSaveChanges), findsOneWidget);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileEditTitle), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file profile shows the local file summary', (tester) async {
    await _pump(tester, currentId: 2);
    final l10n = AppLocalizations.current;
    expect(find.text(l10n.profileLocalYaml), findsWidgets);
    expect(find.text(l10n.profileTapToExpand), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('subscription URL is masked until revealed', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;
    await tester.tap(_cardText(1, 'Alpha'));
    await tester.pumpAndSettle();
    expect(find.textContaining('•'), findsOneWidget);
    expect(find.text(_profiles.first.url), findsNothing);

    await tester.tap(find.byTooltip(l10n.profileShowLink));
    await tester.pumpAndSettle();
    expect(find.text(_profiles.first.url), findsOneWidget);
    expect(find.byTooltip(l10n.profileHideLink), findsOneWidget);
  });

  testWidgets('add opens a draft card with an inline form', (tester) async {
    final key = GlobalKey<ProfilesCarouselState>();
    await _pump(tester, carouselKey: key);
    final l10n = AppLocalizations.current;
    key.currentState!.startAdd();
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileNew), findsOneWidget);
    expect(find.text(l10n.addProfile), findsWidgets);
    expect(find.text(l10n.profileImportFile), findsOneWidget);

    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileNew), findsNothing);
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
