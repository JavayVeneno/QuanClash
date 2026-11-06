import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:rust_api/rust_api.dart';

// ── Binary frame types (mirrors Rust ipc.rs) ────────────────────────────────

const _typeReady = 0x00;
const _typeConnected = 0x01;
const _typeDisconnected = 0x02;
const _typeData = 0x03;
const _typeError = 0x04;

class IPCCoreTransport {
  final String address;
  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>();
  StreamSubscription<Uint8List>? _subscription;
  Completer<void> _completer = Completer<void>();
  Completer<void> _readyCompleter = Completer<void>();
  Future<void>? _closeFuture;
  bool _closing = false;

  void Function()? onDisconnect;

  IPCCoreTransport({required this.address});

  Completer<void> get connectionCompleter => _completer;

  Stream<Uint8List> get dataStream => _dataController.stream;

  Future<void> init() async {
    try {
      final stream = restartIpcServer(name: address);
      _subscription = stream.listen(
        (data) {
          if (_closing || data.isEmpty) return;
          final type = data[0];
          final payload = data.length > 1 ? data.sublist(1) : Uint8List(0);
          switch (type) {
            case _typeReady:
              commonPrint.log('IPC Ready');
              if (_readyCompleter.isCompleted) {
                break;
              }
              _readyCompleter.complete();
              break;
            case _typeConnected:
              commonPrint.log('IPC Connected');
              if (_completer.isCompleted) {
                break;
              }
              _completer.complete();
              break;
            case _typeDisconnected:
              commonPrint.log('IPC Disconnected');
              _completer = Completer<void>();
              onDisconnect?.call();
              break;
            case _typeData:
              _dataController.add(payload);
              break;
            case _typeError:
              final msg = utf8.decode(payload);
              commonPrint.log('IPC error: $msg', logLevel: LogLevel.error);
              break;
            default:
              commonPrint.log(
                'IPC unknown frame type: $type',
                logLevel: LogLevel.warning,
              );
          }
        },
        onError: (error) {
          commonPrint.log('IPC error: $error', logLevel: LogLevel.error);
        },
        cancelOnError: false,
      );
      await _readyCompleter.future;
    } catch (e) {
      commonPrint.log(
        'Failed to start IPC server: $e',
        logLevel: LogLevel.error,
      );
      rethrow;
    }
  }

  void send(String message) {
    sendIpcMessage(data: utf8.encode(message));
  }

  void disconnected() {
    _completer = Completer<void>();
  }

  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    _closing = true;
    try {
      // FRB's async stream cancellation can wait for its native producer to
      // finish. Stop the producer first, otherwise neither side can finish.
      await stopIpcServer();
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      _readyCompleter = Completer<void>();
      _completer = Completer<void>();
      await _dataController.close();
    }
  }
}
