import 'package:flutter_test/flutter_test.dart';
import 'package:quanclash/common/dns_proxy_target.dart';
import 'package:quanclash/common/proxy_chain.dart';
import 'package:quanclash/models/proxy_chain.dart';

Map<String, dynamic> _baseConfig() {
  return {
    'proxies': [
      {
        'name': 'HK-01',
        'type': 'vless',
        'server': '1.1.1.1',
        'port': 443,
        'udp': true,
      },
      {
        'name': 'HK-02',
        'type': 'vless',
        'server': '1.1.1.2',
        'port': 443,
        'udp': true,
      },
      {
        'name': 'JP-NoUdp',
        'type': 'trojan',
        'server': '1.1.1.3',
        'port': 443,
        'udp': false,
      },
      {
        'name': 'US-Res-A',
        'type': 'ss',
        'server': '2.2.2.1',
        'port': 8388,
        'udp': true,
      },
      {
        'name': 'US-Res-B',
        'type': 'hysteria2',
        'server': '2.2.2.2',
        'port': 443,
      },
      {
        'name': 'DE-Dialed',
        'type': 'vless',
        'server': '3.3.3.1',
        'port': 443,
        'dialer-proxy': 'HK-01',
      },
    ],
    'proxy-groups': [
      {
        'name': 'Proxy',
        'type': 'select',
        'proxies': ['HK-01', 'HK-02'],
      },
    ],
    'rules': ['MATCH,Proxy'],
  };
}

void main() {
  group('applyProxyChains', () {
    test('generates static entry group and cloned exit group', () {
      const chain = ProxyChain(
        id: 1,
        profileId: 10,
        name: 'USHome',
        entry: ChainHop(
          type: ChainGroupType.urlTest,
          members: ['HK-01', 'HK-02'],
          tolerance: 40,
          interval: 180,
        ),
        exit: ChainHop(
          type: ChainGroupType.fallback,
          members: ['US-Res-A', 'US-Res-B'],
        ),
      );

      final result = applyProxyChains(_baseConfig(), [chain]);
      expect(result.hasErrors, isFalse);
      expect(result.activeChainGroupNames, ['USHome']);
      expect(result.matchSelectGroupName, 'Proxy');

      final proxies = (result.config['proxies'] as List)
          .cast<Map<String, dynamic>>();
      final exitCopyA = proxies.firstWhere(
        (p) => p['name'] == 'USHome / US-Res-A',
      );
      expect(exitCopyA['dialer-proxy'], 'USHome · 入口');
      expect(exitCopyA['server'], '2.2.2.1');

      final groups = (result.config['proxy-groups'] as List)
          .cast<Map<String, dynamic>>();
      final entryGroup = groups.firstWhere((g) => g['name'] == 'USHome · 入口');
      expect(entryGroup['type'], 'url-test');
      expect(entryGroup['hidden'], isTrue);
      expect(entryGroup['tolerance'], 40);
      expect(entryGroup['interval'], 180);
      expect(entryGroup['proxies'], ['HK-01', 'HK-02']);
      expect(entryGroup.containsKey('use'), isFalse);
      expect(entryGroup.containsKey('filter'), isFalse);
      expect(entryGroup.containsKey('include-all'), isFalse);

      final exitGroup = groups.firstWhere((g) => g['name'] == 'USHome');
      expect(exitGroup['type'], 'fallback');
      expect(exitGroup['proxies'], ['USHome / US-Res-A', 'USHome / US-Res-B']);

      final aggGroup = groups.firstWhere(
        (g) => g['name'] == chainAggregateGroupName,
      );
      expect(aggGroup['type'], 'select');
      expect(aggGroup['proxies'], ['USHome']);

      final matchGroup = groups.firstWhere((g) => g['name'] == 'Proxy');
      expect((matchGroup['proxies'] as List).first, 'USHome');

      // Strict DNS proxy target validation must accept the generated chain!
      final dnsErrors = validateDnsProxyTarget(result.config, 'USHome');
      expect(dnsErrors, isEmpty);

      // resolveActiveProxyChain matches both chain group name and cloned exit name.
      expect(
        resolveActiveProxyChain(
          [chain],
          proxyName: 'USHome / US-Res-A',
        )?.id,
        1,
      );
      expect(
        resolveActiveProxyChain(
          [chain],
          proxyName: 'HK-01',
        ),
        isNull,
      );
    });

    test('degrades single-node entry and single-node exit without extra groups', () {
      const chain = ProxyChain(
        id: 2,
        profileId: 10,
        name: 'JPOne',
        entry: ChainHop(members: ['HK-01']),
        exit: ChainHop(members: ['US-Res-A']),
      );

      final result = applyProxyChains(_baseConfig(), [chain]);
      expect(result.hasErrors, isFalse);

      final proxies = (result.config['proxies'] as List)
          .cast<Map<String, dynamic>>();
      final exitCopy = proxies.firstWhere((p) => p['name'] == 'JPOne');
      expect(exitCopy['dialer-proxy'], 'HK-01');

      final groups = (result.config['proxy-groups'] as List)
          .cast<Map<String, dynamic>>();
      expect(groups.any((g) => g['name'] == 'JPOne · 入口'), isFalse);
      expect(groups.any((g) => g['name'] == 'JPOne'), isFalse);

      expect(validateDnsProxyTarget(result.config, 'JPOne'), isEmpty);
    });

    test('rejects DIRECT, missing nodes, same node both sides, and existing dialer', () {
      const directChain = ProxyChain(
        id: 3,
        profileId: 10,
        name: 'BadDirect',
        entry: ChainHop(members: ['DIRECT']),
        exit: ChainHop(members: ['US-Res-A']),
      );
      const bothSidesChain = ProxyChain(
        id: 4,
        profileId: 10,
        name: 'BadBoth',
        entry: ChainHop(members: ['HK-01']),
        exit: ChainHop(members: ['HK-01']),
      );
      const missingChain = ProxyChain(
        id: 5,
        profileId: 10,
        name: 'BadMissing',
        entry: ChainHop(members: ['HK-01']),
        exit: ChainHop(members: ['DoesNotExist']),
      );
      const dialerChain = ProxyChain(
        id: 6,
        profileId: 10,
        name: 'BadDialer',
        entry: ChainHop(members: ['HK-02']),
        exit: ChainHop(members: ['DE-Dialed']),
      );

      final result = applyProxyChains(_baseConfig(), [
        directChain,
        bothSidesChain,
        missingChain,
        dialerChain,
      ]);

      expect(result.activeChainGroupNames, isEmpty);
      expect(
        result.issuesByChainId[3]!.map((i) => i.code),
        contains(ChainIssueCode.builtinMember),
      );
      expect(
        result.issuesByChainId[4]!.map((i) => i.code),
        contains(ChainIssueCode.nodeBothSides),
      );
      expect(
        result.issuesByChainId[5]!.map((i) => i.code),
        contains(ChainIssueCode.missingNode),
      );
      expect(
        result.issuesByChainId[6]!.map((i) => i.code),
        contains(ChainIssueCode.exitHasDialer),
      );
    });

    test('emits non-blocking warning for QUIC exit with non-UDP entry', () {
      const chain = ProxyChain(
        id: 7,
        profileId: 10,
        name: 'QuicWarn',
        entry: ChainHop(members: ['JP-NoUdp']),
        exit: ChainHop(members: ['US-Res-B']),
      );

      final result = applyProxyChains(_baseConfig(), [chain]);
      expect(result.hasErrors, isFalse);
      expect(result.activeChainGroupNames, ['QuicWarn']);
      expect(
        result.issues.any(
          (i) => i.isWarning && i.code == ChainIssueCode.udpQuicMismatch,
        ),
        isTrue,
      );
    });

    test('rejects provider source under strictDns and respects chainsEnabled=false', () {
      const providerChain = ProxyChain(
        id: 8,
        profileId: 10,
        name: 'SubChain',
        entry: ChainHop(members: ['HK-01']),
        exit: ChainHop(members: ['US-Res-A']),
        sourceType: ChainSourceType.provider,
      );

      final strictRes = applyProxyChains(
        _baseConfig(),
        [providerChain],
        strictDns: true,
      );
      expect(strictRes.hasErrors, isTrue);
      expect(
        strictRes.issues.map((i) => i.code),
        contains(ChainIssueCode.providerNodeStrict),
      );

      final disabledRes = applyProxyChains(
        _baseConfig(),
        [
          const ProxyChain(
            id: 9,
            profileId: 10,
            name: 'Off',
            entry: ChainHop(members: ['HK-01']),
            exit: ChainHop(members: ['US-Res-A']),
          ),
        ],
        chainsEnabled: false,
      );
      expect(disabledRes.activeChainGroupNames, isEmpty);
      expect(disabledRes.issues, isEmpty);
    });

    test('rejects urlTest on exit group', () {
      const chain = ProxyChain(
        id: 10,
        profileId: 10,
        name: 'BadExitType',
        entry: ChainHop(members: ['HK-01']),
        exit: ChainHop(
          type: ChainGroupType.urlTest,
          members: ['US-Res-A', 'US-Res-B'],
        ),
      );
      final result = applyProxyChains(_baseConfig(), [chain]);
      expect(result.hasErrors, isTrue);
      expect(
        result.issues.map((i) => i.code),
        contains(ChainIssueCode.invalidExitType),
      );
    });
  });
}
