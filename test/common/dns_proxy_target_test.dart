import 'package:quanclash/common/dns_proxy_target.dart';
import 'package:flutter_test/flutter_test.dart';

const _node = {'name': 'node', 'type': 'socks5'};

void main() {
  group('DNS target graph', () {
    test('bounds recursive graph inspection', () {
      expect(
        validateDnsProxyTarget({
          'proxies': [_node],
          'proxy-groups': [
            for (var i = 0; i < 150; i++)
              {
                'name': '$i',
                'type': 'select',
                'proxies': [i == 149 ? 'node' : '${i + 1}'],
              },
          ],
        }, '0'),
        contains('dns-proxy-target-too-deep'),
      );
    });
    test('accepts a static proxy and nested all-proxy groups', () {
      final config = {
        'proxies': [_node],
        'proxy-groups': [
          {
            'name': 'outer',
            'type': 'select',
            'proxies': ['inner', 'node'],
          },
          {
            'name': 'inner',
            'type': 'fallback',
            'proxies': ['node'],
          },
        ],
      };
      expect(validateDnsProxyTarget(config, 'node'), isEmpty);
      expect(validateDnsProxyTarget(config, 'outer'), isEmpty);
    });

    test(
      'rejects a typo and case mismatch instead of treating it as an interface',
      () {
        final config = {
          'proxies': [_node],
        };
        for (final target in ['Node', 'Ethernet', 'typo']) {
          expect(
            validateDnsProxyTarget(config, target),
            contains('dns-proxy-target-not-found'),
          );
        }
      },
    );

    test('rejects every selectable DIRECT descendant', () {
      expect(
        validateDnsProxyTarget({
          'proxies': [_node],
          'proxy-groups': [
            {
              'name': 'outer',
              'type': 'select',
              'proxies': ['node', 'inner'],
            },
            {
              'name': 'inner',
              'type': 'select',
              'proxies': ['DIRECT'],
            },
          ],
        }, 'outer'),
        contains('dns-proxy-target-not-proxy'),
      );
    });

    test('rejects disguised direct outbounds', () {
      for (final type in ['direct', 'dns', 'reject', 'pass', 'unknown']) {
        expect(
          validateDnsProxyTarget({
            'proxies': [
              {'name': 'node', 'type': type},
            ],
          }, 'node'),
          contains('dns-proxy-target-unverified-type'),
        );
      }
    });

    test('rejects empty groups that upstream may replace with DIRECT', () {
      expect(
        validateDnsProxyTarget({
          'proxy-groups': [
            {'name': 'empty', 'type': 'select', 'proxies': []},
          ],
        }, 'empty'),
        contains('dns-proxy-target-empty-group'),
      );
    });

    test(
      'rejects dynamic providers and auto inclusion despite a safe static member',
      () {
        for (final extra in [
          {
            'use': ['subscription'],
          },
          {'include-all': true},
          {'include-all-proxies': true},
          {'include-all-providers': true},
        ]) {
          expect(
            validateDnsProxyTarget({
              'proxies': [_node],
              'proxy-groups': [
                {
                  'name': 'group',
                  'type': 'select',
                  'proxies': ['node'],
                  ...extra,
                },
              ],
            }, 'group'),
            contains('dns-proxy-target-dynamic-group'),
          );
        }
      },
    );

    test('rejects filters that could remove all members', () {
      for (final key in ['filter', 'exclude-filter', 'exclude-type']) {
        expect(
          validateDnsProxyTarget({
            'proxies': [_node],
            'proxy-groups': [
              {
                'name': 'group',
                'type': 'select',
                'proxies': ['node'],
                key: 'x',
              },
            ],
          }, 'group'),
          contains('dns-proxy-target-filtered-group'),
        );
      }
    });

    test('rejects graph cycles and duplicate definitions', () {
      expect(
        validateDnsProxyTarget({
          'proxy-groups': [
            {
              'name': 'a',
              'type': 'select',
              'proxies': ['b'],
            },
            {
              'name': 'b',
              'type': 'select',
              'proxies': ['a'],
            },
          ],
        }, 'a'),
        contains('dns-proxy-target-cycle'),
      );
      expect(
        validateDnsProxyTarget({
          'proxies': [_node, _node],
        }, 'node'),
        contains('dns-proxy-target-duplicate'),
      );
    });

    test('follows dialer-proxy chains rather than trusting the leaf type', () {
      expect(
        validateDnsProxyTarget({
          'proxies': [
            {..._node, 'dialer-proxy': 'missing'},
          ],
        }, 'node'),
        contains('dns-proxy-target-not-found'),
      );
      expect(
        validateDnsProxyTarget({
          'proxies': [
            {..._node, 'dialer-proxy': 'node'},
          ],
        }, 'node'),
        contains('dns-proxy-target-cycle'),
      );
    });
  });
}
