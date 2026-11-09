import 'dart:async';
import 'dart:convert';

import 'package:quanclash/core/controller.dart';
import 'package:quanclash/core/interface.dart';
import 'package:quanclash/core/node_quality.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _wire({
  Map<String, dynamic>? network,
  Map<String, dynamic>? quality,
}) => {
  'schemaVersion': 1,
  'source': 'selected-proxy',
  'proxyName': 'node',
  'sampledAt': '2026-10-30T01:02:03Z',
  'network':
      network ??
      {
        'provider': 'cloudflare',
        'status': 'ok',
        'egressIp': '203.0.113.1',
        'colo': 'HKG',
        'country': 'HK',
        'ttfbMs': 75,
      },
  'quality': quality ?? {'provider': 'ippure', 'status': 'not-requested'},
};

class _Handler extends CoreHandlerInterface {
  final Map<String, dynamic>? response;
  ActionMethod? method;
  dynamic data;
  Duration? timeout;

  _Handler(this.response);

  @override
  final Completer<void> completer = Completer<void>()..complete();

  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) async {
    this.method = method;
    this.data = data;
    this.timeout = timeout;
    return response as T?;
  }

  @override
  Future<bool> destroy() async => true;

  @override
  Future<String> preload() async => '';

  @override
  Future<bool> shutdown(bool isUser) async => true;
}

void main() {
  tearDown(CoreController.resetInstance);

  test('typed report keeps network metrics separate from provider risk', () {
    final report = NodeQualityResult.fromJson(
      _wire(
        quality: {
          'provider': 'ippure',
          'status': 'ok',
          'egressIp': '203.0.113.1',
          'riskScore': 0,
          'isResidential': false,
        },
      ),
    );
    expect(report.network.ttfbMs, 75);
    expect(report.network.riskScore, isNull);
    expect(report.quality.riskScore, 0);
    expect(report.quality.isResidential, isFalse);
    expect(report.egressMismatch, isFalse);
    expect(report.sampledAt.isUtc, isTrue);
  });

  test('missing risk fields remain unknown', () {
    final report = NodeQualityResult.fromJson(
      _wire(
        quality: {
          'provider': 'ippure',
          'status': 'ok',
          'egressIp': '203.0.113.1',
        },
      ),
    );
    expect(report.quality.riskScore, isNull);
    expect(report.quality.isResidential, isNull);
  });

  test('unverified IPv6 score is suppressed and IP mismatch is explicit', () {
    final report = NodeQualityResult.fromJson(
      _wire(
        quality: {
          'provider': 'ippure',
          'status': 'ok',
          'egressIp': '2001:db8::1',
          'riskScore': 0,
        },
      ),
    );
    expect(report.quality.riskScore, isNull);
    expect(report.egressMismatch, isTrue);
  });

  test('equivalent IPv6 addresses do not produce mismatch', () {
    final wire = _wire(
      quality: {
        'provider': 'ippure',
        'status': 'ok',
        'egressIp': '2001:db8::1',
      },
    );
    (wire['network'] as Map)['egressIp'] = '2001:0db8:0:0:0:0:0:1';
    expect(NodeQualityResult.fromJson(wire).egressMismatch, isFalse);
  });

  test('every failure state has no fake score or IP', () {
    for (final status in [
      'failed',
      'timeout',
      'unavailable',
      'not-requested',
    ]) {
      final report = NodeQualityResult.fromJson(
        _wire(quality: {'provider': 'ippure', 'status': status}),
      );
      expect(report.quality.riskScore, isNull);
      expect(report.quality.egressIp, isNull);
    }
  });

  test('rejects incompatible identity and schema', () {
    for (final change in [
      {'schemaVersion': 2},
      {'schemaVersion': 1.0},
      {'source': 'route-rules'},
      {'proxyName': ''},
      {'sampledAt': 'invalid'},
      {'sampledAt': '2026-10-30T01:02:03'},
    ]) {
      expect(
        () => NodeQualityResult.fromJson({..._wire(), ...change}),
        throwsA(anything),
      );
    }
  });

  test('rejects invalid, mixed and failure metrics', () {
    for (final change in [
      {'status': 'new-status'},
      {'provider': 'cloudflare'},
      {'egressIp': 'secret-host'},
      {'egressIp': 'fe80::1%eth0'},
      {'egressIp': '0.0.0.0'},
      {'egressIp': '224.0.0.1'},
      {'egressIp': null},
      {'riskScore': -1},
      {'riskScore': 101},
      {'riskScore': 0.5},
      {'riskScore': '0'},
      {'isResidential': 'true'},
      {'status': 'failed', 'riskScore': 0},
      {'ttfbMs': 20},
      {'colo': 'HKG'},
    ]) {
      expect(
        () => NodeQualityResult.fromJson(
          _wire(
            quality: {
              'provider': 'ippure',
              'status': 'ok',
              'egressIp': '203.0.113.1',
              ...change,
            },
          ),
        ),
        throwsA(anything),
      );
    }
  });

  test(
    'interface opt-in determines providers and bounded IPC timeout',
    () async {
      for (final optIn in [false, true]) {
        final handler = _Handler(_wire());
        await handler.testNodeQuality('node', includeIpPure: optIn);
        expect(handler.method, ActionMethod.testNodeQuality);
        expect(handler.timeout, const Duration(seconds: 15));
        expect(jsonDecode(handler.data as String), {
          'proxy-name': 'node',
          'providers': ['cloudflare', if (optIn) 'ippure'],
        });
        final action = Action(
          method: handler.method!,
          data: handler.data,
          id: 'test',
        );
        expect(
          Action.fromJson(jsonDecode(jsonEncode(action))).method,
          handler.method,
        );
      }
    },
  );

  test('missing IPC response is unavailable, not an empty success', () async {
    await expectLater(
      _Handler(null).testNodeQuality('node', includeIpPure: false),
      throwsStateError,
    );
  });

  test('facade validates the requested node and opt-in response', () async {
    final controller = CoreController.test(_Handler(_wire()));
    expect(
      (await controller.testNodeQuality(
        'node',
        includeIpPure: false,
      )).proxyName,
      'node',
    );
    await expectLater(
      controller.testNodeQuality('other', includeIpPure: false),
      throwsFormatException,
    );
    await expectLater(
      controller.testNodeQuality('node', includeIpPure: true),
      throwsFormatException,
    );
    final unexpected = CoreController.test(
      _Handler(
        _wire(
          quality: {
            'provider': 'ippure',
            'status': 'ok',
            'egressIp': '203.0.113.1',
            'riskScore': 75,
          },
        ),
      ),
    );
    await expectLater(
      unexpected.testNodeQuality('node', includeIpPure: false),
      throwsFormatException,
    );
  });
}
