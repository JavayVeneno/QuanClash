import 'dart:convert';

import 'package:fl_clash/common/dns_config.dart';
import 'package:fl_clash/common/task.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _patchDns = Dns(
  nameserver: ['https://dns.example/dns-query'],
  nameserverPolicy: {
    '+.example.com': 'https://one.example/dns-query; tls://1.1.1.1',
    '+.internal': '10.0.0.1',
  },
  fallback: [],
  defaultNameserver: ['9.9.9.9'],
  proxyServerNameserver: ['tls://1.1.1.1'],
);

void main() {
  group('Effective DNS config', () {
    for (final profileDns in <Map?>[
      null,
      {},
      {
        'enable': false,
        'nameserver': ['system://'],
      },
    ]) {
      for (final overrideDns in [false, true]) {
        test(
          'uses patch without implicit system DNS: $profileDns/$overrideDns',
          () {
            final result = _buildDns(
              profileDns: profileDns,
              patchDns: _patchDns,
              overrideDns: overrideDns,
              appendSystemDns: false,
            );
            final dns = result.config;
            expect(result.errors, isEmpty);
            expect(dns['nameserver'], _patchDns.nameserver);
            expect(dns['enable'], true);
            expect(dns['fallback-filter'], isA<Map>());
            expect(dns['nameserver-policy'], {
              '+.example.com': [
                'https://one.example/dns-query',
                'tls://1.1.1.1',
              ],
              '+.internal': '10.0.0.1',
            });
          },
        );
      }
    }

    test('preserves enabled subscription DNS, including advanced fields', () {
      final profileDns = {
        'enable': true,
        'respect-rules': true,
        'nameserver': ['https://dns.example/dns-query#proxy-a'],
        'nameserver-policy': {
          '+.internal': ['system://'],
        },
        'proxy-server-nameserver': ['tls://1.1.1.1'],
        'proxy-server-nameserver-policy': {'node.example': 'tls://8.8.8.8'},
        'direct-nameserver': ['10.0.0.1'],
        'cache-max-size': 2048,
        'fake-ip-filter-mode': 'rule',
      };
      final before = jsonEncode(profileDns);
      final result = _buildDns(
        profileDns: profileDns,
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
      );
      final dns = result.config;
      expect(dns, profileDns);
      (dns['nameserver'] as List).add('tls://8.8.8.8');
      (dns['nameserver-policy']['+.internal'] as List).clear();
      expect(jsonEncode(profileDns), before);
    });

    test(
      'DNS override replaces subscription fields instead of merging policies',
      () {
        final dns = _buildDns(
          profileDns: {
            'enable': true,
            'nameserver': ['system://'],
            'nameserver-policy': {'+.example': 'system://'},
            'direct-nameserver': ['system://'],
          },
          patchDns: _patchDns.copyWith(respectRules: true),
          overrideDns: true,
          appendSystemDns: false,
        ).config;
        expect(dns['nameserver'], _patchDns.nameserver);
        expect(dns['respect-rules'], true);
        expect(dns['proxy-server-nameserver'], _patchDns.proxyServerNameserver);
        expect(dns.containsKey('direct-nameserver'), false);
        expect(dns['nameserver-policy'], isNot(contains('+.example')));
      },
    );

    for (final overrideDns in [false, true]) {
      test('system DNS is appended only on explicit opt-in: $overrideDns', () {
        final dns = _buildDns(
          profileDns: {
            'enable': true,
            'nameserver': ['tls://1.1.1.1'],
          },
          patchDns: _patchDns,
          overrideDns: overrideDns,
          appendSystemDns: true,
        ).config;
        expect(dns['nameserver'], [
          if (overrideDns) ..._patchDns.nameserver else 'tls://1.1.1.1',
          systemDnsNameserver,
        ]);
      });
    }

    for (final systemServer in [
      'system://',
      'system',
      'system://#proxy-a',
      'dhcp://system',
    ]) {
      test(
        'does not duplicate an explicit system DNS alias: $systemServer',
        () {
          final dns = _buildDns(
            profileDns: {
              'enable': true,
              'nameserver': ['tls://1.1.1.1', systemServer],
            },
            patchDns: _patchDns,
            overrideDns: false,
            appendSystemDns: true,
          ).config;
          expect(dns['nameserver'], ['tls://1.1.1.1', systemServer]);
        },
      );
    }

    test('keeps an explicit system server in custom patch DNS', () {
      final dns = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(nameserver: ['system://']),
        overrideDns: false,
        appendSystemDns: false,
      ).config;
      expect(dns['nameserver'], ['system://']);
    });

    test('keeps disabled patch DNS disabled without injecting resolvers', () {
      final dns = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(enable: false),
        overrideDns: false,
        appendSystemDns: false,
      ).config;
      expect(dns['enable'], false);
      expect(dns['nameserver'], _patchDns.nameserver);
    });

    test('repeated compilation cannot mutate the patch DNS lists', () {
      final original = jsonEncode(_patchDns);
      final first = _buildDns(
        profileDns: null,
        patchDns: _patchDns,
        overrideDns: true,
        appendSystemDns: true,
      ).config;
      final second = _buildDns(
        profileDns: null,
        patchDns: _patchDns,
        overrideDns: true,
        appendSystemDns: false,
      ).config;
      expect(first['nameserver'], contains('system://'));
      expect(second['nameserver'], isNot(contains('system://')));
      expect(jsonEncode(_patchDns), original);
    });
  });

  group('DNS safety modes', () {
    test(
      'proxy-only preserves spaces and Unicode in validated group names',
      () {
        for (final target in ['DNS Group', '\u4ee3\u7406']) {
          final result = buildEffectiveDnsConfig(
            profileDns: null,
            patchDns: _patchDns,
            overrideDns: true,
            appendSystemDns: false,
            safetyMode: DnsSafetyMode.proxyOnly,
            proxyTarget: target,
            proxyConfig: {
              ..._proxyConfig,
              'proxy-groups': [
                {
                  'name': target,
                  'type': 'select',
                  'proxies': ['node'],
                },
              ],
            },
          );
          expect(result.errors, isEmpty);
          final servers = result.config['nameserver'] as List;
          final server = servers.single as String;
          expect(Uri.decodeComponent(Uri.parse(server).fragment), target);
          final again = buildEffectiveDnsConfig(
            profileDns: result.config,
            patchDns: _patchDns,
            overrideDns: false,
            appendSystemDns: false,
            safetyMode: DnsSafetyMode.proxyOnly,
            proxyTarget: target,
            proxyConfig: {
              ..._proxyConfig,
              'proxy-groups': [
                {
                  'name': target,
                  'type': 'select',
                  'proxies': ['node'],
                },
              ],
            },
          );
          expect(again.errors, isEmpty);
          expect(again.config['nameserver'], [server]);
        }
      },
    );

    test('proxy-only refuses implicit bootstrap inheritance', () {
      final result = buildEffectiveDnsConfig(
        profileDns: {
          'enable': true,
          'nameserver': ['tls://8.8.8.8'],
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
        proxyConfig: _proxyConfig,
      );
      expect(
        result.errors,
        containsAll([
          'dns-default-nameserver-missing',
          'dns-proxy-server-nameserver-missing',
        ]),
      );
    });

    test(
      'proxy-only accepts bracketed IPv6 without losing its proxy route',
      () {
        final result = _buildDns(
          profileDns: {
            'enable': true,
            'nameserver': [
              '2001:4860:4860::8888',
              'tls://[2606:4700:4700::1111]',
            ],
            'default-nameserver': ['2001:4860:4860::8888'],
            'proxy-server-nameserver': ['tls://[2606:4700:4700::1111]'],
          },
          patchDns: _patchDns,
          overrideDns: false,
          appendSystemDns: false,
          safetyMode: DnsSafetyMode.proxyOnly,
          proxyTarget: 'PROXY',
        );
        expect(result.errors, isEmpty);
        expect(result.config['nameserver'], [
          'udp://[2001:4860:4860::8888]#PROXY',
          'tls://[2606:4700:4700::1111]#PROXY',
        ]);
      },
    );

    test(
      'proxy-only rejects malformed, overlay and last-fragment bypasses',
      () {
        for (final server in [
          'tls://1.1.1.1#PROXY&DIRECT',
          'tls://1.1.1.1#PROXY&OtherGroup',
          'tls://1.1.1.1#%44IRECT',
          'tls://1.1.1.1#OtherGroup',
          'ts://overlay#PROXY',
          'et://overlay#PROXY',
          'tls://[invalid',
        ]) {
          final result = _buildDns(
            profileDns: {
              'enable': true,
              'nameserver': [server],
            },
            patchDns: _patchDns,
            overrideDns: false,
            appendSystemDns: false,
            safetyMode: DnsSafetyMode.proxyOnly,
            proxyTarget: 'PROXY',
          );
          expect(result.errors, isNotEmpty, reason: server);
        }
      },
    );

    test('proxy-only validates shapes instead of silently skipping fields', () {
      for (final fields in [
        {'nameserver': 'system'},
        {
          'nameserver-policy': {
            '+.internal': ['system'],
          },
        },
        {
          'fallback': [false],
        },
        {
          'direct-nameserver': ['system://'],
        },
        {
          'proxy-server-nameserver-policy': {'node.example': 'dhcp://Ethernet'},
        },
        {
          'proxy-server-nameserver': ['tls://1.1.1.1#PROXY'],
        },
      ]) {
        final result = _buildDns(
          profileDns: {
            'enable': true,
            'nameserver': ['tls://1.1.1.1'],
            ...fields,
          },
          patchDns: _patchDns,
          overrideDns: false,
          appendSystemDns: false,
          safetyMode: DnsSafetyMode.proxyOnly,
          proxyTarget: 'PROXY',
        );
        expect(result.errors, isNotEmpty, reason: '$fields');
      }
    });

    test('proxy-only rejects target-fragment injection', () {
      for (final target in [
        'PROXY&DIRECT',
        'PROXY#x',
        'PROXY=h3',
        'PROXY%20',
      ]) {
        final result = _buildDns(
          profileDns: null,
          patchDns: _patchDns,
          overrideDns: true,
          appendSystemDns: false,
          safetyMode: DnsSafetyMode.proxyOnly,
          proxyTarget: target,
        );
        expect(result.errors, contains('dns-proxy-target-invalid-fragment'));
      }
    });

    test('proxy-only pins ordinary resolvers and keeps bootstrap direct', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(
          nameserverPolicy: {
            '+.example.com': 'https://one.example/dns-query',
            '+.blocked': 'rcode://success',
          },
          proxyServerNameserver: ['tls://1.1.1.1'],
        ),
        overrideDns: true,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, isEmpty);
      expect(result.config['nameserver'], [
        'https://dns.example/dns-query#PROXY',
      ]);
      expect(result.config['nameserver-policy'], {
        '+.example.com': ['https://one.example/dns-query#PROXY'],
        '+.blocked': ['rcode://success'],
      });
      expect(result.config['proxy-server-nameserver'], ['tls://1.1.1.1']);
      expect(result.warnings, isNot(contains('dns-direct-nameserver-present')));
    });

    test('proxy-only keeps the validated explicit proxy fragment', () {
      final result = _buildDns(
        profileDns: {
          'enable': true,
          'nameserver': ['tls://8.8.8.8#PROXY', '1.1.1.1'],
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, isEmpty);
      expect(result.config['nameserver'], [
        'tls://8.8.8.8#PROXY',
        'udp://1.1.1.1#PROXY',
      ]);
    });

    test('proxy-only rejects a direct fragment', () {
      final result = _buildDns(
        profileDns: {
          'enable': true,
          'nameserver': ['tls://8.8.8.8#DIRECT'],
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, contains('dns-nameserver-direct-path'));
    });

    test('proxy-only keeps resolver parameters when adding a target', () {
      final result = _buildDns(
        profileDns: {
          'enable': true,
          'nameserver': [
            'https://dns.example/dns-query#&h3=true',
            'https://other.example/dns-query#PROXY&h3=true',
          ],
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, isEmpty);
      expect(result.config['nameserver'], [
        'https://dns.example/dns-query#PROXY&h3=true',
        'https://other.example/dns-query#PROXY&h3=true',
      ]);
    });

    test('proxy-only rejects an appended system resolver', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: true,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, contains('dns-nameserver-system-resolver'));
      expect(result.warnings, contains('dns-system-dns-appended'));
    });

    test('proxy-only rejects respect-rules', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(respectRules: true),
        overrideDns: true,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, contains('dns-respect-rules-not-strict'));
    });

    test('proxy-only requires a proxy target', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns,
        overrideDns: true,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
      );
      expect(result.errors, contains('dns-proxy-target-required'));
      expect(result.config['nameserver'], _patchDns.nameserver);
    });

    test('proxy-only rejects reserved proxy targets', () {
      for (final target in ['DIRECT', 'reject', 'Compatible']) {
        final result = _buildDns(
          profileDns: null,
          patchDns: _patchDns,
          overrideDns: true,
          appendSystemDns: false,
          safetyMode: DnsSafetyMode.proxyOnly,
          proxyTarget: target,
        );
        expect(
          result.errors,
          contains('dns-proxy-target-reserved'),
          reason: target,
        );
      }
    });

    test('proxy-only rejects a bootstrap policy without a resolver', () {
      final result = _buildDns(
        profileDns: {
          'enable': true,
          'nameserver': ['tls://8.8.8.8'],
          'default-nameserver': ['223.5.5.5'],
          'proxy-server-nameserver': [],
          'proxy-server-nameserver-policy': {'node.example': 'tls://1.1.1.1'},
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, contains('dns-proxy-server-nameserver-missing'));
    });

    test('proxy-only rejects a non-IP bootstrap host', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(
          proxyServerNameserver: ['https://doh.pub/dns-query'],
        ),
        overrideDns: true,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(
        result.errors,
        contains('dns-proxy-server-nameserver-not-ip-literal'),
      );
    });

    test('proxy-only rejects a system bootstrap resolver', () {
      final result = _buildDns(
        profileDns: null,
        patchDns: _patchDns.copyWith(
          proxyServerNameserver: ['system://'],
          defaultNameserver: ['223.5.5.5'],
        ),
        overrideDns: true,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(
        result.errors,
        contains('dns-proxy-server-nameserver-invalid-bootstrap'),
      );
    });

    test('compatible and custom never rewrite resolvers', () {
      for (final mode in [DnsSafetyMode.compatible, DnsSafetyMode.custom]) {
        final result = _buildDns(
          profileDns: {
            'enable': true,
            'nameserver': ['system://', 'tls://8.8.8.8'],
          },
          patchDns: _patchDns,
          overrideDns: false,
          appendSystemDns: false,
          safetyMode: mode,
          proxyTarget: 'PROXY',
        );
        expect(result.errors, isEmpty, reason: '$mode');
        expect(result.config['nameserver'], [
          'system://',
          'tls://8.8.8.8',
        ], reason: '$mode');
      }
    });

    test('proxy-only pins direct-traffic resolvers as well', () {
      final result = _buildDns(
        profileDns: {
          'enable': true,
          'nameserver': ['tls://8.8.8.8'],
          'direct-nameserver': ['10.0.0.1'],
        },
        patchDns: _patchDns,
        overrideDns: false,
        appendSystemDns: false,
        safetyMode: DnsSafetyMode.proxyOnly,
        proxyTarget: 'PROXY',
      );
      expect(result.errors, isEmpty);
      expect(result.config['direct-nameserver'], ['udp://10.0.0.1#PROXY']);
    });
  });

  group('Generated profile YAML', () {
    test('proxy-only mode pins resolvers in the generated profile', () async {
      final result = await makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '/profiles',
          profileId: 1,
          rawConfig: {
            ..._proxyConfig,
            'rules': ['MATCH,DIRECT'],
          },
          realPatchConfig: PatchClashConfig(
            dns: _patchDns.copyWith(proxyServerNameserver: ['tls://1.1.1.1']),
          ),
          overrideDns: true,
          appendSystemDns: false,
          dnsSafetyMode: DnsSafetyMode.proxyOnly,
          dnsProxyTarget: 'PROXY',
          proxyGroups: [],
          rules: [],
          addedRules: [],
          defaultUA: 'QuanClash-Test',
        ),
      );
      expect(result.dnsErrors, isEmpty);
      final config = loadYaml(result.yaml) as YamlMap;
      final dns = config['dns'] as YamlMap;
      expect(dns['nameserver'], ['https://dns.example/dns-query#PROXY']);
    });

    test('proxy-only failure returns blocking errors', () async {
      final result = await makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '/profiles',
          profileId: 1,
          rawConfig: {
            ..._proxyConfig,
            'rules': ['MATCH,DIRECT'],
          },
          realPatchConfig: PatchClashConfig(
            dns: _patchDns.copyWith(proxyServerNameserver: ['tls://1.1.1.1']),
          ),
          overrideDns: true,
          appendSystemDns: false,
          dnsSafetyMode: DnsSafetyMode.proxyOnly,
          proxyGroups: [],
          rules: [],
          addedRules: [],
          defaultUA: 'QuanClash-Test',
        ),
      );
      expect(result.dnsErrors, contains('dns-proxy-target-required'));
      expect(result.yaml, isEmpty);
      expect(result.md5, isEmpty);
    });

    test('target validation uses custom groups about to be applied', () async {
      final result = await makeRealProfileTask(
        const MakeRealProfileState(
          profilesPath: '/profiles',
          profileId: 1,
          rawConfig: {
            ..._proxyConfig,
            'rules': ['MATCH,DIRECT'],
          },
          realPatchConfig: PatchClashConfig(dns: _patchDns),
          overrideDns: true,
          appendSystemDns: false,
          dnsSafetyMode: DnsSafetyMode.proxyOnly,
          dnsProxyTarget: 'PROXY',
          proxyGroups: [
            ProxyGroup(
              id: 1,
              name: 'PROXY',
              type: GroupType.Selector,
              proxies: ['DIRECT'],
            ),
          ],
          rules: [],
          addedRules: [],
          defaultUA: 'QuanClash-Test',
        ),
      );
      expect(result.dnsErrors, contains('dns-proxy-target-not-proxy'));
      expect(result.yaml, isEmpty);
    });

    for (final tunEnabled in [false, true]) {
      for (final appendSystemDns in [false, true]) {
        test(
          'preserves DNS and TUN settings: $tunEnabled/$appendSystemDns',
          () async {
            final result = await makeRealProfileTask(
              MakeRealProfileState(
                profilesPath: '/profiles',
                profileId: 1,
                rawConfig: {
                  ..._proxyConfig,
                  'rules': ['MATCH,DIRECT'],
                },
                realPatchConfig: PatchClashConfig(
                  dns: _patchDns.copyWith(respectRules: true),
                  tun: Tun(enable: tunEnabled, autoRoute: tunEnabled),
                ),
                overrideDns: false,
                appendSystemDns: appendSystemDns,
                proxyGroups: [],
                rules: [],
                addedRules: [],
                defaultUA: 'QuanClash-Test',
              ),
            );
            final config = loadYaml(result.yaml) as YamlMap;
            final dns = config['dns'] as YamlMap;
            expect(dns['nameserver'], [
              ..._patchDns.nameserver,
              if (appendSystemDns) systemDnsNameserver,
            ]);
            expect(dns['respect-rules'], true);
            expect(
              dns['proxy-server-nameserver'],
              _patchDns.proxyServerNameserver,
            );
            expect(config['tun']['enable'], tunEnabled);
            expect(config['tun']['auto-route'], tunEnabled);
            expect(config['tun']['dns-hijack'], ['any:53']);
            expect(dns['fallback-filter'], isA<YamlMap>());
            expect(result.md5, isNotEmpty);
            expect(result.dnsErrors, isEmpty);
          },
        );
      }
    }
  });
}

const _proxyConfig = {
  'proxies': [
    {'name': 'node', 'type': 'socks5', 'server': '127.0.0.1', 'port': 1080},
  ],
  'proxy-groups': [
    {
      'name': 'PROXY',
      'type': 'select',
      'proxies': ['node'],
    },
  ],
};

EffectiveDnsConfig _buildDns({
  required Map? profileDns,
  required Dns patchDns,
  required bool overrideDns,
  required bool appendSystemDns,
  DnsSafetyMode safetyMode = DnsSafetyMode.compatible,
  String proxyTarget = '',
}) {
  return buildEffectiveDnsConfig(
    profileDns: profileDns == null || safetyMode != DnsSafetyMode.proxyOnly
        ? profileDns
        : {
            'default-nameserver': ['9.9.9.9'],
            'proxy-server-nameserver': ['tls://1.1.1.1'],
            ...profileDns,
          },
    patchDns: patchDns,
    overrideDns: overrideDns,
    appendSystemDns: appendSystemDns,
    safetyMode: safetyMode,
    proxyTarget: proxyTarget,
    proxyConfig: _proxyConfig,
  );
}
