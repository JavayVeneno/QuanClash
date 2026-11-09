import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:quanclash/core/connection_inspection_session.dart';
import 'package:quanclash/core/connection_updates.dart';
import 'package:quanclash/core/controller.dart';
import 'package:quanclash/core/transport.dart';
import 'package:quanclash/models/models.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rust_api/rust_api.dart';

import 'fixtures/native_core_handler.dart';

Future<List<int>> _read(StreamIterator<int> input, int count) async {
  final bytes = <int>[];
  while (bytes.length < count) {
    if (!await input.moveNext()) throw StateError('Loopback stream closed');
    bytes.add(input.current);
  }
  return bytes;
}

void main() {
  final corePath = Platform.environment['QUANCLASH_CONNECTION_IPC_CORE'];
  final rustPath = Platform.environment['QUANCLASH_CONNECTION_IPC_RUST'];
  test(
    'production IPC merges updates and serializes inspection sessions',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'quanclash-merge-native-',
      );
      addTearDown(() async {
        if (!p.isWithin(
          p.normalize(p.absolute(Directory.systemTemp.path)),
          p.normalize(p.absolute(home.path)),
        )) {
          throw StateError('Native fixture cleanup escaped temp');
        }
        await home.delete(recursive: true);
      });
      await RustLib.init(externalLibrary: ExternalLibrary.open(rustPath!));
      addTearDown(RustLib.dispose);
      final echo = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final peers = <Socket>[];
      final echoSub = echo.listen((socket) {
        peers.add(socket);
        socket.listen(socket.add);
      });
      addTearDown(() async {
        for (final peer in peers) {
          peer.destroy();
        }
        await echoSub.cancel();
        await echo.close();
      });
      // Reserve then release a loopback port for the private core listener.
      // Binding collisions fail the test; no existing process/port is reclaimed.
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      await File(p.join(home.path, 'config.yaml')).writeAsString('''
mixed-port: $port
bind-address: 127.0.0.1
allow-lan: false
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
external-controller: ''
tun: {enable: false}
dns: {enable: false}
rules: ['MATCH,DIRECT']
''');
      final transport = IPCCoreTransport(
        address:
            r'\\.\pipe\'
            'quanclash-merge-${p.basename(home.path)}',
      );
      await transport.init().timeout(const Duration(seconds: 5));
      final handler = IsolatedCoreHandler(transport);
      addTearDown(handler.destroy);
      final process = await Process.start(corePath!, [transport.address]);
      final stdoutSub = process.stdout.listen((_) {});
      final stderrSub = process.stderr.listen((_) {});
      addTearDown(() async {
        process.kill();
        await process.exitCode.timeout(const Duration(seconds: 5));
        await stdoutSub.cancel();
        await stderrSub.cancel();
      });
      await transport.connectionCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      expect(
        await handler.init(InitParams(homeDir: home.path, version: 1)),
        isTrue,
      );
      expect(
        await handler.setupConfig(
          const SetupParams(selectedMap: {}, testUrl: 'http://127.0.0.1/'),
        ),
        isEmpty,
      );
      expect(await handler.startListener(), isTrue);
      final controller = CoreController.test(handler);
      addTearDown(CoreController.resetInstance);
      final initial = await controller.getConnectionUpdates('');
      expect(initial.full, isTrue);
      var snapshot = const ConnectionInspectionSnapshot.empty().apply(initial);
      expect(snapshot.records, isEmpty);
      final client = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 3),
      );
      final input = StreamIterator(client.expand((bytes) => bytes));
      addTearDown(() async {
        client.destroy();
        await input.cancel();
      });
      client.add([5, 1, 0]);
      await client.flush();
      expect(await _read(input, 2), [5, 0]);
      client.add([5, 1, 0, 1, 127, 0, 0, 1, echo.port >> 8, echo.port & 255]);
      await client.flush();
      final reply = await _read(input, 4);
      expect(reply[1], 0);
      expect(reply[3], anyOf(1, 4));
      await _read(input, reply[3] == 1 ? 6 : 18);
      Future<void> transfer(String message) async {
        final payload = utf8.encode(message);
        client.add(payload);
        await client.flush();
        expect(await _read(input, payload.length), payload);
      }

      await transfer('first-local-echo');
      final added = await controller.getConnectionUpdates(snapshot.cursor);
      expect(added.full, isFalse);
      expect(added.upserted, hasLength(1));
      snapshot = snapshot.apply(added);
      final id = snapshot.records.keys.single;
      final first = snapshot.records[id]!;
      expect(first.tracker.metadata.network, 'tcp');
      expect(first.tracker.metadata.destinationIP, '127.0.0.1');
      expect(first.tracker.upload, greaterThanOrEqualTo(16));
      expect(first.tracker.download, greaterThanOrEqualTo(16));
      await transfer('second-local-echo');
      final counted = await controller.getConnectionUpdates(snapshot.cursor);
      expect(counted.full, isFalse);
      expect(counted.upserted, isEmpty);
      expect(counted.updated, hasLength(1));
      snapshot = snapshot.apply(counted);
      expect(
        snapshot.records[id]!.tracker.upload,
        greaterThan(first.tracker.upload),
      );
      // Cross-check the merged record against the unchanged full-snapshot action.
      final legacy = await controller.getConnections();
      expect(legacy.single, snapshot.records[id]!.tracker);
      final session = controller.createConnectionInspectionSession();
      addTearDown(session.dispose);
      final refreshA = session.refresh();
      final refreshB = session.refresh();
      expect(identical(refreshA, refreshB), isTrue);
      expect(await refreshA, isTrue);
      expect(await refreshB, isTrue);
      expect(session.state.connections.single, legacy.single);
      final sessionCursor = session.state.snapshot.cursor;
      await transfer('third-session-local-echo');
      expect(await session.refresh(), isTrue);
      expect(session.state.snapshot.cursor, isNot(sessionCursor));
      expect(session.state.source, ConnectionInspectionSource.incremental);
      expect(
        session.state.connections.single,
        (await controller.getLegacyConnectionSnapshot()).connections.single,
      );
      // Simulate an unsupported update action; the full action is real IPC.
      // This is compatibility-boundary coverage, not an old-binary runtime test.
      var updateAttempts = 0;
      var legacyAttempts = 0;
      final compatible = ConnectionInspectionSession(
        readUpdates: (_) async {
          updateAttempts++;
          throw StateError('Simulated unsupported action');
        },
        readLegacy: () {
          legacyAttempts++;
          return controller.getLegacyConnectionSnapshot();
        },
      );
      addTearDown(compatible.dispose);
      expect(await compatible.refresh(), isTrue);
      expect(await compatible.refresh(), isTrue);
      expect(updateAttempts, 1);
      expect(legacyAttempts, 2);
      expect(compatible.state.source, ConnectionInspectionSource.legacy);
      expect(
        compatible.state.connections.single,
        session.state.connections.single,
      );
      final resync = await controller.getConnectionUpdates(initial.cursor);
      expect(resync.full, isTrue);
      snapshot = snapshot.apply(resync);
      await controller.closeConnection(id);
      final removed = await controller.getConnectionUpdates(snapshot.cursor);
      expect(removed.removed, hasLength(1));
      expect(removed.removed.single.id, id);
      expect(removed.removed.single.finalCountersVerified, isFalse);
      snapshot = snapshot.apply(removed);
      expect(snapshot.records, isEmpty);
      expect(await session.refresh(), isTrue);
      expect(session.state.connections, isEmpty);
      session.disconnect();
      compatible.disconnect();
      expect(await handler.stopListener(), isTrue);
      expect(await session.refresh(), isFalse);
      expect(await handler.startListener(), isTrue);
      session.reset();
      expect(await session.refresh(), isTrue);
      expect(session.state.status, ConnectionInspectionStatus.ready);
      expect(session.state.connections, isEmpty);
      final restarted = await controller.getConnectionUpdates(snapshot.cursor);
      expect(restarted.full, isTrue);
      snapshot = snapshot.apply(restarted);
      session.disconnect();
      expect(await handler.stopListener(), isTrue);
      await controller.shutdown(false);
      final inactive = await controller.getConnectionUpdates(snapshot.cursor);
      expect(inactive.status, ConnectionUpdateStatus.inactive);
      expect(snapshot.apply(inactive).records, isEmpty);
      session.reset(); // Explicitly query inactive core, without restarting it.
      expect(await session.refresh(), isTrue);
      expect(session.state.status, ConnectionInspectionStatus.inactive);
      expect(session.state.uploadTotal, 0);
    },
    skip: !Platform.isWindows || corePath == null || rustPath == null
        ? 'Opt-in: QUANCLASH_CONNECTION_IPC_CORE/RUST, loopback only'
        : false,
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
