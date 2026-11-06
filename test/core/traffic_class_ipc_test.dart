import 'dart:io';

import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/traffic_class.dart';
import 'package:fl_clash/core/traffic_class_session.dart';
import 'package:fl_clash/core/transport.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rust_api/rust_api.dart';

import 'fixtures/native_core_handler.dart';
import 'fixtures/traffic_class_packets.dart';

void main() {
  final corePath = Platform.environment['QUANCLASH_TRAFFIC_CLASS_IPC_CORE'];
  final rustPath = Platform.environment['QUANCLASH_TRAFFIC_CLASS_IPC_RUST'];
  test(
    'real TrafficClass facade and session reconcile CAS and lifecycle',
    () async {
      final home = await Directory.systemTemp.createTemp(
        'quanclash-class-native-',
      );
      addTearDown(() async {
        if (!p.isWithin(
          p.normalize(p.absolute(Directory.systemTemp.path)),
          p.normalize(p.absolute(home.path)),
        )) {
          throw StateError('TrafficClass cleanup escaped temp');
        }
        await home.delete(recursive: true);
      });
      await RustLib.init(externalLibrary: ExternalLibrary.open(rustPath!));
      addTearDown(RustLib.dispose);
      // All IP listeners are disabled. This test exercises only a private named
      // pipe and volatile preparation; no process resolver or QoS hook runs.
      await File(p.join(home.path, 'config.yaml')).writeAsString('''
mixed-port: 0
allow-lan: false
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
external-controller: ''
tun: {enable: false}
dns: {enable: false}
rules: ['MATCH,REJECT']
''');
      final transport = IPCCoreTransport(
        address:
            r'\\.\pipe\'
            'quanclash-class-${p.basename(home.path)}',
      );
      await transport.init().timeout(const Duration(seconds: 5));
      final handler = IsolatedCoreHandler(transport);
      addTearDown(handler.destroy);
      final process = await Process.start(corePath!, [transport.address]);
      final stdoutDrain = process.stdout.listen((_) {});
      final stderrDrain = process.stderr.listen((_) {});
      // Terminate only this child before joining the Windows blocking reader.
      addTearDown(() async {
        process.kill();
        await process.exitCode.timeout(const Duration(seconds: 5));
        await stdoutDrain.cancel();
        await stderrDrain.cancel();
      });
      await transport.connectionCompleter.future.timeout(
        const Duration(seconds: 5),
      );
      final controller = CoreController.test(handler);
      addTearDown(CoreController.resetInstance);
      final session = controller.createTrafficClassSession();
      addTearDown(session.dispose);
      expect(await session.refresh(), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.inactive);
      expect(await session.submit(classConfig()), isFalse);
      expect(
        await handler.init(InitParams(homeDir: home.path, version: 1)),
        isTrue,
      );
      const setup = SetupParams(selectedMap: {}, testUrl: 'http://127.0.0.1/');
      session.reset();
      expect(await handler.setupConfig(setup), isEmpty);
      final readA = session.refresh();
      final readB = session.refresh();
      expect(identical(readA, readB), isTrue);
      expect(await readA, isTrue);
      final first = session.state.snapshot!;
      expect(first.status, TrafficClassStatus.prepared);
      expect(first.classes, isEmpty);
      final config = classConfig();
      expect(await session.submit(config), isTrue);
      final accepted = session.state.snapshot!;
      expect(accepted.revision, isNot(first.revision));
      expect(accepted.classes.single.id, config.classes.single.id);
      expect(identical(session.state.acknowledgedConfig, config), isTrue);
      await expectLater(
        controller.setTrafficClasses(config, first.revision),
        throwsStateError,
      );
      expect(
        (await controller.getTrafficClassState()).revision,
        accepted.revision,
      );
      expect(await session.refresh(), isTrue);
      expect(identical(session.state.acknowledgedConfig, config), isTrue);

      // Invalidate owner state BEFORE lifecycle changes, not after a reply.
      for (final transition in [
        () => handler.setupConfig(setup),
        handler.startListener,
        handler.stopListener,
      ]) {
        final previous = session.state.snapshot!.revision;
        session.reset();
        await transition();
        expect(await session.submit(config), isFalse);
        expect(await session.refresh(), isTrue);
        expect(session.state.snapshot!.revision, isNot(previous));
        expect(session.state.snapshot!.classes, isEmpty);
        expect(session.state.acknowledgedConfig, isNull);
        await expectLater(
          controller.setTrafficClasses(config, previous),
          throwsStateError,
        );
        expect(await session.submit(config), isTrue);
      }
      final empty = TrafficClassConfig.fromJson({
        'schemaVersion': 1,
        'classes': [],
      });
      expect(await session.submit(empty), isTrue);
      expect(session.state.snapshot!.classes, isEmpty);
      session.disconnect();
      await controller.shutdown(false);
      expect(await session.refresh(), isFalse);
      session.reset(); // Explicit inactive query, no restart or policy replay.
      expect(await session.refresh(), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.inactive);
      expect(session.state.snapshot!.revision, isEmpty);
      expect(await session.submit(config), isFalse);
    },
    skip: !Platform.isWindows || corePath == null || rustPath == null
        ? 'Opt-in: QUANCLASH_TRAFFIC_CLASS_IPC_CORE/RUST, private IPC only'
        : false,
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
