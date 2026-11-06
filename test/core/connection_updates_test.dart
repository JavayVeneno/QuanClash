import 'dart:math';

import 'package:fl_clash/core/connection_updates.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'fixtures/connection_packets.dart';

class _Handler extends Mock implements CoreHandlerInterface {}

ConnectionInspectionSnapshot _initial() =>
    const ConnectionInspectionSnapshot.empty().apply(
      inspectionPacket(
        inspectionWire(
          cursor: 1,
          upserted: [inspectionRecord(1), inspectionRecord(2)],
        ),
      ),
    );

void main() {
  group('Strict schema decoding', () {
    test('keeps nil/empty, IPv6, provider and full metadata fields', () {
      final packet = inspectionPacket(
        inspectionWire(upserted: [inspectionRecord(1)]),
      );
      final record = packet.upserted.single;
      expect(record.metadata['sourceGeoIP'], isNull);
      expect(record.metadata['destinationGeoIP'], isEmpty);
      expect(record.providerChains, isNull);
      expect(record.metadata['type'], 'Socks5');
      expect(record.tracker.metadata.destinationIP, '::1');
      expect(record.tracker.start.isUtc, isTrue);
      expect(record.tracker.start.hour, 4);
      expect(record.tracker.start.microsecond, 456);
      expect(record.startTimestamp, '2026-10-30T12:30:01.123456789+08:00');
      expect(packet.sampledAt.isUtc, isTrue);
    });

    test(
      'nullable chains have an empty UI view, unknown DNS stays unknown',
      () {
        final wire = inspectionRecord(1)..['chains'] = null;
        wire['metadata']['dnsMode'] = 'unknown';
        wire['providerChains'] = ['fixture-provider'];
        final record = inspectionPacket(
          inspectionWire(upserted: [wire]),
        ).upserted.single;
        expect(record.chains, isNull);
        expect(record.tracker.chains, isEmpty);
        expect(record.metadata['dnsMode'], 'unknown');
        expect(record.tracker.metadata.dnsMode, isNull);
        expect(record.providerChains, ['fixture-provider']);
      },
    );

    test('integer counters retain zero and signed-int64 maximum', () {
      final packet = inspectionPacket(
        inspectionWire(
          upserted: [
            inspectionRecord(1, upload: 0, download: 0x7fffffffffffffff),
          ],
        ),
      );
      expect(packet.upserted.single.tracker.upload, 0);
      expect(packet.upserted.single.tracker.download, 0x7fffffffffffffff);
    });

    for (final field in [
      'schemaVersion',
      'status',
      'full',
      'cursor',
      'baseCursor',
      'sampledAt',
      'uploadTotal',
      'downloadTotal',
      'upserted',
      'updated',
      'removed',
    ]) {
      test('rejects absent/null $field', () {
        expect(
          () => inspectionPacket(inspectionWire()..remove(field)),
          throwsFormatException,
        );
        expect(
          () => inspectionPacket(inspectionWire()..[field] = null),
          throwsFormatException,
        );
      });
    }

    test('rejects numeric coercion, invalid status and cursor shapes', () {
      final mutations = <String, List<Object?>>{
        'schemaVersion': [1.0, '1', true, 2],
        'status': ['unknown', 1],
        'full': [1, 'true'],
        'cursor': ['short', 'G' * 32, 'a' * 33],
        'baseCursor': [inspectionCursor(1)],
        'uploadTotal': [-1, 1.5, '0', true],
        'downloadTotal': [-1, 2.0, '0', false],
      };
      for (final entry in mutations.entries) {
        for (final value in entry.value) {
          expect(
            () => inspectionPacket(inspectionWire()..[entry.key] = value),
            throwsFormatException,
            reason: entry.key,
          );
        }
      }
      expect(
        () => inspectionPacket(inspectionWire(full: false, base: 2, cursor: 2)),
        throwsFormatException,
      );
      expect(
        () =>
            inspectionPacket(inspectionWire(full: false)..['baseCursor'] = ''),
        throwsFormatException,
      );
    });

    test('rejects normalized invalid dates and timezone ambiguity', () {
      for (final time in [
        '2026-02-30T00:00:00Z',
        '2026-10-30T24:00:00Z',
        '2026-10-30T04:00:00',
        '2026-10-30',
        '2026-10-30T04:00:00+08:00',
        '2026-10-30T04:00:00.1234567890Z',
      ]) {
        expect(
          () => inspectionPacket(inspectionWire()..['sampledAt'] = time),
          throwsFormatException,
        );
      }
      for (final time in [
        '2026-13-01T00:00:00Z',
        '2026-10-30T00:00:00+24:00',
      ]) {
        expect(
          () => inspectionPacket(
            inspectionWire(upserted: [inspectionRecord(1)..['start'] = time]),
          ),
          throwsFormatException,
        );
      }
    });

    test('rejects wrong record, metadata, list and counter types', () {
      for (final field in [
        'id',
        'upload',
        'download',
        'start',
        'metadata',
        'chains',
        'providerChains',
        'rule',
        'rulePayload',
      ]) {
        expect(
          () => inspectionPacket(
            inspectionWire(upserted: [inspectionRecord(1)..remove(field)]),
          ),
          throwsFormatException,
        );
      }
      for (final value in [-1, 1.0, '10', true, null]) {
        expect(
          () => inspectionPacket(
            inspectionWire(upserted: [inspectionRecord(1)..['upload'] = value]),
          ),
          throwsFormatException,
        );
        expect(
          () => inspectionPacket(
            inspectionWire(
              full: false,
              updated: [inspectionCounts(1)..['download'] = value],
            ),
          ),
          throwsFormatException,
        );
      }
      for (final entry in <String, Object?>{
        'uid': 1.0,
        'dscp': 256,
        'network': 'garbage',
        'dnsMode': 'garbage',
        'host': null,
        'sourcePort': 80,
        'destinationPort': '65536',
        'inboundPort': '01',
        'sourceGeoIP': [1],
        'processPath': true,
      }.entries) {
        final record = inspectionRecord(1);
        record['metadata'][entry.key] = entry.value;
        expect(
          () => inspectionPacket(inspectionWire(upserted: [record])),
          throwsFormatException,
          reason: entry.key,
        );
      }
      expect(
        () => inspectionPacket(inspectionWire()..['updated'] = {}),
        throwsFormatException,
      );
      expect(
        () => inspectionPacket(inspectionWire()..['upserted'] = [1]),
        throwsFormatException,
      );
      expect(
        () => inspectionPacket(
          inspectionWire(
            upserted: [
              inspectionRecord(1)..['chains'] = [3],
            ],
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => inspectionPacket(
          inspectionWire(upserted: [inspectionRecord(1)..['id'] = 'invalid']),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate and overlapping operations', () {
      for (final wire in [
        inspectionWire(upserted: [inspectionRecord(1), inspectionRecord(1)]),
        inspectionWire(
          full: false,
          updated: [inspectionCounts(1), inspectionCounts(1)],
        ),
        inspectionWire(
          full: false,
          removed: [
            inspectionCounts(1)..['finalCountersVerified'] = false,
            inspectionCounts(1)..['finalCountersVerified'] = false,
          ],
        ),
        inspectionWire(
          full: false,
          upserted: [inspectionRecord(1)],
          updated: [inspectionCounts(1)],
        ),
        inspectionWire(
          full: false,
          updated: [inspectionCounts(1)],
          removed: [inspectionCounts(1)..['finalCountersVerified'] = false],
        ),
      ]) {
        expect(() => inspectionPacket(wire), throwsFormatException);
      }
    });

    test('full and non-ready packets cannot smuggle delta lists', () {
      expect(
        () => inspectionPacket(inspectionWire(updated: [inspectionCounts(1)])),
        throwsFormatException,
      );
      for (final status in ['inactive', 'fallback-required']) {
        expect(
          () => inspectionPacket(inspectionWire(status: status, full: false)),
          throwsFormatException,
        );
        expect(
          () => inspectionPacket(
            inspectionWire(status: status)..['cursor'] = inspectionCursor(1),
          ),
          throwsFormatException,
        );
        expect(
          () => inspectionPacket(
            inspectionWire(status: status, upserted: [inspectionRecord(1)]),
          ),
          throwsFormatException,
        );
      }
      expect(
        () => inspectionPacket(
          inspectionWire(status: 'inactive')..['uploadTotal'] = 1,
        ),
        throwsFormatException,
      );
      expect(
        inspectionPacket(
          inspectionWire(status: 'fallback-required'),
        ).uploadTotal,
        100,
      );
    });

    test(
      'removals require explicit false; do not invent final byte totals',
      () {
        for (final value in [null, true, 0, 'false']) {
          expect(
            () => inspectionPacket(
              inspectionWire(
                full: false,
                removed: [
                  inspectionCounts(1)..['finalCountersVerified'] = value,
                ],
              ),
            ),
            throwsFormatException,
          );
        }
        final packet = inspectionPacket(
          inspectionWire(
            full: false,
            removed: [inspectionCounts(1)..['finalCountersVerified'] = false],
          ),
        );
        expect(packet.removed.single.finalCountersVerified, isFalse);
        expect(packet.removed.single.upload, 10);
      },
    );

    test('checks packet/list size before constructing records', () {
      expect(
        () => ConnectionUpdatePacket.fromJson(
          inspectionWire()..['upserted'] = List.filled(4097, null),
        ),
        throwsFormatException,
      );
      expect(
        () => ConnectionUpdatePacket.fromJson(
          inspectionWire(full: false)
            ..['upserted'] = List.filled(4096, null)
            ..['updated'] = List.filled(4096, null)
            ..['removed'] = [null],
        ),
        throwsFormatException,
      );
      expect(
        () => inspectionPacket(
          inspectionWire(
            upserted: [inspectionRecord(1)..['chains'] = List.filled(8193, '')],
          ),
        ),
        throwsFormatException,
      );
      final record = inspectionRecord(1);
      record['metadata']['host'] = 'x' * (8 * 1024 * 1024);
      expect(
        () =>
            ConnectionUpdatePacket.fromJson(inspectionWire(upserted: [record])),
        throwsFormatException,
      );
    });

    test('input mutation and exposed collections cannot corrupt a packet', () {
      final record = inspectionRecord(1);
      record['metadata']['sourceGeoIP'] = ['AA'];
      final wire = inspectionWire(upserted: [record]);
      final packet = ConnectionUpdatePacket.fromJson(wire);
      record['chains'][0] = 'changed';
      record['metadata']['sourceGeoIP'][0] = 'changed';
      record['metadata']['host'] = 'changed';
      wire['upserted'].clear();
      final parsed = packet.upserted.single;
      expect(parsed.tracker.chains, ['DIRECT']);
      expect(parsed.tracker.metadata.sourceGeoIP, ['AA']);
      expect(parsed.metadata['sourceGeoIP'], ['AA']);
      expect(parsed.tracker.metadata.host, 'fixture.invalid');
      expect(() => packet.upserted.clear(), throwsUnsupportedError);
      expect(() => parsed.metadata.clear(), throwsUnsupportedError);
      expect(() => parsed.chains!.clear(), throwsUnsupportedError);
      expect(
        () => parsed.tracker.metadata.sourceGeoIP.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => (parsed.metadata['sourceGeoIP'] as List).clear(),
        throwsUnsupportedError,
      );
    });

    test(
      'additive fields are ignored without retaining arbitrary payloads',
      () {
        final record = inspectionRecord(1)..['futureField'] = {'nested': []};
        record['metadata']['futureField'] = {'nested': []};
        final packet = inspectionPacket(
          inspectionWire(upserted: [record])..['futureField'] = true,
        );
        expect(
          packet.upserted.single.metadata.containsKey('futureField'),
          isFalse,
        );
        expect(packet.upserted.single.id, inspectionId(1));
      },
    );
  });

  group('Atomic snapshot merge', () {
    test(
      'replaces full snapshots; updates absolute counters and removes IDs',
      () {
        final before = _initial();
        final after = before.apply(
          inspectionPacket(
            inspectionWire(
              full: false,
              base: 1,
              cursor: 2,
              upserted: [inspectionRecord(3)],
              updated: [inspectionCounts(1)],
              removed: [inspectionCounts(2)..['finalCountersVerified'] = false],
            ),
          ),
        );
        expect(after.records.keys, [inspectionId(1), inspectionId(3)]);
        expect(after.records[inspectionId(1)]!.tracker.upload, 10);
        expect(before.records[inspectionId(1)]!.tracker.upload, 1);
        expect(after.cursor, inspectionCursor(2));
        expect(after.uploadTotal, 100);
        final reset = after.apply(
          inspectionPacket(
            inspectionWire(cursor: 3, upserted: [inspectionRecord(4)]),
          ),
        );
        expect(reset.records.keys, [inspectionId(4)]);
        expect(after.records.keys, [inspectionId(1), inspectionId(3)]);
        expect(() => after.records.clear(), throwsUnsupportedError);
      },
    );

    test('upserts replace late metadata, provider chain and counters', () {
      final record = inspectionRecord(1, upload: 30)
        ..['providerChains'] = ['new'];
      record['metadata']['sniffHost'] = 'sniffed.invalid';
      final after = _initial().apply(
        inspectionPacket(inspectionWire(full: false, upserted: [record])),
      );
      expect(
        after.records[inspectionId(1)]!.metadata['sniffHost'],
        'sniffed.invalid',
      );
      expect(after.records[inspectionId(1)]!.providerChains, ['new']);
      expect(after.records[inspectionId(1)]!.tracker.upload, 30);
    });

    test('unchanged records share immutable objects; totals may reset', () {
      final before = _initial();
      final after = before.apply(
        inspectionPacket(
          inspectionWire(full: false)
            ..['uploadTotal'] = 0
            ..['downloadTotal'] = 0,
        ),
      );
      expect(
        after.records[inspectionId(1)],
        same(before.records[inspectionId(1)]),
      );
      expect(after.uploadTotal, 0);
      expect(after.cursor, inspectionCursor(2));
    });

    test('delta on missing/wrong baseline and replay never advance state', () {
      final before = _initial();
      expect(
        () => const ConnectionInspectionSnapshot.empty().apply(
          inspectionPacket(inspectionWire(full: false)),
        ),
        throwsFormatException,
      );
      expect(
        () => before.apply(
          inspectionPacket(inspectionWire(full: false, base: 3)),
        ),
        throwsFormatException,
      );
      final packet = inspectionPacket(inspectionWire(full: false));
      final after = before.apply(packet);
      expect(() => after.apply(packet), throwsFormatException);
      expect(before.cursor, inspectionCursor(1));
      expect(after.cursor, inspectionCursor(2));
    });

    test(
      'missing counter/removal IDs leave valid earlier operations untouched',
      () {
        for (final wire in [
          inspectionWire(
            full: false,
            upserted: [inspectionRecord(3)],
            updated: [inspectionCounts(1), inspectionCounts(999)],
          ),
          inspectionWire(
            full: false,
            updated: [inspectionCounts(1)],
            removed: [inspectionCounts(999)..['finalCountersVerified'] = false],
          ),
        ]) {
          final before = _initial();
          expect(
            () => before.apply(inspectionPacket(wire)),
            throwsFormatException,
          );
          expect(before.cursor, inspectionCursor(1));
          expect(before.records.keys, [inspectionId(1), inspectionId(2)]);
          expect(before.records[inspectionId(1)]!.tracker.upload, 1);
        }
      },
    );

    test('inactive and fallback clear state with distinguishable status', () {
      for (final status in ['inactive', 'fallback-required']) {
        final snapshot = _initial().apply(
          inspectionPacket(inspectionWire(status: status)),
        );
        expect(snapshot.records, isEmpty);
        expect(snapshot.needsFull, isTrue);
        expect(snapshot.requiresLegacyFallback, status == 'fallback-required');
        expect(
          () => snapshot.apply(inspectionPacket(inspectionWire(full: false))),
          throwsFormatException,
        );
        expect(
          snapshot.apply(inspectionPacket(inspectionWire())).status,
          ConnectionUpdateStatus.ready,
        );
      }
    });

    test('map capacity is enforced across otherwise valid deltas', () {
      final before = const ConnectionInspectionSnapshot.empty().apply(
        inspectionPacket(
          inspectionWire(
            cursor: 1,
            upserted: List.generate(4096, inspectionRecord),
          ),
        ),
      );
      expect(
        () => before.apply(
          inspectionPacket(
            inspectionWire(full: false, upserted: [inspectionRecord(4096)]),
          ),
        ),
        throwsFormatException,
      );
      expect(before.records.length, 4096);
      expect(before.cursor, inspectionCursor(1));
    });

    test('retained byte charge is bounded across valid small packets', () {
      final host = 'x' * (512 * 1024);
      Map<String, dynamic> largeRecord(int n) {
        final record = inspectionRecord(n);
        record['metadata']['host'] = host;
        return record;
      }

      final before = const ConnectionInspectionSnapshot.empty().apply(
        ConnectionUpdatePacket.fromJson(
          inspectionWire(cursor: 1, upserted: List.generate(15, largeRecord)),
        ),
      );
      final packet = ConnectionUpdatePacket.fromJson(
        inspectionWire(
          full: false,
          upserted: [largeRecord(20), largeRecord(21)],
        ),
      );
      expect(() => before.apply(packet), throwsFormatException);
      expect(before.records.length, 15);
      expect(before.cursor, inspectionCursor(1));
    });

    test('seeded add/change/count/remove sequences match a full reference', () {
      final random = Random(530);
      var snapshot = const ConnectionInspectionSnapshot.empty().apply(
        inspectionPacket(inspectionWire(cursor: 1)),
      );
      final reference = <int, Map<String, dynamic>>{};
      for (var step = 1; step <= 150; step++) {
        final id = random.nextInt(32);
        final existing = reference[id];
        final adds = <Map<String, dynamic>>[];
        final updates = <Map<String, dynamic>>[];
        final removed = <Map<String, dynamic>>[];
        if (existing == null || random.nextBool()) {
          final record = inspectionRecord(id, upload: step, download: step * 2);
          record['metadata']['host'] = 'step-$step.invalid';
          reference[id] = record;
          adds.add(record);
        } else if (random.nextBool()) {
          removed.add(inspectionCounts(id)..['finalCountersVerified'] = false);
          reference.remove(id);
        } else {
          updates.add(inspectionCounts(id, upload: step, download: step * 3));
          existing['upload'] = step;
          existing['download'] = step * 3;
        }
        snapshot = snapshot.apply(
          inspectionPacket(
            inspectionWire(
              full: false,
              base: step,
              cursor: step + 1,
              upserted: adds,
              updated: updates,
              removed: removed,
            ),
          ),
        );
        final full = inspectionPacket(
          inspectionWire(upserted: reference.values.toList()),
        );
        expect(snapshot.records.length, reference.length);
        for (final record in full.upserted) {
          expect(snapshot.records[record.id]!.tracker, record.tracker);
          expect(snapshot.records[record.id]!.metadata, record.metadata);
        }
      }
    });
  });

  group('Shared facade', () {
    late _Handler handler;
    late CoreController controller;
    setUp(() {
      handler = _Handler();
      controller = CoreController.test(handler);
    });
    tearDown(CoreController.resetInstance);

    test('returns typed packets without changing legacy polling', () async {
      when(
        () => handler.getConnectionUpdates(''),
      ).thenAnswer((_) async => inspectionWire());
      final packet = await controller.getConnectionUpdates('');
      expect(packet.status, ConnectionUpdateStatus.ready);
      verify(() => handler.getConnectionUpdates('')).called(1);
      verifyNever(() => handler.getConnections());
    });

    test(
      'null and invalid responses are errors, not empty successes',
      () async {
        when(
          () => handler.getConnectionUpdates(''),
        ).thenAnswer((_) async => null);
        await expectLater(
          controller.getConnectionUpdates(''),
          throwsStateError,
        );
        when(
          () => handler.getConnectionUpdates(''),
        ).thenAnswer((_) async => inspectionWire()..['schemaVersion'] = 2);
        await expectLater(
          controller.getConnectionUpdates(''),
          throwsFormatException,
        );
      },
    );
  });
}
