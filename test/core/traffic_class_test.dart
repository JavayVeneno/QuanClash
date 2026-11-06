import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/traffic_class_packets.dart';

class _Handler extends CoreHandlerInterface {
  Object? response;
  int calls = 0;
  ActionMethod? method;
  Object? data;
  Duration? timeout;

  _Handler(this.response);

  @override
  final Completer<void> completer = Completer<void>()..complete();

  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) async {
    calls++;
    this.method = method;
    this.data = data;
    this.timeout = timeout;
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
  tearDown(CoreController.resetInstance);

  test(
    'config preserves selectors, detaches all collections and encodes CAS',
    () {
      final path = Platform.isWindows
          ? r'C:\Program Files\browser.exe'
          : '/opt/browser';
      final wire = classConfigWire();
      final match =
          ((wire['classes'] as List).single as Map<String, dynamic>)['match']
              as Map<String, dynamic>;
      match.addAll({
        'uids': [0, 4294967295],
        'processPaths': [path],
        'processNames': ['browser.exe'],
        'packages': ['com.example.browser'],
      });
      final config = TrafficClassConfig.fromJson(jsonDecode(jsonEncode(wire)));
      final request = jsonDecode(config.encodeRequest(classRevision(1)));
      expect(request['expectedRevision'], classRevision(1));
      expect(request['config'], wire);
      match['uids'][0] = 2;
      expect(config.classes.single.match['uids']!.first, 0);
      expect(() => config.classes.clear(), throwsUnsupportedError);
      expect(
        () => config.classes.single.match['uids']!.clear(),
        throwsUnsupportedError,
      );
      expect(() => config.classes.single.match.clear(), throwsUnsupportedError);
      final exported = config.toJson();
      exported['classes'][0]['match']['uids'][0] = 3;
      expect(config.classes.single.match['uids']!.first, 0);
      expect(
        TrafficClassConfig.fromJson({
          'schemaVersion': 1,
          'classes': [],
        }).classes,
        isEmpty,
      );
    },
  );

  final malformed = <String, Map<String, dynamic>>{
    'missing classes': {'schemaVersion': 1},
    'null classes': {'schemaVersion': 1, 'classes': null},
    'float schema': {'schemaVersion': 1.0, 'classes': []},
    'future schema': {'schemaVersion': 2, 'classes': []},
    'case key': {'schemaVersion': 1, 'Classes': []},
    'unknown field': {...classConfigWire(), 'extra': true},
    'duplicate IDs': {
      'schemaVersion': 1,
      'classes': [
        ...classConfigWire()['classes'],
        ...classConfigWire()['classes'],
      ],
    },
    'class cap': {'schemaVersion': 1, 'classes': List.filled(257, {})},
  };
  for (final entry in malformed.entries) {
    test('config rejects ${entry.key}', () {
      expect(
        () => TrafficClassConfig.fromJson(entry.value),
        throwsFormatException,
      );
    });
  }

  final malformedClass = <String, Map<String, dynamic>>{
    'empty match': {'id': 'a', 'match': {}},
    'missing match': {'id': 'a'},
    'null priority': {
      'id': 'a',
      'priority': null,
      'match': {
        'networks': ['tcp'],
      },
    },
    'float priority': {
      'id': 'a',
      'priority': 1.5,
      'match': {
        'networks': ['tcp'],
      },
    },
    'overflow priority': {
      'id': 'a',
      'priority': 2147483648,
      'match': {
        'networks': ['tcp'],
      },
    },
    'empty ID': {
      'id': '',
      'match': {
        'networks': ['tcp'],
      },
    },
    'newline ID': {
      'id': 'a\n',
      'match': {
        'networks': ['tcp'],
      },
    },
    'null UID': {
      'id': 'a',
      'match': {
        'uids': [null],
      },
    },
    'float UID': {
      'id': 'a',
      'match': {
        'uids': [1.0],
      },
    },
    'negative UID': {
      'id': 'a',
      'match': {
        'uids': [-1],
      },
    },
    'overflow UID': {
      'id': 'a',
      'match': {
        'uids': [4294967296],
      },
    },
    'empty UID': {
      'id': 'a',
      'match': {
        'uids': [],
        'networks': ['tcp'],
      },
    },
    'duplicate UID': {
      'id': 'a',
      'match': {
        'uids': [1, 1],
      },
    },
    'unknown dimension': {
      'id': 'a',
      'match': {
        'hosts': ['example.com'],
      },
    },
    'unknown network': {
      'id': 'a',
      'match': {
        'networks': ['icmp'],
      },
    },
    'duplicate network': {
      'id': 'a',
      'match': {
        'networks': ['tcp', 'TCP'],
      },
    },
    'relative path': {
      'id': 'a',
      'match': {
        'processPaths': ['browser.exe'],
      },
    },
    'padded name': {
      'id': 'a',
      'match': {
        'processNames': [' browser.exe '],
      },
    },
    'control name': {
      'id': 'a',
      'match': {
        'processNames': ['a\u0000b'],
      },
    },
    'text cap': {
      'id': 'a',
      'match': {
        'packages': [List.filled(1025, 'x').join()],
      },
    },
    'value cap': {
      'id': 'a',
      'match': {'packages': List.filled(129, 'a')},
    },
  };
  for (final entry in malformedClass.entries) {
    test('selectors reject ${entry.key}', () {
      expect(
        () => TrafficClassConfig.fromJson({
          'schemaVersion': 1,
          'classes': [entry.value],
        }),
        throwsFormatException,
      );
    });
  }

  test('serialized document and request limits are bounded', () {
    final classes = List.generate(
      256,
      (i) => {
        'id': 'c$i',
        'match': {
          'packages': List.generate(
            128,
            (j) => '$j${List.filled(100, 'x').join()}',
          ),
        },
      },
    );
    expect(
      () =>
          TrafficClassConfig.fromJson({'schemaVersion': 1, 'classes': classes}),
      throwsFormatException,
    );
    for (final revision in [
      '',
      '${classRevision(1).toUpperCase()}A',
      '${classRevision(1)}\n',
    ]) {
      expect(
        () => classConfig().encodeRequest(revision),
        throwsFormatException,
      );
    }
  });

  test(
    'summary distinguishes inactive and ignores unretained additive fields',
    () {
      final raw = classStateWire(config: classConfig());
      raw['arbitrary'] = ['not retained'];
      final snapshot = TrafficClassSnapshot.fromJson(raw);
      raw['classes'][0]['id'] = 'mutated';
      expect(snapshot.classes.single.id, 'interactive');
      expect(() => snapshot.classes.clear(), throwsUnsupportedError);
      expect(classState(inactive: true).status, TrafficClassStatus.inactive);
    },
  );

  for (final key in [
    'schemaVersion',
    'status',
    'revision',
    'enforcing',
    'classes',
  ]) {
    test('summary requires $key', () {
      final raw = classStateWire()..remove(key);
      expect(() => TrafficClassSnapshot.fromJson(raw), throwsFormatException);
    });
  }

  test('summary rejects unsafe status, counters and malformed membership', () {
    for (final mutation in <Map<String, dynamic>>[
      {'enforcing': true},
      {'enforcing': 0},
      {'schemaVersion': 1.0},
      {'revision': '${classRevision(1)}\n'},
      {'revision': List.filled(32, 'A').join()},
      {'status': 'ready'},
      {'classes': null},
      {
        'classes': [
          {'id': 'a', 'priority': 1.0},
        ],
      },
      {
        'classes': [
          {'id': 'a', 'priority': 0},
          {'id': 'a', 'priority': 0},
        ],
      },
      {
        'status': 'inactive',
        'revision': '',
        'classes': [
          {'id': 'a', 'priority': 0},
        ],
      },
    ]) {
      expect(
        () => TrafficClassSnapshot.fromJson({...classStateWire(), ...mutation}),
        throwsFormatException,
      );
    }
  });

  test(
    'facade validates exact rotated acknowledgment and generated methods',
    () async {
      final config = classConfig();
      final handler = _Handler(classStateWire(revision: 2, config: config));
      final controller = CoreController.test(handler);
      expect(
        (await controller.setTrafficClasses(config, classRevision(1))).revision,
        classRevision(2),
      );
      expect(handler.method, ActionMethod.setTrafficClasses);
      expect(handler.timeout, const Duration(seconds: 5));
      expect(
        jsonDecode(handler.data as String),
        jsonDecode(config.encodeRequest(classRevision(1))),
      );
      for (final method in [
        ActionMethod.getTrafficClassState,
        ActionMethod.setTrafficClasses,
      ]) {
        final action = Action(id: 'fixture', method: method, data: null);
        final json = jsonDecode(jsonEncode(action));
        expect(json['method'], method.name);
        expect(Action.fromJson(json).method, method);
        expect(ActionResult.fromJson({...json, 'code': 0}).method, method);
      }
      handler.response = classStateWire(revision: 3);
      expect(
        (await controller.getTrafficClassState()).revision,
        classRevision(3),
      );
      expect(handler.data, isNull);
      handler.response = null;
      await expectLater(controller.getTrafficClassState(), throwsStateError);
      await expectLater(
        controller.setTrafficClasses(config, classRevision(3)),
        throwsStateError,
      );
    },
  );

  test(
    'facade refuses stale, reordered, mismatched and inactive acks',
    () async {
      final config = TrafficClassConfig.fromJson({
        'schemaVersion': 1,
        'classes': [
          ...classConfigWire()['classes'],
          ...classConfigWire(id: 'second')['classes'],
        ],
      });
      final good = classStateWire(revision: 2, config: config);
      for (final bad in [
        classStateWire(revision: 1, config: config),
        classStateWire(revision: 2, inactive: true),
        {...good, 'classes': (good['classes'] as List).reversed.toList()},
        classStateWire(revision: 2, config: classConfig()),
        classStateWire(revision: 2, config: classConfig(priority: 7)),
      ]) {
        await expectLater(
          CoreController.test(
            _Handler(bad),
          ).setTrafficClasses(config, classRevision(1)),
          throwsFormatException,
        );
      }
      final handler = _Handler(good);
      await expectLater(
        CoreController.test(handler).setTrafficClasses(config, 'bad'),
        throwsFormatException,
      );
      expect(handler.calls, 0);
    },
  );

  test('write logging never includes raw selector payload', () async {
    final logs = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
    addTearDown(() => debugPrint = previous);
    final config = TrafficClassConfig.fromJson({
      'schemaVersion': 1,
      'classes': [
        {
          'id': 'sensitive',
          'match': {
            'processNames': ['secret-process.exe'],
          },
        },
      ],
    });
    await _Handler(
      classStateWire(revision: 2, config: config),
    ).setTrafficClasses(config, classRevision(1));
    expect(logs.join(), isNot(contains('secret-process')));
  });

  test(
    'session factory binds typed read, CAS write and terminal disposal',
    () async {
      final handler = _Handler(classStateWire());
      final controller = CoreController.test(handler);
      final session = controller.createTrafficClassSession();
      addTearDown(session.dispose);
      final config = classConfig();
      expect(handler.calls, 0);
      expect(await session.refresh(), isTrue);
      expect(handler.method, ActionMethod.getTrafficClassState);
      handler.response = classStateWire(revision: 2, config: config);
      expect(await session.submit(config), isTrue);
      expect(handler.method, ActionMethod.setTrafficClasses);
      expect(
        jsonDecode(handler.data as String)['expectedRevision'],
        classRevision(1),
      );
      expect(identical(session.state.acknowledgedConfig, config), isTrue);
      session.dispose();
      expect(await session.refresh(), isFalse);
      expect(await session.submit(config), isFalse);
      expect(handler.calls, 2);
    },
  );

  test(
    'unavailable old endpoint never writes or fabricates prepared state',
    () async {
      final handler = _Handler(null);
      final session = CoreController.test(handler).createTrafficClassSession();
      addTearDown(session.dispose);
      expect(await session.refresh(), isTrue);
      expect(session.state.status, TrafficClassSessionStatus.unavailable);
      expect(session.state.failure, TrafficClassFailure.unavailable);
      expect(session.state.snapshot, isNull);
      expect(session.state.writeOutcomeUncertain, isFalse);
      expect(await session.submit(classConfig()), isFalse);
      expect(handler.calls, 1);
    },
  );

  test(
    'facade-rejected ack requires reread and explicit owner reconciliation',
    () async {
      final handler = _Handler(classStateWire());
      final session = CoreController.test(handler).createTrafficClassSession();
      addTearDown(session.dispose);
      final config = classConfig();
      expect(await session.refresh(), isTrue);
      handler.response = classStateWire(
        revision: 2,
        config: classConfig(id: 'other'),
      );
      expect(await session.submit(config), isTrue);
      // The facade refuses malformed acknowledgments before the session receives
      // them; the outcome is conservatively unknown, not a successful new config.
      expect(session.state.status, TrafficClassSessionStatus.unavailable);
      expect(session.state.writeOutcomeUncertain, isTrue);
      expect(session.state.acknowledgedConfig, isNull);
      expect(await session.submit(config), isFalse);
      handler.response = classStateWire(revision: 2, config: config);
      expect(await session.refresh(), isTrue);
      expect(session.state.acknowledgedConfig, isNull);
      expect(session.state.writeOutcomeUncertain, isTrue);
      handler.response = classStateWire(revision: 3, config: config);
      expect(await session.submit(config), isTrue);
      expect(session.state.writeOutcomeUncertain, isFalse);
      expect(identical(session.state.acknowledgedConfig, config), isTrue);
      expect(handler.calls, 4);
    },
  );
}
