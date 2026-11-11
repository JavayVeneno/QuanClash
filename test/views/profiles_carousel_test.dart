import 'package:quanclash/common/measure.dart';
import 'package:quanclash/common/theme.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/profiles/profiles.dart';
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

/// 卡片堆叠里某张后排卡片露出的顶部边缘（考虑缩放后的视觉上沿）。
double _exposedEdgeY(WidgetTester tester, int id, double scale) {
  final key = ValueKey('profile-card-$id');
  final topLeft = tester.getTopLeft(find.byKey(key));
  final size = tester.getSize(find.byKey(key));
  return topLeft.dy + size.height * (1 - scale) / 2 + 6;
}

void main() {
  testWidgets('shows active summary and toggles details on tap', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text(l10n.profileActive), findsOneWidget);
    expect(find.text(l10n.profileRemainingTraffic), findsWidgets);

    expect(find.text(l10n.profileSubscriptionUrl), findsOneWidget);
    expect(find.text(l10n.profileNodeCount), findsOneWidget);
    expect(find.text(l10n.profileCurrentConfig), findsOneWidget);
    expect(find.text(l10n.profileCollapse), findsOneWidget);

    await tester.tap(_cardText(1, l10n.profileCollapse));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileSubscriptionUrl), findsNothing);
    expect(find.text(l10n.profileTapToExpand), findsOneWidget);

    await tester.tap(_cardText(1, l10n.profileTapToExpand));
    await tester.pumpAndSettle();
    expect(find.text(l10n.profileSubscriptionUrl), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clicking the exposed stack edge brings a card to front', (
    tester,
  ) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;

    // 第二张卡片（缩放 0.96）露出的顶部区域。
    await tester.tapAt(Offset(700, _exposedEdgeY(tester, 2, 0.96)));
    await tester.pumpAndSettle();
    expect(_cardText(2, l10n.profileCollapse), findsOneWidget);
    expect(_cardText(1, l10n.profileCollapse), findsNothing);

    // 当前卡片换位后，Alpha 落到第三层（缩放 0.88），点它的露出边。
    await tester.tapAt(Offset(700, _exposedEdgeY(tester, 1, 0.88)));
    await tester.pumpAndSettle();
    expect(_cardText(1, l10n.profileCollapse), findsOneWidget);

    await tester.tapAt(Offset(700, _exposedEdgeY(tester, 4, 0.88)));
    await tester.pumpAndSettle();
    expect(_cardText(4, l10n.profileCollapse), findsOneWidget);
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
    expect(find.text(l10n.profileCollapse), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('subscription URL is masked until revealed', (tester) async {
    await _pump(tester);
    final l10n = AppLocalizations.current;
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
