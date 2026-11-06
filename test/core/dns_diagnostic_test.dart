import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/dns_diagnostic.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCoreHandler extends Mock implements CoreHandlerInterface {}

Map<String, dynamic> _report({String status = 'ready', String path = 'rules'}) {
  return {
    'schemaVersion': 1,
    'source': 'active-config',
    'status': status,
    'proxyBootstrap': 'dedicated',
    'directQueries': 'inherits-main',
    'directFollowPolicy': false,
    'warnings': [
      'configuration-only-not-a-leak-test',
      'rules-may-select-direct',
    ],
    'routes': [
      {
        'role': 'nameserver-policy',
        'policyIndex': 0,
        'serverIndex': 1,
        'endpoint': '1.1.1.1:443',
        'transport': 'https',
        'path': path,
      },
    ],
  };
}

void main() {
  tearDown(CoreController.resetInstance);

  test('generated action serialization matches the core diagnostic method', () {
    const action = Action(
      id: 'diagnostic-1',
      method: ActionMethod.getDnsDiagnostic,
      data: null,
    );
    expect(action.toJson()['method'], 'getDnsDiagnostic');
    final response = ActionResult.fromJson({
      'id': action.id,
      'method': 'getDnsDiagnostic',
      'code': 0,
      'data': _report(),
    });
    expect(response.method, ActionMethod.getDnsDiagnostic);
    expect(response.code, ResultType.success);
    expect(
      DnsDiagnostic.fromJson(response.data as Map<String, dynamic>).status,
      DnsDiagnosticStatus.ready,
    );
  });

  test('unavailable core snapshots decode with no invented active routes', () {
    for (final status in ['inactive', 'not-configured', 'disabled']) {
      final report = DnsDiagnostic.fromJson({
        ..._report(status: status),
        'proxyBootstrap': '',
        'directQueries': '',
        'routes': <Object>[],
      });
      expect(report.routes, isEmpty);
      expect(report.status, isNot(DnsDiagnosticStatus.ready));
      expect(report.proxyBootstrap, isEmpty);
    }
  });

  test('controller exposes a typed active-config snapshot', () async {
    final handler = _MockCoreHandler();
    when(() => handler.getDnsDiagnostic()).thenAnswer((_) async => _report());
    final report = await CoreController.test(handler).getDnsDiagnostic();
    expect(report.status, DnsDiagnosticStatus.ready);
    expect(report.proxyBootstrap, 'dedicated');
    expect(report.directQueries, 'inherits-main');
    expect(report.routes.single.path, DnsRoutePath.rules);
    expect(report.routes.single.policyIndex, 0);
    expect(report.routes.single.serverIndex, 1);
    expect(report.routes.single.target, isNull);
    expect(report.warnings, contains('rules-may-select-direct'));
    verify(() => handler.getDnsDiagnostic()).called(1);
  });

  for (final entry in {
    'ready': DnsDiagnosticStatus.ready,
    'disabled': DnsDiagnosticStatus.disabled,
    'inactive': DnsDiagnosticStatus.inactive,
    'not-configured': DnsDiagnosticStatus.notConfigured,
    'future': DnsDiagnosticStatus.unknown,
  }.entries) {
    test('preserves state ${entry.key} without treating it as safe', () {
      expect(
        DnsDiagnostic.fromJson(_report(status: entry.key)).status,
        entry.value,
      );
    });
  }

  for (final path in DnsRoutePath.values) {
    test('decodes path ${path.name}', () {
      expect(
        DnsDiagnostic.fromJson(_report(path: path.name)).routes.single.path,
        path,
      );
    });
  }

  test('unknown future routing path stays unknown', () {
    expect(
      DnsDiagnostic.fromJson(_report(path: 'future')).routes.single.path,
      DnsRoutePath.unknown,
    );
  });

  test('snapshot collections are detached and immutable', () {
    final raw = _report();
    final report = DnsDiagnostic.fromJson(raw);
    (raw['warnings'] as List).clear();
    (raw['routes'] as List).clear();
    expect(report.routes, hasLength(1));
    expect(report.warnings, hasLength(2));
    expect(() => report.routes.clear(), throwsUnsupportedError);
    expect(() => report.warnings.clear(), throwsUnsupportedError);
  });

  test(
    'rejects a missing or incompatible schema instead of defaulting safe',
    () {
      for (final raw in [
        <String, dynamic>{},
        {..._report(), 'schemaVersion': 2},
        {..._report(), 'source': 'profile-file'},
      ]) {
        expect(() => DnsDiagnostic.fromJson(raw), throwsFormatException);
      }
    },
  );

  test('controller propagates transport failure', () async {
    final handler = _MockCoreHandler();
    when(
      () => handler.getDnsDiagnostic(),
    ).thenThrow(StateError('disconnected'));
    await expectLater(
      CoreController.test(handler).getDnsDiagnostic(),
      throwsStateError,
    );
  });
}
