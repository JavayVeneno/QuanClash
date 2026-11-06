import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/node_quality.dart';
import 'package:fl_clash/core/transport.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rust_api/rust_api.dart';

import 'fixtures/native_core_handler.dart';

Future<List<int>> _readBytes(StreamIterator<int> input, int length) async {
  final bytes = <int>[];
  while (bytes.length < length) {
    if (!await input.moveNext()) {
      throw StateError('SOCKS fixture closed early');
    }
    bytes.add(input.current);
  }
  return bytes;
}

Future<String> _refuseSocks(Socket socket) async {
  final input = StreamIterator(socket.expand((bytes) => bytes));
  try {
    final greeting = await _readBytes(input, 2);
    if (greeting.first != 5 || greeting.last == 0) {
      throw StateError('Invalid SOCKS greeting');
    }
    await _readBytes(input, greeting.last);
    socket.add([5, 0]);
    await socket.flush();
    final request = await _readBytes(input, 5);
    if (request[0] != 5 || request[1] != 1 || request[3] != 3) {
      throw StateError('Probe did not send SOCKS domain CONNECT');
    }
    final host = ascii.decode(await _readBytes(input, request[4]));
    final port = await _readBytes(input, 2);
    // Refuse before opening any destination connection. This server has no
    // forwarding implementation and cannot contact Cloudflare or IPPure.
    socket.add([5, 1, 0, 1, 127, 0, 0, 1, 0, 0]);
    await socket.flush();
    return '$host:${port[0] * 256 + port[1]}';
  } finally {
    await input.cancel();
    socket.destroy();
  }
}

void main() {
  final corePath = Platform.environment['QUANCLASH_NODE_QUALITY_IPC_CORE'];
  final rustPath = Platform.environment['QUANCLASH_NODE_QUALITY_IPC_RUST'];
  test(
    'native Rust IPC and facade validate the matching core without public probes',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'quanclash-quality-native-',
      );
      addTearDown(() async {
        final resolved = p.normalize(p.absolute(home.path));
        if (!p.isWithin(
          p.normalize(p.absolute(Directory.systemTemp.path)),
          resolved,
        )) {
          throw StateError('Fixture cleanup path escaped temp directory');
        }
        await home.delete(recursive: true);
      });
      await RustLib.init(externalLibrary: ExternalLibrary.open(rustPath!));
      addTearDown(RustLib.dispose);
      final destinations = <Future<String>>[];
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final subscription = server.listen((socket) {
        destinations.add(
          _refuseSocks(socket).timeout(const Duration(seconds: 3)),
        );
      });
      addTearDown(() async {
        await subscription.cancel();
        await server.close();
      });
      await File(p.join(home.path, 'config.yaml')).writeAsString('''
mixed-port: 0
allow-lan: false
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
tun: {enable: false}
dns: {enable: false}
proxies:
  - {name: node, type: socks5, server: 127.0.0.1, port: ${server.port}}
proxy-groups:
  - {name: group, type: select, proxies: [node]}
rules: ['MATCH,REJECT']
''');
      final transport = IPCCoreTransport(
        address:
            r'\\.\pipe\'
            'quanclash-quality-native-${p.basename(home.path)}',
      );
      await transport.init().timeout(const Duration(seconds: 5));
      final handler = IsolatedCoreHandler(transport);
      addTearDown(handler.destroy);
      final process = await Process.start(corePath!, [transport.address]);
      final exited = process.exitCode;
      final stdoutDrain = process.stdout.listen((_) {});
      final stderrDrain = process.stderr.listen((_) {});
      addTearDown(() async {
        process.kill();
        await exited.timeout(const Duration(seconds: 5));
        await stdoutDrain.cancel();
        await stderrDrain.cancel();
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
      final controller = CoreController.test(handler);
      addTearDown(CoreController.resetInstance);
      final missing = await controller.testNodeQuality(
        'missing',
        includeIpPure: false,
      );
      expect(missing.network.reason, 'proxy-not-found');
      expect(missing.quality.status, NodeQualityStatus.notRequested);
      final group = await controller.testNodeQuality(
        'group',
        includeIpPure: false,
      );
      expect(group.network.reason, 'group-not-supported');
      final basic = await controller.testNodeQuality(
        'node',
        includeIpPure: false,
      );
      expect(basic.network.status, NodeQualityStatus.failed);
      expect(basic.network.egressIp, isNull);
      expect(basic.quality.status, NodeQualityStatus.notRequested);
      final optedIn = await controller.testNodeQuality(
        'node',
        includeIpPure: true,
      );
      expect(optedIn.network.status, NodeQualityStatus.failed);
      expect(optedIn.quality.status, NodeQualityStatus.failed);
      expect(optedIn.quality.riskScore, isNull);
      expect(await Future.wait(destinations), [
        'www.cloudflare.com:443',
        'www.cloudflare.com:443',
        'my.ippure.com:443',
      ]);
      await controller.shutdown(false);
      final inactive = await controller.testNodeQuality(
        'node',
        includeIpPure: false,
      );
      expect(inactive.network.reason, 'inactive');
      // On Windows the child must disconnect before joining the blocking
      // native reader. Shutdown above only deinitializes the core policy.
      process.kill();
      await exited.timeout(const Duration(seconds: 5));
      await handler.destroy().timeout(const Duration(seconds: 5));
      expect(await ipcServerStatus(), isFalse);
      expect(await isIpcConnected(), isFalse);
      for (var cycle = 0; cycle < 2; cycle++) {
        final restarted = IPCCoreTransport(address: transport.address);
        final drained = restarted.dataStream.drain<void>();
        await restarted.init().timeout(const Duration(seconds: 5));
        expect(await ipcServerStatus(), isTrue);
        await Future.wait([
          restarted.close(),
          restarted.close(),
        ]).timeout(const Duration(seconds: 5));
        await drained;
        expect(await ipcServerStatus(), isFalse);
      }
    },
    skip: !Platform.isWindows || corePath == null || rustPath == null
        ? 'Opt-in: set QUANCLASH_NODE_QUALITY_IPC_CORE and QUANCLASH_NODE_QUALITY_IPC_RUST; loopback only'
        : false,
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
