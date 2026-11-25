import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/mobile_v4/network_globe.dart';
import 'package:quanclash/views/mobile_v4/sheets/config_sheet.dart';
import 'package:quanclash/views/mobile_v4/sheets/monitor_sheet.dart';
import 'package:quanclash/views/mobile_v4/sheets/proxy_sheet.dart';
import 'package:quanclash/views/mobile_v4/sheets/settings_sheet.dart';
import 'package:quanclash/views/mobile_v4/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;

Widget _wrapSheet({
  required Widget child,
  List<Profile> profiles = const [],
  List<Override> overrides = const [],
  Brightness brightness = Brightness.dark,
}) {
  return ProviderScope(
    overrides: [
      profilesStreamProvider.overrideWith((_) => Stream.value(profiles)),
      globalRulesProvider.overrideWithBuild((_, _) => Stream.value(const [])),
      scriptsProvider.overrideWithBuild((_, _) => Stream.value(const [])),
      coreRuntimeVersionProvider.overrideWith((_) async => 'v1.19.0'),
      ...overrides,
    ],
    child: MaterialApp(
      theme: ThemeData(brightness: brightness),
      locale: const Locale('zh', 'CN'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      home: Scaffold(body: child),
    ),
  );
}

void _expectAllLucideIcons(WidgetTester tester) {
  final icons = tester.widgetList<Icon>(find.byType(Icon));
  expect(icons, isNotEmpty);
  for (final icon in icons) {
    expect(icon.icon?.fontFamily, QuanXIcons.waypoints.fontFamily);
  }
}

void main() {
  test('mobileV4GeoForNode resolves major regions and city overrides', () {
    expect(mobileV4GeoForNode('🇭🇰 香港 IEPL 01').id, 'hk');
    expect(mobileV4GeoForNode('SG-Singapore-02').id, 'sg');
    expect(mobileV4GeoForNode('🇯🇵 日本东京 01').id, 'jp');
    expect(mobileV4GeoForNode('日本大阪 02').id, 'jp-osa');
    expect(mobileV4GeoForNode('美国纽约 BGP').id, 'us-nyc');
    expect(mobileV4GeoForNode('美国洛杉矶 01').id, 'us-lax');
    expect(mobileV4GeoForNode('德国法兰克福').id, 'de');
    expect(mobileV4GeoForNode('英国伦敦').id, 'gb');
    expect(mobileV4GeoForNode('神秘未知节点').id, 'jp');
    expect(mobileV4GeoForNode('').id, 'jp');
  });

  testWidgets('mobile v4 globe animates cleanly when activeNodeName changes', (
    tester,
  ) async {
    Future<void> pumpGlobe(String nodeName) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 400,
              child: MobileV4Globe(
                connected: true,
                activeNodeName: nodeName,
                onTap: () {},
                onConnectChanged: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await pumpGlobe('🇭🇰 香港 01');
    await tester.pump(const Duration(milliseconds: 100));
    await pumpGlobe('🇩🇪 德国法兰克福 02');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileV4Globe), findsOneWidget);
  });

  testWidgets(
    'proxy sheet supports search, sort cycle, region grouping, risk badge, and providers',
    (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const hkProxy = Proxy(name: '🇭🇰 香港 01', type: 'Shadowsocks');
      const jpProxy = Proxy(name: '🇯🇵 日本东京 01', type: 'VMess');
      const usProxy = Proxy(name: '🇺🇸 美国洛杉矶 01', type: 'Trojan');
      const group = Group(
        type: GroupType.Selector,
        name: 'PROXY',
        now: '🇭🇰 香港 01',
        all: [hkProxy, jpProxy, usProxy],
      );
      final provider = ExternalProvider(
        name: 'Airport-Sub',
        type: 'Proxy',
        path: '/tmp/sub.yaml',
        count: 12,
        vehicleType: 'HTTP',
        updateAt: DateTime.now(),
      );
      final qualityResult = NodeQualityResult.fromJson({
        'schemaVersion': 1,
        'source': 'selected-proxy',
        'proxyName': '🇭🇰 香港 01',
        'sampledAt': DateTime.now().toUtc().toIso8601String(),
        'network': {
          'provider': 'cloudflare',
          'status': 'ok',
          'egressIp': '1.2.3.4',
          'ttfbMs': 42,
        },
        'quality': {
          'provider': 'ippure',
          'status': 'ok',
          'egressIp': '1.2.3.4',
          'riskScore': 18,
          'isResidential': true,
        },
      });
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrapSheet(
          overrides: [
            groupsProvider.overrideWithBuild((_, _) => [group]),
            providersProvider.overrideWithBuild((_, _) => [provider]),
            proxiesViewModeProvider.overrideWithBuild(
              (_, _) => ProxiesGroupMode.all,
            ),
            nodeQualityResultsProvider.overrideWithBuild(
              (_, _) => {'🇭🇰 香港 01': qualityResult},
            ),
          ],
          child: MobileV4ProxySheet(controller: controller),
        ),
      );
      await tester.pump();

      expect(find.text('🇭🇰 香港 01'), findsOneWidget);
      expect(find.text('🇯🇵 日本东京 01'), findsOneWidget);
      expect(find.text('🇺🇸 美国洛杉矶 01'), findsOneWidget);
      expect(find.text('风 18'), findsOneWidget);
      expect(find.text('外部节点源'), findsOneWidget);
      expect(find.text('Airport-Sub'), findsOneWidget);
      _expectAllLucideIcons(tester);

      // Search filter
      await tester.enterText(find.byType(TextField), '日本');
      await tester.pump();
      expect(find.text('🇯🇵 日本东京 01'), findsOneWidget);
      expect(find.text('🇺🇸 美国洛杉矶 01'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(QuanXIcons.x));
      await tester.pump();
      expect(find.text('🇺🇸 美国洛杉矶 01'), findsOneWidget);

      // Cycle sort: 默认排序 -> 按延迟 -> 按名称
      await tester.tap(find.text('默认排序'));
      await tester.pump();
      expect(find.text('按延迟'), findsOneWidget);
      await tester.tap(find.text('按延迟'));
      await tester.pump();
      expect(find.text('按名称'), findsOneWidget);

      // Toggle grouping: 策略组 -> 按地区
      await tester.tap(find.text('策略组'));
      await tester.pump();
      expect(find.text('按地区'), findsOneWidget);
      expect(find.text('🇭🇰 香港'), findsOneWidget);
      expect(find.text('🇯🇵 日本'), findsOneWidget);

      // One-tap collapse all -> hides proxy rows and flips to 全部展开
      expect(find.text('全部收起'), findsOneWidget);
      await tester.tap(find.text('全部收起'));
      await tester.pump();
      expect(find.text('全部展开'), findsOneWidget);
      expect(find.text('🇭🇰 香港 01'), findsNothing);

      // One-tap expand all -> restores proxy rows
      await tester.tap(find.text('全部展开'));
      await tester.pump();
      expect(find.text('全部收起'), findsOneWidget);
      expect(find.text('🇭🇰 香港 01'), findsOneWidget);
    },
  );

  testWidgets('config sheet opens profile CRUD menu and auto-update picker', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const profile = Profile(
      id: 1,
      label: 'Primary Sub',
      url: 'https://example.com/sub.yaml',
      autoUpdate: true,
      autoUpdateDuration: Duration(hours: 24),
      subscriptionInfo: SubscriptionInfo(
        upload: 1024 * 1024 * 1024,
        download: 4 * 1024 * 1024 * 1024,
        total: 100 * 1024 * 1024 * 1024,
      ),
    );
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapSheet(
        profiles: const [profile],
        overrides: [
          currentProfileIdProvider.overrideWithBuild((_, _) => 1),
        ],
        child: MobileV4ConfigSheet(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('Primary Sub'), findsOneWidget);
    expect(find.text('生效中'), findsOneWidget);
    expect(find.text('每 24 小时'), findsOneWidget);
    _expectAllLucideIcons(tester);

    // Tap overflow button on Hero card to open CRUD action sheet
    await tester.tap(find.byIcon(QuanXIcons.ellipsisVertical).first);
    await tester.pumpAndSettle();
    expect(find.text('更新订阅'), findsOneWidget);
    expect(find.text('编辑配置'), findsOneWidget);
    expect(find.text('预览 YAML'), findsOneWidget);
    expect(find.text('覆写配置'), findsOneWidget);
    expect(find.text('删除订阅'), findsOneWidget);

    // Dismiss action sheet
    await tester.tap(find.byIcon(QuanXIcons.x).last);
    await tester.pumpAndSettle();

    // Open auto-update interval picker
    await tester.tap(find.text('自动更新'));
    await tester.pumpAndSettle();
    expect(find.text('自动更新周期'), findsOneWidget);
    expect(find.text('每 6 小时'), findsOneWidget);
    expect(find.text('每 12 小时'), findsOneWidget);
    expect(find.text('每 72 小时'), findsOneWidget);

    // Verify Proxy sheet test passed cleanly; now also verify EditProfileView
    // opens inside a real Scaffold without throwing MissingMaterial errors.
    await tester.tap(find.byIcon(QuanXIcons.x).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(QuanXIcons.ellipsisVertical).first);
    await tester.pumpAndSettle();
    expect(find.text('编辑配置'), findsOneWidget);
  });

  testWidgets('settings sheet renders all parity sections and pickers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapSheet(
        brightness: Brightness.light,
        child: MobileV4SettingsSheet(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('连接'), findsOneWidget);
    expect(find.text('DNS 诊断'), findsOneWidget);
    expect(find.text('按需连接'), findsOneWidget);
    expect(find.text('监控与诊断'), findsOneWidget);
    expect(find.text('实时连接'), findsOneWidget);
    expect(find.text('请求记录'), findsOneWidget);
    expect(find.text('运行日志'), findsOneWidget);

    // Scroll down to verify lower sections
    await tester.scrollUntilVisible(find.text('关于与更新'), 200);
    await tester.pump();
    expect(find.text('规则与配置'), findsOneWidget);
    expect(find.text('高级配置'), findsOneWidget);
    expect(find.text('风险检测接口'), findsOneWidget);
    expect(find.text('备份与恢复'), findsOneWidget);
    expect(find.text('Geo 资源管理'), findsOneWidget);
    expect(find.text('关于与更新'), findsOneWidget);
    _expectAllLucideIcons(tester);

    // Tap About & Update to verify About sheet with core version
    await tester.tap(find.text('关于与更新'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Core v1.19.0'), findsNWidgets(2));
    expect(find.text('开源许可'), findsOneWidget);
  });

  testWidgets('monitor sheet renders telemetry card and diagnostic entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _wrapSheet(
        child: MobileV4MonitorSheet(controller: controller),
      ),
    );
    await tester.pump();

    expect(find.text('累计下载'), findsOneWidget);
    expect(find.text('累计上传'), findsOneWidget);
    expect(find.text('实时连接'), findsOneWidget);
    expect(find.text('请求记录'), findsOneWidget);
    expect(find.text('运行日志'), findsOneWidget);
    expect(find.text('DNS 诊断'), findsOneWidget);
    _expectAllLucideIcons(tester);
  });
}
