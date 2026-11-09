import 'dart:async';

import 'package:quanclash/core/traffic_class.dart';
import 'package:quanclash/core/traffic_class_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/traffic_class_packets.dart';

class _Backend {
  int reads = 0;
  final writes = <({TrafficClassConfig config, String revision})>[];
  Future<TrafficClassSnapshot> Function() read = () async => classState();
  Future<TrafficClassSnapshot> Function(TrafficClassConfig, String) write =
      (config, _) async => classState(revision: 2, config: config);

  TrafficClassSession session({Duration? timeout}) => TrafficClassSession(
    read: () {
      reads++;
      return read();
    },
    write: (config, revision) {
      writes.add((config: config, revision: revision));
      return write(config, revision);
    },
    requestTimeout: timeout ?? const Duration(seconds: 5),
  );
}

Future<void> _turn() => Future<void>.delayed(Duration.zero);

void main() {
  test('construction and lifecycle send no requests', () async {
    final backend = _Backend();
    final session = backend.session();
    addTearDown(session.dispose);
    expect(session.state.status, TrafficClassSessionStatus.idle);
    expect(session.state.snapshot, isNull);
    expect(session.state.needsRefresh, isTrue);
    expect(session.requestPending, isFalse);
    expect(await session.submit(classConfig()), isFalse);
    session.reset();
    session.disconnect();
    expect(session.state.status, TrafficClassSessionStatus.inactive);
    expect(await session.refresh(), isFalse);
    session.dispose();
    session.reset();
    expect(await session.refresh(), isFalse);
    expect(await session.submit(classConfig()), isFalse);
    expect(backend.reads, 0);
    expect(backend.writes, isEmpty);
  });

  test('deadline must be positive and at most fifteen seconds', () {
    for (final timeout in [
      Duration.zero,
      const Duration(microseconds: -1),
      const Duration(seconds: 16),
    ]) {
      expect(() => _Backend().session(timeout: timeout), throwsArgumentError);
    }
    _Backend().session(timeout: const Duration(seconds: 15)).dispose();
  });

  test('concurrent reads coalesce without queuing any writes', () async {
    final backend = _Backend();
    final gate = Completer<TrafficClassSnapshot>();
    backend.read = () => gate.future;
    final session = backend.session();
    addTearDown(session.dispose);
    final first = session.refresh();
    final second = session.refresh();
    expect(identical(first, second), isTrue);
    expect(await session.submit(classConfig()), isFalse);
    expect(backend.reads, 1);
    expect(session.requestPending, isTrue);
    gate.complete(classState());
    expect(await first, isTrue);
    expect(await second, isTrue);
    await _turn();
    expect(backend.reads, 1);
    expect(backend.writes, isEmpty);
    expect(session.requestPending, isFalse);
    expect(session.state.needsRefresh, isFalse);
  });

  test(
    'submit uses accepted CAS base and retains config only after ack',
    () async {
      final backend = _Backend();
      final gate = Completer<TrafficClassSnapshot>();
      backend.write = (_, _) => gate.future;
      final session = backend.session();
      addTearDown(session.dispose);
      final config = classConfig();
      expect(await session.refresh(), isTrue);
      final write = session.submit(config);
      await _turn();
      expect(backend.writes.single.revision, classRevision(1));
      expect(identical(backend.writes.single.config, config), isTrue);
      expect(session.state.acknowledgedConfig, isNull);
      expect(await session.submit(config), isFalse);
      expect(await session.refresh(), isFalse);
      gate.complete(classState(revision: 2, config: config));
      expect(await write, isTrue);
      expect(identical(session.state.acknowledgedConfig, config), isTrue);
      expect(session.state.snapshot!.revision, classRevision(2));
      expect(session.state.writeOutcomeUncertain, isFalse);
      backend.write = (config, _) async =>
          classState(revision: 3, config: config);
      expect(await session.submit(config), isTrue);
      expect(backend.writes.last.revision, classRevision(2));
      expect(backend.reads, 1);
    },
  );

  test(
    'inactive snapshot is distinct from prepared empty and forbids writes',
    () async {
      final backend = _Backend()..read = () async => classState(inactive: true);
      final session = backend.session();
      addTearDown(session.dispose);
      expect(await session.refresh(), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.inactive);
      expect(session.state.snapshot!.status, TrafficClassStatus.inactive);
      expect(await session.submit(classConfig()), isFalse);
      backend.read = () async => classState();
      expect(await session.refresh(), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.prepared);
      expect(session.state.snapshot!.classes, isEmpty);
      expect(await session.submit(classConfig()), isTrue);
    },
  );

  test('explicit empty submission clears acknowledged config', () async {
    final session = _Backend().session();
    addTearDown(session.dispose);
    final empty = TrafficClassConfig.fromJson({
      'schemaVersion': 1,
      'classes': [],
    });
    expect(await session.refresh(), isTrue);
    expect(await session.submit(empty), isTrue);
    expect(session.state.snapshot!.classes, isEmpty);
    expect(session.state.acknowledgedConfig!.classes, isEmpty);
  });

  test('read summary preserves ack only at the same revision', () async {
    final backend = _Backend();
    final session = backend.session();
    addTearDown(session.dispose);
    final config = classConfig();
    expect(await session.refresh(), isTrue);
    expect(await session.submit(config), isTrue);
    backend.read = () async => classState(revision: 2, config: config);
    expect(await session.refresh(), isTrue);
    expect(identical(session.state.acknowledgedConfig, config), isTrue);
    backend.read = () async => classState(revision: 3, config: config);
    expect(await session.refresh(), isTrue);
    expect(session.state.acknowledgedConfig, isNull);
    expect(session.state.needsRefresh, isFalse);
  });

  for (final invalid in [
    'same revision',
    'ID',
    'priority',
    'inactive',
    'order',
  ]) {
    test('rejects $invalid ack without retry or claiming selectors', () async {
      final config = TrafficClassConfig.fromJson({
        'schemaVersion': 1,
        'classes': [
          ...classConfigWire()['classes'],
          ...classConfigWire(id: 'second')['classes'],
        ],
      });
      final backend = _Backend();
      backend.write = (_, _) async {
        final wire = classStateWire(revision: 2, config: config);
        switch (invalid) {
          case 'same revision':
            wire['revision'] = classRevision(1);
          case 'ID':
            wire['classes'][0]['id'] = 'other';
          case 'priority':
            wire['classes'][0]['priority'] = 7;
          case 'inactive':
            return classState(inactive: true);
          case 'order':
            wire['classes'] = (wire['classes'] as List).reversed.toList();
        }
        return TrafficClassSnapshot.fromJson(wire);
      };
      final session = backend.session();
      addTearDown(session.dispose);
      expect(await session.refresh(), isTrue);
      expect(await session.submit(config), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.unavailable);
      expect(session.state.failure, TrafficClassFailure.invalidAcknowledgment);
      expect(session.state.snapshot, isNull);
      expect(session.state.acknowledgedConfig, isNull);
      expect(session.state.needsRefresh, isTrue);
      expect(session.state.writeOutcomeUncertain, isTrue);
      expect(await session.submit(config), isFalse);
      expect(backend.writes, hasLength(1));
    });
  }

  test('membership-matched priority mismatch also rejects', () async {
    final backend = _Backend()
      ..write = (_, _) async =>
          classState(revision: 2, config: classConfig(priority: 7));
    final session = backend.session();
    addTearDown(session.dispose);
    expect(await session.refresh(), isTrue);
    expect(await session.submit(classConfig()), isTrue);
    expect(session.state.failure, TrafficClassFailure.invalidAcknowledgment);
  });

  for (final failure in ['read', 'write']) {
    test(
      '$failure error is redacted and never retried automatically',
      () async {
        final backend = _Backend();
        final session = backend.session();
        addTearDown(session.dispose);
        if (failure == 'read') {
          backend.read = () async => throw StateError('secret-path/selector');
          expect(await session.refresh(), isTrue);
        } else {
          expect(await session.refresh(), isTrue);
          backend.write = (_, _) async =>
              throw StateError('secret-path/selector');
          expect(await session.submit(classConfig()), isTrue);
        }
        expect(session.state.failure, TrafficClassFailure.unavailable);
        expect(session.state.snapshot, isNull);
        expect(session.state.acknowledgedConfig, isNull);
        expect(session.state.writeOutcomeUncertain, failure == 'write');
        expect(session.state.failure.toString(), isNot(contains('secret')));
        expect(await session.submit(classConfig()), isFalse);
        await _turn();
        expect(backend.reads, 1);
        expect(backend.writes, hasLength(failure == 'write' ? 1 : 0));
      },
    );
  }

  for (final operation in ['read', 'write']) {
    for (final lifecycle in ['reset', 'disconnect', 'dispose']) {
      for (final error in [false, true]) {
        test(
          '$lifecycle rejects obsolete $operation ${error ? 'error' : 'ack'}',
          () async {
            final backend = _Backend();
            final session = backend.session();
            addTearDown(session.dispose);
            final gate = Completer<TrafficClassSnapshot>();
            late Future<bool> pending;
            if (operation == 'read') {
              backend.read = () => gate.future;
              pending = session.refresh();
            } else {
              expect(await session.refresh(), isTrue);
              backend.write = (_, _) => gate.future;
              pending = session.submit(classConfig());
            }
            await _turn();
            switch (lifecycle) {
              case 'reset':
                session.reset();
              case 'disconnect':
                session.disconnect();
              case 'dispose':
                session.dispose();
            }
            final invalidated = session.state;
            expect(invalidated.writeOutcomeUncertain, operation == 'write');
            expect(invalidated.snapshot, isNull);
            expect(invalidated.acknowledgedConfig, isNull);
            expect(await session.submit(classConfig()), isFalse);
            if (error) {
              gate.completeError(StateError('secret-stale-selector'));
            } else {
              gate.complete(classState(revision: 2, config: classConfig()));
            }
            expect(await pending, isFalse);
            expect(identical(session.state, invalidated), isTrue);
            expect(session.requestPending, isFalse);
            if (lifecycle != 'reset') expect(await session.refresh(), isFalse);
            session.reset();
            backend.read = () async => classState(revision: 3);
            expect(await session.refresh(), lifecycle != 'dispose');
            if (lifecycle != 'dispose') {
              expect(session.state.snapshot!.revision, classRevision(3));
              // Reconnection reads a new base; it must not replay the old write.
              expect(session.state.acknowledgedConfig, isNull);
              expect(session.state.writeOutcomeUncertain, operation == 'write');
            }
            expect(backend.writes, hasLength(operation == 'write' ? 1 : 0));
          },
        );
      }
    }
  }

  test('invalidation before microtask admission performs no write', () async {
    final backend = _Backend();
    final session = backend.session();
    addTearDown(session.dispose);
    expect(await session.refresh(), isTrue);
    final write = session.submit(classConfig());
    session.reset();
    expect(await write, isFalse);
    expect(backend.writes, isEmpty);
    expect(session.state.writeOutcomeUncertain, isFalse);
    final read = session.refresh();
    session.disconnect();
    expect(await read, isFalse);
    expect(backend.reads, 1);
  });

  test(
    'reset during read shares obsolete work, never queues another read',
    () async {
      final backend = _Backend();
      final gate = Completer<TrafficClassSnapshot>();
      backend.read = () => gate.future;
      final session = backend.session();
      addTearDown(session.dispose);
      final old = session.refresh();
      await _turn();
      session.reset();
      expect(identical(session.refresh(), old), isTrue);
      gate.complete(classState());
      expect(await old, isFalse);
      expect(backend.reads, 1);
      backend.read = () async => classState(revision: 3);
      expect(await session.refresh(), isTrue);
      expect(backend.reads, 2);
    },
  );

  for (final operation in ['read', 'write']) {
    for (final error in [false, true]) {
      test(
        '$operation timeout gates callbacks and discards late ${error ? 'error' : 'success'}',
        () async {
          final backend = _Backend();
          final session = backend.session(
            timeout: const Duration(milliseconds: 10),
          );
          addTearDown(session.dispose);
          final gate = Completer<TrafficClassSnapshot>();
          late Future<bool> pending;
          if (operation == 'read') {
            backend.read = () => gate.future;
            pending = session.refresh();
          } else {
            expect(await session.refresh(), isTrue);
            backend.write = (_, _) => gate.future;
            pending = session.submit(classConfig());
          }
          expect(await pending, isTrue);
          expect(session.state.failure, TrafficClassFailure.timeout);
          expect(session.state.writeOutcomeUncertain, operation == 'write');
          expect(session.state.needsRefresh, isTrue);
          expect(session.requestPending, isTrue);
          expect(await session.refresh(), isFalse);
          expect(await session.submit(classConfig()), isFalse);
          session.disconnect();
          session.reset();
          final invalidated = session.state;
          expect(await session.refresh(), isFalse);
          if (error) {
            gate.completeError(StateError('secret-late-selector'));
          } else {
            gate.complete(classState(revision: 2, config: classConfig()));
          }
          await _turn();
          expect(identical(session.state, invalidated), isTrue);
          expect(session.requestPending, isFalse);
          backend.read = () async =>
              classState(revision: 2, config: classConfig());
          expect(await session.refresh(), isTrue);
          expect(session.state.acknowledgedConfig, isNull);
          expect(session.state.writeOutcomeUncertain, operation == 'write');
          expect(backend.writes, hasLength(operation == 'write' ? 1 : 0));
          if (operation == 'write') {
            backend.write = (config, _) async =>
                classState(revision: 3, config: config);
            expect(await session.submit(classConfig()), isTrue);
            expect(backend.writes.last.revision, classRevision(2));
            expect(session.state.writeOutcomeUncertain, isFalse);
            expect(session.state.acknowledgedConfig, isNotNull);
          }
        },
      );
    }
  }

  test('stale CAS failure does not promote submitted desired policy', () async {
    final backend = _Backend();
    final session = backend.session();
    addTearDown(session.dispose);
    final accepted = classConfig();
    final desired = classConfig(id: 'new');
    expect(await session.refresh(), isTrue);
    expect(await session.submit(accepted), isTrue);
    backend.write = (_, _) async => throw StateError('stale revision');
    expect(await session.submit(desired), isTrue);
    expect(session.state.acknowledgedConfig, isNull);
    expect(session.state.writeOutcomeUncertain, isTrue);
    expect(accepted.classes.single.id, 'interactive');
    expect(await session.submit(desired), isFalse);
    backend.read = () async => classState(revision: 3, config: accepted);
    expect(await session.refresh(), isTrue);
    expect(session.state.acknowledgedConfig, isNull);
    expect(backend.writes, hasLength(2));
    backend.write = (config, _) async =>
        classState(revision: 4, config: config);
    expect(await session.submit(desired), isTrue);
    expect(backend.writes.last.revision, classRevision(3));
    expect(identical(session.state.acknowledgedConfig, desired), isTrue);
  });
}
