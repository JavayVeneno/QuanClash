import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:quanclash/core/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures/native_core_handler.dart';

class _Transport extends Mock implements IPCCoreTransport {}

void main() {
  for (final instrumented in [false, true]) {
    test(
      'fixture response decoding with instrumentation=$instrumented',
      () async {
        final transport = _Transport();
        final stream = StreamController<Uint8List>();
        final observations = <Map<String, dynamic>>[];
        final sent = Completer<String>();
        when(() => transport.dataStream).thenAnswer((_) => stream.stream);
        when(
          () => transport.connectionCompleter,
        ).thenReturn(Completer<void>()..complete());
        when(() => transport.close()).thenAnswer((_) async {});
        when(() => transport.send(any())).thenAnswer((call) {
          sent.complete(call.positionalArguments.single as String);
        });
        final handler = IsolatedCoreHandler(
          transport,
          logActions: false,
          onResponse: instrumented
              ? (result, bytes, micros) {
                  observations.add({
                    'id': result.id,
                    'bytes': bytes,
                    'micros': micros,
                  });
                }
              : null,
        );
        addTearDown(() async {
          await handler.destroy();
          await stream.close();
        });
        final pending = handler.getConnections();
        final action = jsonDecode(await sent.future) as Map<String, dynamic>;
        final encoded = Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'id': action['id'],
              'method': 'getConnections',
              'code': 0,
              'data': '{"connections":[],"uploadTotal":0,"downloadTotal":0}',
            }),
          ),
        );
        stream.add(encoded);
        expect(
          await pending,
          '{"connections":[],"uploadTotal":0,"downloadTotal":0}',
        );
        if (instrumented) {
          expect(observations.single['id'], action['id']);
          expect(observations.single['bytes'], encoded.length);
          expect(observations.single['micros'], greaterThanOrEqualTo(0));
        } else {
          expect(observations, isEmpty);
        }
        // Duplicate/unmatched responses must not count again or complete twice.
        stream.add(encoded);
        await Future<void>.delayed(Duration.zero);
        expect(observations.length, instrumented ? 1 : 0);
      },
    );
  }
}
