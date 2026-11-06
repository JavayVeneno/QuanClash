import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/proxies/grouping.dart';
import 'package:flutter_test/flutter_test.dart';

Proxy _proxy(String name) => Proxy(name: name, type: 'Vmess');

void main() {
  group('provider info detection', () {
    test('recognises subscription notices', () {
      expect(isProviderInfoProxyName('官网地址: 45.130.147.44 或者 43.203.193.0'), isTrue);
      expect(isProviderInfoProxyName('联系邮箱: s8ksus@gmail.com'), isTrue);
      expect(isProviderInfoProxyName('有问题可邮件联系客服'), isTrue);
      expect(isProviderInfoProxyName('回家节点-会员过期后无法打开官网时使用'), isTrue);
      expect(isProviderInfoProxyName('续费地址: 156.238.122.14'), isTrue);
      expect(isProviderInfoProxyName('官网地址: go.chuyun.us 或者 a1.s8ks.org'), isTrue);
      expect(isProviderInfoProxyName('https://example.com/notice'), isTrue);
    });

    test('keeps real nodes and pseudo adapters', () {
      expect(isProviderInfoProxyName('香港A2'), isFalse);
      expect(isProviderInfoProxyName('日本A4-原生'), isFalse);
      expect(isProviderInfoProxyName('新加坡-IPV6直连-电信优化'), isFalse);
      expect(isProviderInfoProxyName('DIRECT'), isFalse);
      expect(isProviderInfoProxyName('REJECT'), isFalse);
    });
  });

  group('region detection', () {
    test('maps common node names', () {
      expect(regionOfProxyName('香港A2')?.id, 'hk');
      expect(regionOfProxyName('香港A5>HKBn家宽')?.id, 'hk');
      expect(regionOfProxyName('新加坡-IPV6直连-电信优化')?.id, 'sg');
      expect(regionOfProxyName('澳门-IPV6直连')?.id, 'mo');
      expect(regionOfProxyName('日本A3')?.id, 'jp');
      expect(regionOfProxyName('台湾-IPV6直连')?.id, 'tw');
      expect(regionOfProxyName('HKG 01')?.id, 'hk');
      expect(regionOfProxyName('US-01')?.id, 'us');
    });

    test('does not match two-letter codes inside words', () {
      expect(regionOfProxyName('Russia')?.id, 'ru');
      expect(regionOfProxyName('Australia')?.id, 'au');
      expect(regionOfProxyName('Node')?.id, isNull);
    });
  });

  group('sections', () {
    final now = DateTime(2026, 11, 5, 12);
    final proxies = [
      _proxy('香港A1'),
      _proxy('香港A2'),
      _proxy('日本A1'),
      _proxy('官网地址: example.com'),
    ];

    test('all mode keeps a single flat section', () {
      final sections = buildProxySections(
        proxies: proxies,
        mode: ProxiesGroupMode.all,
        usage: const {},
        otherRegionLabel: 'Other',
        recentLabel: 'Recent',
        frequentLabel: 'Frequent',
        providerInfoLabel: 'Provider info',
        now: now,
      );
      expect(sections, hasLength(1));
      expect(sections.single.title, isNull);
      expect(sections.single.proxies, proxies);
    });

    test('region mode groups, orders by count and hides provider info', () {
      final sections = buildProxySections(
        proxies: proxies,
        mode: ProxiesGroupMode.region,
        usage: {
          '香港A1': NodeUsageEntry(
            count: 3,
            lastUsed: now.subtract(const Duration(hours: 1)),
          ),
          '日本A1': NodeUsageEntry(
            count: 2,
            lastUsed: now.subtract(const Duration(days: 30)),
          ),
        },
        otherRegionLabel: 'Other',
        recentLabel: 'Recent',
        frequentLabel: 'Frequent',
        providerInfoLabel: 'Provider info',
        now: now,
      );
      expect(sections.map((section) => section.id).toList(), [
        'recent',
        'frequent',
        'region:hk',
        'region:jp',
        'provider-info',
      ]);
      expect(sections[0].proxies.map((proxy) => proxy.name), ['香港A1']);
      expect(sections[1].proxies.map((proxy) => proxy.name), ['日本A1']);
      expect(sections[2].proxies, hasLength(2));
      expect(sections[3].proxies.single.name, '日本A1');
      final info = sections.last;
      expect(info.collapsible, isTrue);
      expect(info.expandedByDefault, isFalse);
      expect(info.proxies.single.name, '官网地址: example.com');
    });

    test('group references are never treated as provider info', () {
      final sections = buildProxySections(
        proxies: const [Proxy(name: '国外流量', type: 'Selector')],
        mode: ProxiesGroupMode.region,
        usage: const {},
        otherRegionLabel: 'Other',
        recentLabel: 'Recent',
        frequentLabel: 'Frequent',
        providerInfoLabel: 'Provider info',
        now: now,
      );
      expect(sections.any((section) => section.id == 'provider-info'), isFalse);
      expect(sections.single.proxies.single.name, '国外流量');
    });

    test('unknown names fall into the other-region bucket', () {
      final sections = buildProxySections(
        proxies: [_proxy('Unknown Node')],
        mode: ProxiesGroupMode.region,
        usage: const {},
        otherRegionLabel: 'Other',
        recentLabel: 'Recent',
        frequentLabel: 'Frequent',
        providerInfoLabel: 'Provider info',
        now: now,
      );
      expect(sections, hasLength(1));
      expect(sections.single.id, 'region:other');
      expect(sections.single.title, 'Other');
    });
  });
}
