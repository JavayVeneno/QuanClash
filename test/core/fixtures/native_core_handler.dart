import 'dart:async';
import 'dart:convert';

import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/transport.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';

// An explicit native test of the production Rust transport and shared facade,
// without the app's global CoreService, helper or system-network managers.
class IsolatedCoreHandler extends CoreHandlerInterface {
  final IPCCoreTransport transport;
  final bool logActions;
  final void Function(ActionResult result, int payloadBytes, int decodeMicros)?
  onResponse;
  final Map<String, Completer<dynamic>> _pending = {};
  late final StreamSubscription<List<int>> _subscription;
  int _sequence = 0;

  IsolatedCoreHandler(
    this.transport, {
    this.logActions = true,
    this.onResponse,
  }) {
    _subscription = transport.dataStream.listen((bytes) {
      final clock = onResponse == null ? null : (Stopwatch()..start());
      final result = ActionResult.fromJson(jsonDecode(utf8.decode(bytes)));
      clock?.stop();
      final pending = _pending.remove(result.id);
      if (pending == null) {
        return;
      }
      if (result.code == ResultType.success) {
        onResponse?.call(result, bytes.length, clock!.elapsedMicroseconds);
        pending.complete(result.data);
      } else {
        pending.completeError(StateError('Isolated core rejected action'));
      }
    });
  }

  @override
  Completer<void> get completer => transport.connectionCompleter;

  @override
  Future<T?> invoke<T>({
    required ActionMethod method,
    dynamic data,
    Duration? timeout,
  }) async {
    final id = 'node-quality-native-${_sequence++}';
    final pending = Completer<dynamic>();
    _pending[id] = pending;
    try {
      if (logActions) debugPrint('Native IPC fixture: sending ${method.name}');
      transport.send(jsonEncode(Action(id: id, method: method, data: data)));
      final result = await pending.future.timeout(
        timeout ?? const Duration(seconds: 5),
      );
      if (logActions) debugPrint('Native IPC fixture: received ${method.name}');
      return result as T?;
    } finally {
      _pending.remove(id);
    }
  }

  @override
  Future<bool> shutdown(bool isUser) async =>
      await invoke<bool>(method: ActionMethod.shutdown) ?? false;

  @override
  Future<String> preload() async => '';

  @override
  Future<bool> destroy() async {
    debugPrint('Native IPC fixture: closing transport');
    await _subscription.cancel();
    await transport.close();
    debugPrint('Native IPC fixture: transport closed');
    return true;
  }
}
