import 'dart:async';
import 'dart:convert';

import 'package:quanclash/core/interface.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCoreHandler extends CoreHandlerInterface {
  final Object? response;
  ActionMethod? invokedMethod;
  dynamic invokedData;
  Duration? invokedTimeout;

  _TestCoreHandler(this.response);

  @override
  final Completer<void> completer = Completer<void>()..complete();

  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) async {
    invokedMethod = method;
    invokedData = data;
    invokedTimeout = timeout;
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
  const params = SetupParams(selectedMap: {}, testUrl: 'https://test.example');

  group('Core setup acknowledgment', () {
    test('only an explicit empty response means success', () async {
      final handler = _TestCoreHandler('');
      expect(await handler.setupConfig(params), '');
      expect(handler.invokedMethod, ActionMethod.setupConfig);
      expect(jsonDecode(handler.invokedData as String), params.toJson());
    });

    test('a missing response is an error, not success', () async {
      final handler = _TestCoreHandler(null);
      expect(await handler.setupConfig(params), isNotEmpty);
    });

    test('configuration error responses are preserved', () async {
      final handler = _TestCoreHandler('configuration file is empty');
      expect(await handler.setupConfig(params), 'configuration file is empty');
    });
  });

  group('DNS diagnostic transport', () {
    test(
      'delegates a structured response through the shared interface',
      () async {
        final response = <String, dynamic>{
          'schemaVersion': 1,
          'status': 'inactive',
        };
        final handler = _TestCoreHandler(response);
        expect(await handler.getDnsDiagnostic(), response);
        expect(handler.invokedMethod, ActionMethod.getDnsDiagnostic);
        expect(handler.invokedData, isNull);
      },
    );

    test('no response is unavailable, not a safe DNS verdict', () async {
      await expectLater(
        _TestCoreHandler(null).getDnsDiagnostic(),
        throwsStateError,
      );
    });
  });

  group('Connection updates transport (not enabled in UI)', () {
    test('encodes schema and cursor, returns a structured map', () async {
      final response = <String, dynamic>{'schemaVersion': 1, 'status': 'ready'};
      final handler = _TestCoreHandler(response);
      const cursor = '0123456789abcdef0123456789abcdef';
      expect(await handler.getConnectionUpdates(cursor), same(response));
      expect(handler.invokedMethod, ActionMethod.getConnectionUpdates);
      expect(jsonDecode(handler.invokedData as String), {
        'schemaVersion': 1,
        'cursor': cursor,
      });
      expect(handler.invokedTimeout, const Duration(seconds: 5));
      final action = Action(
        id: 'fixture',
        method: ActionMethod.getConnectionUpdates,
        data: handler.invokedData,
      );
      expect(jsonDecode(jsonEncode(action))['method'], 'getConnectionUpdates');
    });

    test('missing response is not an empty connection list', () async {
      final handler = _TestCoreHandler(null);
      expect(await handler.getConnectionUpdates(''), isNull);
      expect(jsonDecode(handler.invokedData as String)['cursor'], '');
    });

    test('invalid cursors do not reach the core', () async {
      for (final cursor in ['bad', 'a' * 33, 'g' * 32]) {
        final handler = _TestCoreHandler(null);
        await expectLater(
          handler.getConnectionUpdates(cursor),
          throwsFormatException,
        );
        expect(handler.invokedMethod, isNull);
      }
    });
  });
}
