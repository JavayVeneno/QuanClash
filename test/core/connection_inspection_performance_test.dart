import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:fl_clash/core/connection_inspection_session.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/transport.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rust_api/rust_api.dart';
import 'package:win32/win32.dart';

import 'fixtures/inspection_metrics.dart';
import 'fixtures/native_core_handler.dart';

const _config = '''
mixed-port: PORT
bind-address: 127.0.0.1
allow-lan: false
mode: rule
find-process-mode: off
log-level: error
geo-auto-update: false
ipv6: false
external-controller: ''
profile: {store-selected: false, store-fake-ip: false}
sniffer: {enable: false}
tun: {enable: false}
dns: {enable: false}
rules: ['MATCH,DIRECT']
''';

class _ProcessMeter {
  final HANDLE handle;
  final Stopwatch clock = Stopwatch()..start();

  _ProcessMeter(int id)
    : handle = OpenProcess(
        PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
        false,
        id,
      ).value;

  InspectionProcessSample sample() => using((arena) {
    final created = arena<FILETIME>();
    final exited = arena<FILETIME>();
    final kernel = arena<FILETIME>();
    final user = arena<FILETIME>();
    final memory = arena<PROCESS_MEMORY_COUNTERS>();
    memory.ref.cb = sizeOf<PROCESS_MEMORY_COUNTERS>();
    if (!GetProcessTimes(handle, created, exited, kernel, user).value ||
        !GetProcessMemoryInfo(handle, memory, memory.ref.cb).value) {
      throw StateError('Private child OS sampling failed');
    }
    int ticks(FILETIME value) =>
        (value.dwHighDateTime << 32) + value.dwLowDateTime;
    return InspectionProcessSample(
      clock.elapsedMicroseconds,
      (ticks(kernel.ref) + ticks(user.ref)) ~/ 10,
      memory.ref.WorkingSetSize,
    );
  });

  void close() => CloseHandle(handle);
}

class _EchoClient {
  final Socket socket;
  final StreamIterator<Uint8List> input;
  Uint8List _chunk = Uint8List(0);
  int _offset = 0;

  _EchoClient(this.socket) : input = StreamIterator(socket);

  Future<Uint8List> read(int count) async {
    final output = Uint8List(count);
    var offset = 0;
    while (offset < count) {
      if (_offset == _chunk.length) {
        if (!await input.moveNext().timeout(const Duration(seconds: 3))) {
          throw StateError('Local echo closed early');
        }
        _chunk = input.current;
        _offset = 0;
      }
      final size = (count - offset).clamp(0, _chunk.length - _offset);
      output.setRange(offset, offset + size, _chunk, _offset);
      _offset += size;
      offset += size;
    }
    return output;
  }

  static Future<_EchoClient> connect(int port, int destination) async {
    final socket = await Socket.connect(
      InternetAddress.loopbackIPv4,
      port,
      timeout: const Duration(seconds: 3),
    );
    final client = _EchoClient(socket);
    try {
      socket.add([5, 1, 0]);
      await socket.flush();
      expect(await client.read(2), [5, 0]);
      socket.add([
        5,
        1,
        0,
        1,
        127,
        0,
        0,
        1,
        destination >> 8,
        destination & 255,
      ]);
      await socket.flush();
      final reply = await client.read(4);
      expect(reply.take(3), [5, 0, 0]);
      expect(reply[3], anyOf(1, 4));
      await client.read(reply[3] == 1 ? 6 : 18);
      await client.echo(Uint8List.fromList([1, 2, 3, 4]));
      return client;
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  Future<void> echo(Uint8List payload) async {
    socket.add(payload);
    await socket.flush();
    final received = await read(payload.length);
    // Per-byte StreamIterator would dominate this measurement; consume chunks.
    for (var i = 0; i < payload.length; i++) {
      if (received[i] != payload[i]) throw StateError('Local echo mismatch');
    }
  }

  Future<void> close() async {
    socket.destroy();
    await input.cancel();
  }
}

class _ReadMetric {
  int responseBytes = 0;
  int outerDecodeUs = 0;
  int actions = 0;
  bool? full;
  int upserted = 0;
  int updated = 0;
  int removed = 0;

  void response(ActionResult result, int bytes, int decodeUs) {
    if (result.method != ActionMethod.getConnections &&
        result.method != ActionMethod.getConnectionUpdates) {
      return;
    }
    responseBytes += bytes;
    outerDecodeUs += decodeUs;
    actions++;
    if (result.method == ActionMethod.getConnectionUpdates) {
      final packet = result.data as Map<String, dynamic>;
      full = packet['full'] as bool;
      upserted += (packet['upserted'] as List).length;
      updated += (packet['updated'] as List).length;
      removed += (packet['removed'] as List).length;
    }
  }

  Map<String, dynamic> finish(int elapsedUs, int count, int? retainedCharge) =>
      {
        'elapsed_us': elapsedUs,
        'action_count': actions,
        'response_payload_bytes': responseBytes,
        'response_framed_bytes': responseBytes + actions * 4,
        'outer_decode_us': outerDecodeUs,
        'full': full,
        'upserted': upserted,
        'updated': updated,
        'removed': removed,
        'records': count,
        'incremental_retained_charge_bytes': retainedCharge,
      };
}

Future<Map<String, dynamic>> _sampleStage(
  _ProcessMeter core,
  Future<Map<String, dynamic>> Function() work,
) async {
  final samples = [core.sample()];
  Object? failure;
  final timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
    try {
      samples.add(core.sample());
    } catch (error) {
      failure ??= error;
    }
  });
  Map<String, dynamic> result;
  try {
    result = await work();
  } finally {
    timer.cancel();
  }
  samples.add(core.sample());
  if (failure != null) throw StateError('OS sampler failed');
  result['child'] = inspectionProcessSummary(samples);
  return result;
}

Map<String, dynamic> _pollSummary(List<Map<String, dynamic>> reads) => {
  'elapsed_us': inspectionDistribution(
    reads.map((r) => r['elapsed_us'] as int).toList(),
  ),
  'response_framed_bytes': inspectionDistribution(
    reads.map((r) => r['response_framed_bytes'] as int).toList(),
  ),
  'reads': reads,
};

Future<Map<String, dynamic>> _runChild(
  String corePath,
  bool incremental,
) async {
  final home = await Directory.systemTemp.createTemp(
    'quanclash-inspection-perf-',
  );
  final clients = <_EchoClient>[];
  final peers = <Socket>{};
  final echo = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final echoSub = echo.listen((socket) {
    peers.add(socket);
    socket.listen(
      socket.add,
      onError: (Object _) {
        peers.remove(socket);
        socket.destroy();
      },
      onDone: () {
        peers.remove(socket);
        socket.destroy();
      },
    );
  });
  final reservation = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = reservation.port;
  await reservation.close();
  final transport = IPCCoreTransport(
    address:
        r'\\.\pipe\'
        'quanclash-inspection-${p.basename(home.path)}',
  );
  _ReadMetric? activeRead;
  IsolatedCoreHandler? handler;
  Process? child;
  _ProcessMeter? meter;
  StreamSubscription<List<int>>? stdoutSub;
  StreamSubscription<List<int>>? stderrSub;
  ConnectionInspectionSession? session;
  try {
    await File(
      p.join(home.path, 'config.yaml'),
    ).writeAsString(_config.replaceFirst('PORT', '$port'));
    await transport.init().timeout(const Duration(seconds: 5));
    handler = IsolatedCoreHandler(
      transport,
      logActions: false,
      onResponse: (r, b, d) => activeRead?.response(r, b, d),
    );
    child = await Process.start(corePath, [transport.address]);
    stdoutSub = child.stdout.listen((_) {});
    stderrSub = child.stderr.listen((_) {});
    meter = _ProcessMeter(child.pid);
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
    session = controller.createConnectionInspectionSession();
    final inspection = session;
    List<TrackerInfo> records = const [];
    Future<Map<String, dynamic>> read() async {
      final metric = _ReadMetric();
      activeRead = metric;
      final clock = Stopwatch()..start();
      bool? accepted;
      try {
        if (incremental) {
          accepted = await inspection.refresh();
          records = inspection.state.connections;
        } else {
          records = await controller.getConnections();
        }
        clock.stop();
      } finally {
        activeRead = null;
      }
      // Membership validation/accounting after elapsed time, never in core work.
      if (incremental) {
        expect(accepted, isTrue);
        expect(inspection.state.source, ConnectionInspectionSource.incremental);
        expect(inspection.state.status, ConnectionInspectionStatus.ready);
      }
      expect(metric.actions, 1);
      expect(records.map((r) => r.id).toSet(), hasLength(records.length));
      expect(records.every((r) => r.metadata.network == 'tcp'), isTrue);
      return metric.finish(
        clock.elapsedMicroseconds,
        records.length,
        incremental
            ? inspection.state.snapshot.records.values.fold<int>(
                0,
                (n, r) => n + r.chargedBytes,
              )
            : null,
      );
    }

    Future<void> checkReference(int count) async {
      final reference = await controller.getLegacyConnectionSnapshot();
      expect(records, hasLength(count));
      final expected = {for (final r in reference.connections) r.id: r};
      expect({for (final r in records) r.id: r}, expected);
    }

    final result = <String, dynamic>{
      'mode': incremental ? 'incremental_session' : 'legacy_ui_full',
    };
    result['idle_before'] = await _sampleStage(meter, () async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return {};
    });
    for (var i = 0; i < 128; i++) {
      clients.add(await _EchoClient.connect(port, echo.port));
    }
    // No prior incremental call: the core's detached cache is actually cold.
    result['cold_open'] = await _sampleStage(
      meter,
      () async => {'read': await read()},
    );
    expect(records, hasLength(128));
    if (incremental) expect((result['cold_open']['read'])['full'], isTrue);
    await checkReference(128);

    final payload = Uint8List(65536)..fillRange(0, 65536, 0x5a);
    var sequence = 0;
    final warmup = Stopwatch()..start();
    while (warmup.elapsed < const Duration(seconds: 1)) {
      await clients[sequence++ % clients.length].echo(payload);
    }
    result['stable'] = await _sampleStage(meter, () async {
      final reads = <Map<String, dynamic>>[];
      final stage = Stopwatch()..start();
      final roundTrips = <num>[];
      var operations = 0;
      var forwardingMicros = 0;
      Future<void> forwarding() async {
        while (stage.elapsed < const Duration(seconds: 8)) {
          final clock = Stopwatch()..start();
          await clients[sequence++ % clients.length].echo(payload);
          operations++;
          // Bounded deterministic sampling (one per 16), not a percentile of all operations.
          if (operations % 16 == 0 && roundTrips.length < 8192) {
            roundTrips.add(clock.elapsedMicroseconds);
          }
        }
        forwardingMicros = stage.elapsedMicroseconds;
      }

      Future<void> polling() async {
        while (stage.elapsed < const Duration(seconds: 8)) {
          final metric = await read();
          expect(metric['records'], 128);
          if (incremental) {
            expect(metric['full'], isFalse);
            expect(metric['upserted'], 0);
            expect(metric['removed'], 0);
          }
          reads.add(metric);
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }

      await Future.wait([forwarding(), polling()]);
      expect(reads.length, greaterThanOrEqualTo(6));
      return {
        ..._pollSummary(reads),
        'wall_us': stage.elapsedMicroseconds,
        'forwarding_wall_us': forwardingMicros,
        'echo_operations': operations,
        'echo_payload_bytes_both_directions': operations * 2 * payload.length,
        'sampled_echo_rtt_us': inspectionDistribution(roundTrips),
      };
    });
    // Synchronize counters after forwarding stops, before equality comparison.
    await read();
    await checkReference(128);

    for (final replacements in [64, 128]) {
      result[replacements == 64
          ? 'churn_half'
          : 'churn_all'] = await _sampleStage(meter, () async {
        final reads = <Map<String, dynamic>>[];
        final changed = Uint8List.fromList([5, 6, 7, 8]);
        for (var round = 0; round < 8; round++) {
          final clock = Stopwatch()..start();
          for (var i = 0; i < replacements; i++) {
            final index = (round * replacements + i) % clients.length;
            await clients[index].close();
            clients[index] = await _EchoClient.connect(port, echo.port);
          }
          // Quiesce socket closure before snapshot: high membership churn, not a
          // claim of atomic state while sockets are concurrently opening/closing.
          final remaining =
              Duration(milliseconds: replacements * 8) - clock.elapsed;
          if (remaining > Duration.zero) await Future<void>.delayed(remaining);
          for (final client in clients) {
            await client.echo(changed);
          }
          final metric = await read();
          expect(metric['records'], 128);
          if (incremental) {
            final policyFull = replacements == 128;
            expect(metric['full'], policyFull);
            expect(metric['upserted'], replacements);
            expect(metric['removed'], policyFull ? 0 : replacements);
            expect(metric['updated'], 128 - replacements);
          }
          reads.add(metric);
          await checkReference(
            128,
          ); // Outside read timing, included in stage CPU/RSS.
        }
        return _pollSummary(reads);
      });
    }
    for (final client in clients) {
      await client.close();
    }
    clients.clear();
    // No inspection/forced GC during quiet. Expiry is lazy on the next read.
    result['quiet_no_poll_35s'] = await _sampleStage(meter, () async {
      await Future<void>.delayed(const Duration(seconds: 35));
      return {};
    });
    result['reopen_after_quiet'] = await read();
    expect(records, isEmpty);
    if (incremental) expect(result['reopen_after_quiet']['full'], isTrue);
    await checkReference(0);
    inspection.disconnect();
    expect(await handler.stopListener(), isTrue);
    await controller.shutdown(false);
    return result;
  } finally {
    session?.dispose();
    CoreController.resetInstance();
    for (final client in clients) {
      await client.close();
    }
    // Native Windows reader is blocking: only our private child is terminated,
    // before the synchronous transport join, even when measurement fails.
    if (child != null) {
      child.kill();
      await child.exitCode.timeout(const Duration(seconds: 5));
    }
    meter?.close();
    await stdoutSub?.cancel();
    await stderrSub?.cancel();
    if (handler != null) {
      await handler.destroy();
    } else {
      await transport.close();
    }
    for (final peer in peers) {
      peer.destroy();
    }
    await echoSub.cancel();
    await echo.close();
    if (!p.isWithin(
      p.normalize(p.absolute(Directory.systemTemp.path)),
      p.normalize(p.absolute(home.path)),
    )) {
      throw StateError('Fixture cleanup path escaped temp');
    }
    await home.delete(recursive: true);
  }
}

void main() {
  final env = Platform.environment;
  final enabled = env['QUANCLASH_INSPECTION_PERF'] == '1';
  test(
    'opt-in legacy versus incremental native IPC inspection measurement',
    () async {
      final corePath = env['QUANCLASH_CONNECTION_IPC_CORE'];
      final rustPath = env['QUANCLASH_CONNECTION_IPC_RUST'];
      final output = env['QUANCLASH_INSPECTION_PERF_OUTPUT'];
      expect(corePath, isNotNull);
      expect(rustPath, isNotNull);
      expect(output, isNotNull);
      final reportFile = File(output!);
      if (await reportFile.exists()) {
        throw StateError('Choose a new report path');
      }
      Future<String> hash(String path) async =>
          (await sha256.bind(File(path).openRead()).first).toString();
      Future<String> git(List<String> args) async {
        final result = await Process.run('git', args);
        if (result.exitCode != 0) {
          throw StateError('Git provenance unavailable');
        }
        return (result.stdout as String).trim();
      }

      final report = <String, dynamic>{
        'schema_version': 2,
        'recorded_at': DateTime.now().toUtc().toIso8601String(),
        'dart_version': Platform.version,
        'platform': Platform.operatingSystem,
        'logical_cpus': Platform.numberOfProcessors,
        'processor': env['PROCESSOR_IDENTIFIER'],
        'core_sha256': await hash(corePath!),
        'rust_sha256': await hash(rustPath!),
        'harness_sha256': {
          for (final path in [
            'test/core/connection_inspection_performance_test.dart',
            'test/core/fixtures/native_core_handler.dart',
            'test/core/fixtures/inspection_metrics.dart',
            'lib/core/connection_inspection_session.dart',
            'lib/core/connection_updates.dart',
            'lib/core/controller.dart',
            'lib/core/transport.dart',
          ])
            path: await hash(path),
        },
        'wrapper_revision': await git(['rev-parse', 'HEAD']),
        'wrapper_dirty': (await git(['status', '--porcelain'])).isNotEmpty,
        'mihomo_revision': await git([
          '-C',
          'core/Clash.Meta',
          'rev-parse',
          'HEAD',
        ]),
        'mihomo_dirty': (await git([
          '-C',
          'core/Clash.Meta',
          'status',
          '--porcelain',
        ])).isNotEmpty,
        'config_template': _config,
        'parameters': {
          'pairs': 3,
          'live_tcp': 128,
          'stable_seconds': 8,
          'poll_delay_ms': 1000,
          'churn_rounds': 8,
          'replacements_per_round': [64, 128],
          'expected_incremental_churn_full': [false, true],
          'min_round_ms': [512, 1024],
          'quiet_seconds': 35,
          'sampling_target_ms': 200,
          'order': 'legacy/incremental, incremental/legacy, legacy/incremental',
        },
        'limitations': [
          'Flutter test JIT, not release/AOT UI; includes production Rust transport and Dart decode/merge but no sorting/rendering.',
          'Cold means first inspection in a fresh core; shared test VM/JIT persists between children. No claim of statistical significance.',
          'One sequential loopback worker; host/harness/echo CPU competes with core. No remote/TUN/process lookup/DNS/public provider probes.',
          'Response bytes include outer JSON escaping and four-byte native response prefix, exclude requests and unsolicited events.',
          'Read elapsed includes IPC/core/Dart decoding and merge, not isolated server service time; outer-decode subset is instrumented separately.',
          'Only child OS CPU/RSS sampled; timer runs on test isolate and can be delayed. Raw intervals expose gaps, peaks may be missed.',
          'Churn measures quiesced half/full membership replacement per poll, with strict full-reference reads included in stage CPU/RSS, not read latency.',
          'Incremental retained charge is accounting, not heap/RSS; no comparable legacy charge or Flutter retained-heap result.',
          'Quiet has no polling/forced GC; 35 seconds covers lazy cache expiry at next query, not hour-scale leak or reclamation acceptance.',
        ],
        'stages': <Map<String, dynamic>>[],
      };
      await RustLib.init(externalLibrary: ExternalLibrary.open(rustPath));
      try {
        for (var pair = 1; pair <= 3; pair++) {
          for (var order = 1; order <= 2; order++) {
            final incremental = (pair + order).isOdd;
            final result = await _runChild(corePath, incremental);
            result.addAll({'pair': pair, 'order': order});
            (report['stages'] as List).add(result);
          }
        }
      } finally {
        RustLib.dispose();
      }
      // Never overwrite an earlier successful result or publish partial stages.
      await reportFile.create(exclusive: true);
      await reportFile.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(report)}\n',
      );
    },
    skip: !Platform.isWindows || !enabled
        ? 'Opt-in native loopback performance experiment'
        : false,
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
