import 'dart:async';
import 'dart:typed_data';

import 'package:fl_clash/core/transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rust_api/rust_api.dart';
// The FRB mock entrypoint requires its generated API contract.
// ignore: implementation_imports
import 'package:rust_api/src/rust/frb_generated.dart' show RustLibApi;

class _RustApi extends Mock implements RustLibApi {}

void main() {
  late _RustApi api;

  setUpAll(() {
    api = _RustApi();
    RustLib.initMock(api: api);
  });

  setUp(() => reset(api));
  tearDownAll(RustLib.dispose);

  test('stops the producer before waiting for stream cancellation', () async {
    final stopped = Completer<void>();
    final events = <String>[];
    final native = StreamController<Uint8List>(
      onCancel: () async {
        events.add('cancel');
        await stopped.future;
      },
    );
    when(
      () => api.crateApiIpcRestartIpcServer(name: 'fixture'),
    ).thenAnswer((_) => native.stream);
    when(() => api.crateApiIpcStopIpcServer()).thenAnswer((_) async {
      events.add('stop');
      // Events queued while stopping must not invoke the crash callback or
      // add to the data stream after close has begun.
      native.add(Uint8List.fromList([2]));
      native.add(Uint8List.fromList([3, 42]));
      stopped.complete();
    });
    final transport = IPCCoreTransport(address: 'fixture');
    var disconnected = false;
    transport.onDisconnect = () => disconnected = true;
    final received = <Uint8List>[];
    final data = transport.dataStream.listen(received.add);
    final ready = transport.init();
    native.add(Uint8List.fromList([0]));
    await ready;
    await Future.wait([
      transport.close(),
      transport.close(),
    ]).timeout(const Duration(seconds: 2));
    expect(events, ['stop', 'cancel']);
    expect(disconnected, isFalse);
    expect(received, isEmpty);
    verify(() => api.crateApiIpcStopIpcServer()).called(1);
    await data.cancel();
    await native.close();
  });

  test('releases Dart subscriptions when native stop fails', () async {
    var cancelled = false;
    final native = StreamController<Uint8List>(
      onCancel: () => cancelled = true,
    );
    when(
      () => api.crateApiIpcRestartIpcServer(name: 'fixture'),
    ).thenAnswer((_) => native.stream);
    when(
      () => api.crateApiIpcStopIpcServer(),
    ).thenThrow(StateError('stop failed'));
    final transport = IPCCoreTransport(address: 'fixture');
    final done = transport.dataStream.drain<void>();
    final ready = transport.init();
    native.add(Uint8List.fromList([0]));
    await ready;
    await expectLater(transport.close(), throwsStateError);
    await done;
    expect(cancelled, isTrue);
    await native.close();
  });
}
