import 'dart:async';
import 'dart:convert';

import 'package:quanclash/core/connection_inspection_session.dart';
import 'package:quanclash/core/connection_updates.dart';
import 'package:quanclash/core/controller.dart';
import 'package:quanclash/core/interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures/connection_packets.dart';

class _Handler extends Mock implements CoreHandlerInterface {}

Map<String, dynamic> _legacyWire({List<dynamic>? records = const []}) => {
  'connections': records,
  'uploadTotal': 100,
  'downloadTotal': 200,
};

LegacyConnectionSnapshot _legacy() => LegacyConnectionSnapshot.fromJson(
  _legacyWire(records: [inspectionRecord(9)]),
);

ConnectionUpdatePacket _full({int cursor = 1}) => inspectionPacket(
  inspectionWire(cursor: cursor, upserted: [inspectionRecord(1)]),
);

Future<void> _drain() => Future<void>.delayed(Duration.zero);

void main() {
  group('Caller-driven connection inspection', () {
    test(
      'construction sends nothing and concurrent refreshes share one action',
      () async {
        final gate = Completer<ConnectionUpdatePacket>();
        final cursors = <String>[];
        final session = ConnectionInspectionSession(
          readUpdates: (cursor) {
            cursors.add(cursor);
            return gate.future;
          },
          readLegacy: () async => throw StateError('Unexpected legacy'),
        );
        addTearDown(session.dispose);
        expect(session.state.status, ConnectionInspectionStatus.idle);
        expect(cursors, isEmpty);
        final a = session.refresh();
        final b = session.refresh();
        expect(identical(a, b), isTrue);
        await _drain();
        expect(cursors, ['']);
        expect(session.requestPending, isTrue);
        gate.complete(_full());
        expect(await a, isTrue);
        expect(await b, isTrue);
        expect(session.requestPending, isFalse);
        expect(session.state.source, ConnectionInspectionSource.incremental);
        expect(session.state.connections.single.id, inspectionId(1));
        expect(() => session.state.connections.clear(), throwsUnsupportedError);
        await _drain();
        expect(cursors, ['']); // No queued poll or background work.
      },
    );

    test('serialized delta uses accepted cursor and absolute counts', () async {
      final cursors = <String>[];
      final session = ConnectionInspectionSession(
        readUpdates: (cursor) async {
          cursors.add(cursor);
          return cursors.length == 1
              ? _full()
              : inspectionPacket(
                  inspectionWire(
                    full: false,
                    base: 1,
                    cursor: 2,
                    updated: [inspectionCounts(1)],
                  ),
                );
        },
        readLegacy: () async => _legacy(),
      );
      addTearDown(session.dispose);
      await session.refresh();
      await session.refresh();
      expect(cursors, ['', inspectionCursor(1)]);
      expect(session.state.snapshot.cursor, inspectionCursor(2));
      expect(session.state.connections.single.upload, 10);
      expect(session.state.uploadTotal, 100);
      expect(session.state.downloadTotal, 200);
    });

    for (final operation in ['reset', 'disconnect', 'dispose']) {
      for (final response in ['full', 'delta', 'error']) {
        test(
          '$operation rejects obsolete $response including fallback',
          () async {
            final gate = Completer<ConnectionUpdatePacket>();
            var calls = 0;
            var legacyCalls = 0;
            final session = ConnectionInspectionSession(
              readUpdates: (_) async => ++calls == 1 ? _full() : gate.future,
              readLegacy: () async {
                legacyCalls++;
                return _legacy();
              },
            );
            addTearDown(session.dispose);
            await session.refresh();
            final pending = session.refresh();
            await _drain();
            switch (operation) {
              case 'reset':
                session.reset();
              case 'disconnect':
                session.disconnect();
              case 'dispose':
                session.dispose();
            }
            final invalidated = session.state;
            expect(invalidated.connections, isEmpty);
            if (operation == 'reset') {
              expect(identical(session.refresh(), pending), isTrue);
            } else {
              expect(await session.refresh(), isFalse);
            }
            switch (response) {
              case 'full':
                gate.complete(_full(cursor: 3));
              case 'delta':
                gate.complete(
                  inspectionPacket(
                    inspectionWire(full: false, updated: [inspectionCounts(1)]),
                  ),
                );
              case 'error':
                gate.completeError(StateError('secret-obsolete-error'));
            }
            expect(await pending, isFalse);
            expect(identical(session.state, invalidated), isTrue);
            expect(legacyCalls, 0);
            expect(session.usesLegacy, isFalse);
          },
        );
      }

      test('$operation rejects obsolete legacy result', () async {
        final gate = Completer<LegacyConnectionSnapshot>();
        final session = ConnectionInspectionSession(
          readUpdates: (_) async => throw StateError('Unsupported'),
          readLegacy: () => gate.future,
        );
        addTearDown(session.dispose);
        final pending = session.refresh();
        await _drain();
        switch (operation) {
          case 'reset':
            session.reset();
          case 'disconnect':
            session.disconnect();
          case 'dispose':
            session.dispose();
        }
        final invalidated = session.state;
        gate.complete(_legacy());
        expect(await pending, isFalse);
        expect(identical(session.state, invalidated), isTrue);
      });
    }

    test(
      'reset re-enables disconnect but cannot resurrect disposed session',
      () async {
        final cursors = <String>[];
        final session = ConnectionInspectionSession(
          readUpdates: (cursor) async {
            cursors.add(cursor);
            return _full();
          },
          readLegacy: () async => _legacy(),
        );
        await session.refresh();
        session.disconnect();
        expect(await session.refresh(), isFalse);
        expect(session.state.status, ConnectionInspectionStatus.inactive);
        session.reset();
        expect(await session.refresh(), isTrue);
        expect(cursors, ['', '']);
        session.dispose();
        session.reset();
        expect(await session.refresh(), isFalse);
        expect(session.state.status, ConnectionInspectionStatus.inactive);
      },
    );

    test(
      'reset before scheduled work starts sends no obsolete action',
      () async {
        var calls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) async {
            calls++;
            return _full();
          },
          readLegacy: () async => _legacy(),
        );
        addTearDown(session.dispose);
        final pending = session.refresh();
        session.reset();
        expect(await pending, isFalse);
        expect(calls, 0);
        expect(await session.refresh(), isTrue);
      },
    );

    for (final reason in ['unsupported', 'malformed', 'capacity']) {
      test('$reason falls back once and pins legacy until reset', () async {
        var updateCalls = 0;
        var legacyCalls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) async {
            updateCalls++;
            switch (reason) {
              case 'unsupported':
                throw StateError('Unsupported');
              case 'malformed':
                throw const FormatException('secret-schema');
              default:
                return inspectionPacket(
                  inspectionWire(status: 'fallback-required'),
                );
            }
          },
          readLegacy: () async {
            legacyCalls++;
            return _legacy();
          },
        );
        addTearDown(session.dispose);
        expect(await session.refresh(), isTrue);
        expect(session.usesLegacy, isTrue);
        expect(session.state.source, ConnectionInspectionSource.legacy);
        expect(session.state.connections.single.id, inspectionId(9));
        expect(session.state.snapshot.cursor, isEmpty);
        expect(session.state.failure, switch (reason) {
          'unsupported' => ConnectionInspectionFailure.updateUnavailable,
          'malformed' => ConnectionInspectionFailure.invalidUpdate,
          _ => ConnectionInspectionFailure.capacity,
        });
        await session.refresh();
        expect(updateCalls, 1);
        expect(legacyCalls, 2);
        session.reset();
        await session.refresh();
        expect(updateCalls, 2);
        expect(legacyCalls, 3);
      });
    }

    test(
      'inactive is not successful empty ready and does not use legacy',
      () async {
        var calls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) async => ++calls == 1
              ? inspectionPacket(inspectionWire(status: 'inactive'))
              : _full(),
          readLegacy: () async => throw StateError('Unexpected legacy'),
        );
        addTearDown(session.dispose);
        expect(await session.refresh(), isTrue);
        expect(session.state.status, ConnectionInspectionStatus.inactive);
        expect(session.state.connections, isEmpty);
        expect(session.state.uploadTotal, 0);
        expect(session.usesLegacy, isFalse);
        expect(await session.refresh(), isTrue);
        expect(session.state.status, ConnectionInspectionStatus.ready);
      },
    );

    test('bad base gets only one fresh full resync', () async {
      final cursors = <String>[];
      final session = ConnectionInspectionSession(
        readUpdates: (cursor) async {
          cursors.add(cursor);
          return switch (cursors.length) {
            1 => _full(),
            2 => inspectionPacket(
              inspectionWire(full: false, base: 99, cursor: 2),
            ),
            _ => _full(cursor: 3),
          };
        },
        readLegacy: () async => throw StateError('Unexpected legacy'),
      );
      addTearDown(session.dispose);
      await session.refresh();
      expect(await session.refresh(), isTrue);
      expect(cursors, ['', inspectionCursor(1), '']);
      expect(session.state.snapshot.cursor, inspectionCursor(3));
      expect(session.usesLegacy, isFalse);
    });

    for (final lateError in [false, true]) {
      test(
        'reset rejects pending resync ${lateError ? 'error' : 'full'}',
        () async {
          final gate = Completer<ConnectionUpdatePacket>();
          final started = Completer<void>();
          var calls = 0;
          final session = ConnectionInspectionSession(
            readUpdates: (_) {
              if (++calls == 1) {
                return Future.value(
                  inspectionPacket(inspectionWire(full: false)),
                );
              }
              started.complete();
              return gate.future;
            },
            readLegacy: () async => throw StateError('Unexpected legacy'),
          );
          addTearDown(session.dispose);
          final pending = session.refresh();
          await started.future;
          session.reset();
          final invalidated = session.state;
          if (lateError) {
            gate.completeError(StateError('secret-stale-resync'));
          } else {
            gate.complete(_full());
          }
          expect(await pending, isFalse);
          expect(identical(session.state, invalidated), isTrue);
          expect(session.usesLegacy, isFalse);
          expect(calls, 2);
        },
      );
    }

    test(
      'reset rejects obsolete legacy error without changing failure state',
      () async {
        final gate = Completer<LegacyConnectionSnapshot>();
        final started = Completer<void>();
        final session = ConnectionInspectionSession(
          readUpdates: (_) async => throw StateError('Unsupported'),
          readLegacy: () {
            started.complete();
            return gate.future;
          },
        );
        addTearDown(session.dispose);
        final pending = session.refresh();
        await started.future;
        session.reset();
        gate.completeError(StateError('secret-stale-legacy'));
        expect(await pending, isFalse);
        expect(session.state.failure, isNull);
        expect(session.state.status, ConnectionInspectionStatus.idle);
      },
    );

    test(
      'timeout in an obsolete epoch cannot pin new epoch to legacy',
      () async {
        final gate = Completer<ConnectionUpdatePacket>();
        final started = Completer<void>();
        final session = ConnectionInspectionSession(
          readUpdates: (_) {
            started.complete();
            return gate.future;
          },
          readLegacy: () async => _legacy(),
          requestTimeout: const Duration(milliseconds: 20),
        );
        addTearDown(session.dispose);
        final pending = session.refresh();
        await started.future;
        session.reset();
        expect(await pending, isFalse);
        expect(session.usesLegacy, isFalse);
        expect(session.state.failure, isNull);
        expect(await session.refresh(), isFalse);
        gate.complete(_full());
        await _drain();
        expect(session.requestPending, isFalse);
      },
    );

    for (final response in ['error', 'delta', 'capacity']) {
      test(
        'failed $response resync bounds actions and defers legacy',
        () async {
          var calls = 0;
          var legacyCalls = 0;
          final session = ConnectionInspectionSession(
            readUpdates: (_) async {
              calls++;
              if (calls == 1) return _full();
              if (calls == 2) {
                return inspectionPacket(inspectionWire(full: false, base: 99));
              }
              switch (response) {
                case 'error':
                  throw StateError('secret-resync-error');
                case 'capacity':
                  return inspectionPacket(
                    inspectionWire(status: 'fallback-required'),
                  );
                default:
                  return inspectionPacket(inspectionWire(full: false));
              }
            },
            readLegacy: () async {
              legacyCalls++;
              return _legacy();
            },
          );
          addTearDown(session.dispose);
          await session.refresh();
          expect(await session.refresh(), isTrue);
          expect(calls, 3);
          expect(legacyCalls, 0);
          expect(session.state.status, ConnectionInspectionStatus.unavailable);
          expect(session.state.connections, isEmpty);
          expect(
            session.state.failure,
            response == 'capacity'
                ? ConnectionInspectionFailure.capacity
                : ConnectionInspectionFailure.resyncFailed,
          );
          expect(await session.refresh(), isTrue);
          expect(calls, 3);
          expect(legacyCalls, 1);
        },
      );
    }

    for (final lateError in [false, true]) {
      test(
        'timeout blocks hung actions and ignores late ${lateError ? 'error' : 'success'}',
        () async {
          final gate = Completer<ConnectionUpdatePacket>();
          var updates = 0;
          var legacyCalls = 0;
          final session = ConnectionInspectionSession(
            readUpdates: (_) {
              updates++;
              return gate.future;
            },
            readLegacy: () async {
              legacyCalls++;
              return _legacy();
            },
            requestTimeout: const Duration(milliseconds: 20),
          );
          addTearDown(session.dispose);
          expect(await session.refresh(), isTrue);
          expect(
            session.state.failure,
            ConnectionInspectionFailure.requestTimeout,
          );
          expect(session.requestPending, isTrue);
          final unavailable = session.state;
          for (var i = 0; i < 20; i++) {
            expect(await session.refresh(), isFalse);
          }
          expect(updates, 1);
          expect(legacyCalls, 0);
          if (lateError) {
            gate.completeError(StateError('secret-late'));
          } else {
            gate.complete(_full());
          }
          await _drain();
          expect(identical(session.state, unavailable), isTrue);
          expect(session.requestPending, isFalse);
          expect(await session.refresh(), isTrue);
          expect(legacyCalls, 1);
          expect(session.state.source, ConnectionInspectionSource.legacy);
        },
      );
    }

    test(
      'reset after timeout preserves callback busy gate, then restarts full',
      () async {
        final gate = Completer<ConnectionUpdatePacket>();
        var calls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) =>
              ++calls == 1 ? gate.future : Future.value(_full()),
          readLegacy: () async => throw StateError('Unexpected legacy'),
          requestTimeout: const Duration(milliseconds: 20),
        );
        addTearDown(session.dispose);
        await session.refresh();
        session.reset();
        expect(await session.refresh(), isFalse);
        gate.complete(_full(cursor: 99));
        await _drain();
        expect(session.state.status, ConnectionInspectionStatus.idle);
        expect(await session.refresh(), isTrue);
        expect(session.state.snapshot.cursor, inspectionCursor(1));
      },
    );

    test(
      'legacy failure clears previously live state and retains no raw error',
      () async {
        var calls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) async =>
              ++calls == 1 ? _full() : throw StateError('secret-update'),
          readLegacy: () async => throw const FormatException('secret-legacy'),
        );
        addTearDown(session.dispose);
        await session.refresh();
        expect(await session.refresh(), isTrue);
        expect(session.state.status, ConnectionInspectionStatus.unavailable);
        expect(session.state.connections, isEmpty);
        expect(session.state.snapshot.records, isEmpty);
        expect(session.state.uploadTotal, 0);
        expect(session.state.source, isNull);
        expect(
          session.state.failure,
          ConnectionInspectionFailure.legacyUnavailable,
        );
      },
    );

    test('legacy timeout bounds actions too', () async {
      final gate = Completer<LegacyConnectionSnapshot>();
      var calls = 0;
      final session = ConnectionInspectionSession(
        readUpdates: (_) async => throw StateError('Unsupported'),
        readLegacy: () {
          calls++;
          return gate.future;
        },
        requestTimeout: const Duration(milliseconds: 20),
      );
      addTearDown(session.dispose);
      await session.refresh();
      expect(session.state.failure, ConnectionInspectionFailure.requestTimeout);
      expect(await session.refresh(), isFalse);
      expect(calls, 1);
      gate.complete(_legacy());
      await _drain();
      expect(session.state.status, ConnectionInspectionStatus.unavailable);
    });

    test(
      'resync timeout defers legacy and keeps hung action bounded',
      () async {
        final gate = Completer<ConnectionUpdatePacket>();
        var calls = 0;
        final session = ConnectionInspectionSession(
          readUpdates: (_) => ++calls == 1
              ? Future.value(inspectionPacket(inspectionWire(full: false)))
              : gate.future,
          readLegacy: () async => _legacy(),
          requestTimeout: const Duration(milliseconds: 20),
        );
        addTearDown(session.dispose);
        await session.refresh();
        expect(
          session.state.failure,
          ConnectionInspectionFailure.requestTimeout,
        );
        expect(calls, 2);
        expect(await session.refresh(), isFalse);
        gate.complete(_full());
        await _drain();
        await session.refresh();
        expect(session.state.source, ConnectionInspectionSource.legacy);
      },
    );

    test('invalid timeout rejected', () {
      for (final timeout in [
        Duration.zero,
        const Duration(seconds: -1),
        const Duration(seconds: 16),
      ]) {
        expect(
          () => ConnectionInspectionSession(
            readUpdates: (_) async => _full(),
            readLegacy: () async => _legacy(),
            requestTimeout: timeout,
          ),
          throwsArgumentError,
        );
      }
    });
  });

  group('Strict legacy full action', () {
    test('explicit nil is valid empty, absent field is not', () {
      expect(
        LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: null),
        ).connections,
        isEmpty,
      );
      expect(
        () => LegacyConnectionSnapshot.fromJson(
          _legacyWire()..remove('connections'),
        ),
        throwsFormatException,
      );
    });

    test(
      'older metadata defaults and nullable DNS/chains remain compatible',
      () {
        final record = inspectionRecord(1);
        record['metadata'] = {'network': 'tcp', 'dnsMode': null};
        record['chains'] = null;
        final snapshot = LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: [record]),
        );
        expect(snapshot.connections.single.metadata.host, '');
        expect(snapshot.connections.single.metadata.dnsMode, isNull);
        expect(snapshot.connections.single.chains, isEmpty);
      },
    );

    test('invalid fields never coerce numbers or default required records', () {
      for (final bad in [null, -1, 1.5, '10', 0x8000000000000000]) {
        expect(
          () => LegacyConnectionSnapshot.fromJson(
            _legacyWire()..['uploadTotal'] = bad,
          ),
          throwsFormatException,
        );
        final record = inspectionRecord(1)..['download'] = bad;
        expect(
          () =>
              LegacyConnectionSnapshot.fromJson(_legacyWire(records: [record])),
          throwsFormatException,
        );
      }
      for (final key in [
        'id',
        'upload',
        'download',
        'start',
        'metadata',
        'chains',
        'rule',
        'rulePayload',
      ]) {
        expect(
          () => LegacyConnectionSnapshot.fromJson(
            _legacyWire(records: [inspectionRecord(1)..remove(key)]),
          ),
          throwsFormatException,
        );
      }
      for (final bad in [1, 'unsupported']) {
        final record = inspectionRecord(1);
        record['metadata']['dnsMode'] = bad;
        expect(
          () =>
              LegacyConnectionSnapshot.fromJson(_legacyWire(records: [record])),
          throwsFormatException,
        );
      }
      expect(
        () => LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: [inspectionRecord(1), inspectionRecord(1)]),
        ),
        throwsFormatException,
      );
    });

    test(
      'detaches all retained collections and allows more than delta cap',
      () {
        final record = inspectionRecord(1);
        record['metadata']['sourceGeoIP'] = ['CN'];
        final result = LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: [record]),
        );
        record['metadata']['sourceGeoIP'][0] = 'mutated';
        record['chains'][0] = 'mutated';
        expect(result.connections.single.metadata.sourceGeoIP, ['CN']);
        expect(result.connections.single.chains, ['DIRECT']);
        expect(() => result.connections.clear(), throwsUnsupportedError);
        expect(
          () => result.connections.single.metadata.sourceGeoIP.clear(),
          throwsUnsupportedError,
        );
        expect(
          LegacyConnectionSnapshot.fromJson(
            _legacyWire(records: List.generate(4097, inspectionRecord)),
          ).connections,
          hasLength(4097),
        );
      },
    );

    test('legacy count and retained charge fail visibly, never truncate', () {
      expect(
        () => LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: List.generate(16385, inspectionRecord)),
        ),
        throwsFormatException,
      );
      final record = inspectionRecord(1)
        ..['rulePayload'] = 'x' * (8 * 1024 * 1024);
      expect(
        () => LegacyConnectionSnapshot.fromJson(_legacyWire(records: [record])),
        throwsFormatException,
      );
      final listRecord = inspectionRecord(1)
        ..['chains'] = List.filled(8193, 'x');
      expect(
        () => LegacyConnectionSnapshot.fromJson(
          _legacyWire(records: [listRecord]),
        ),
        throwsFormatException,
      );
    });
  });

  group('Controller session factory', () {
    late _Handler handler;
    late CoreController controller;
    setUp(() {
      handler = _Handler();
      controller = CoreController.test(handler);
    });
    tearDown(CoreController.resetInstance);

    test(
      'missing update uses real full facade, legacy pinned per epoch',
      () async {
        when(
          () => handler.getConnectionUpdates(''),
        ).thenAnswer((_) async => null);
        when(() => handler.getConnections()).thenAnswer(
          (_) async => jsonEncode(_legacyWire(records: [inspectionRecord(9)])),
        );
        final session = controller.createConnectionInspectionSession();
        addTearDown(session.dispose);
        await session.refresh();
        await session.refresh();
        verify(() => handler.getConnectionUpdates('')).called(1);
        verify(() => handler.getConnections()).called(2);
        expect(session.state.source, ConnectionInspectionSource.legacy);
        expect(
          session.state.failure,
          ConnectionInspectionFailure.updateUnavailable,
        );
      },
    );

    test(
      'malformed full root or missing totals is an error, not empty success',
      () async {
        for (final wire in ['null', '[]', '{}', '{"connections":null}']) {
          when(() => handler.getConnections()).thenAnswer((_) async => wire);
          await expectLater(
            controller.getLegacyConnectionSnapshot(),
            throwsFormatException,
          );
        }
      },
    );
  });
}
