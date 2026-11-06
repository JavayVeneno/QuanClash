import 'dart:async';

import 'package:fl_clash/models/models.dart';

import 'connection_updates.dart';

enum ConnectionInspectionStatus { idle, ready, inactive, unavailable }

enum ConnectionInspectionSource { incremental, legacy }

enum ConnectionInspectionFailure {
  updateUnavailable,
  invalidUpdate,
  capacity,
  resyncFailed,
  requestTimeout,
  legacyUnavailable,
}

class ConnectionInspectionState {
  final ConnectionInspectionStatus status;
  final ConnectionInspectionSource? source;
  final ConnectionInspectionFailure? failure;
  final ConnectionInspectionSnapshot snapshot;
  final List<TrackerInfo> connections;
  final int uploadTotal;
  final int downloadTotal;

  const ConnectionInspectionState._({
    required this.status,
    this.source,
    this.failure,
    this.snapshot = const ConnectionInspectionSnapshot.empty(),
    this.connections = const [],
    this.uploadTotal = 0,
    this.downloadTotal = 0,
  });
}

class _RequestTimeout implements Exception {}

/// Opt-in, caller-driven refreshes only. No polling, listeners or global state.
/// The owner must call reset/disconnect/dispose BEFORE lifecycle changes; this
/// epoch prevents even a valid FULL reply from reviving an obsolete view.
class ConnectionInspectionSession {
  final Future<ConnectionUpdatePacket> Function(String cursor) _readUpdates;
  final Future<LegacyConnectionSnapshot> Function() _readLegacy;
  final Duration _requestTimeout;
  ConnectionInspectionState _state = const ConnectionInspectionState._(
    status: ConnectionInspectionStatus.idle,
  );
  Future<bool>? _inFlight;
  bool _readBusy = false;
  bool _active = true;
  bool _disposed = false;
  bool _legacyOnly = false;
  ConnectionInspectionFailure? _fallbackCause;
  int _epoch = 0;

  ConnectionInspectionSession({
    required Future<ConnectionUpdatePacket> Function(String cursor) readUpdates,
    required Future<LegacyConnectionSnapshot> Function() readLegacy,
    Duration requestTimeout = const Duration(seconds: 5),
  }) : _readUpdates = readUpdates,
       _readLegacy = readLegacy,
       _requestTimeout = requestTimeout {
    if (requestTimeout <= Duration.zero ||
        requestTimeout > const Duration(seconds: 15)) {
      throw ArgumentError.value(requestTimeout, 'requestTimeout');
    }
  }

  ConnectionInspectionState get state => _state;
  bool get usesLegacy => _legacyOnly;

  /// The injected read future is unresolved, not proof of native cancellation.
  bool get requestPending => _readBusy;

  void reset() => _invalidate(active: true);
  void disconnect() => _invalidate(active: false);

  void dispose() {
    _disposed = true;
    _invalidate(active: false);
  }

  void _invalidate({required bool active}) {
    _epoch++;
    _active = active && !_disposed;
    _legacyOnly = false;
    _fallbackCause = null;
    _state = ConnectionInspectionState._(
      status: _active
          ? ConnectionInspectionStatus.idle
          : ConnectionInspectionStatus.inactive,
    );
  }

  /// true: accepted a new ready/inactive/unavailable state. false: skipped or
  /// obsolete. Concurrent callers share one future; there is no waiting queue.
  /// Reset does not queue replacement work while an obsolete refresh is running;
  /// the owner can refresh again after it and the injected read future settle.
  Future<bool> refresh() {
    if (!_active || _disposed) return Future.value(false);
    final current = _inFlight;
    if (current != null) return current;
    // A deadline does NOT cancel an IPC operation. Until its future settles,
    // refuse new actions instead of accumulating hung requests on every poll.
    if (_readBusy) return Future.value(false);
    final epoch = _epoch;
    final work = Future<bool>.microtask(() => _refresh(epoch));
    final tracked = work.whenComplete(() => _inFlight = null);
    _inFlight = tracked;
    return tracked;
  }

  bool _current(int epoch) => !_disposed && _active && epoch == _epoch;

  Future<T> _request<T>(Future<T> Function() read) {
    _readBusy = true;
    final operation = Future<T>.sync(
      read,
    ).whenComplete(() => _readBusy = false);
    return operation.timeout(
      _requestTimeout,
      onTimeout: () => throw _RequestTimeout(),
    );
  }

  bool _unavailable(int epoch, ConnectionInspectionFailure reason) {
    if (!_current(epoch)) return false;
    _state = ConnectionInspectionState._(
      status: ConnectionInspectionStatus.unavailable,
      failure: reason,
    );
    return true;
  }

  void _pinLegacy(ConnectionInspectionFailure reason) {
    _legacyOnly = true;
    _fallbackCause = reason;
  }

  bool _accept(int epoch, ConnectionInspectionSnapshot snapshot) {
    if (!_current(epoch)) return false;
    _state = ConnectionInspectionState._(
      status: snapshot.status == ConnectionUpdateStatus.inactive
          ? ConnectionInspectionStatus.inactive
          : ConnectionInspectionStatus.ready,
      source: ConnectionInspectionSource.incremental,
      snapshot: snapshot,
      connections: List.unmodifiable(
        snapshot.records.values.map((v) => v.tracker),
      ),
      uploadTotal: snapshot.uploadTotal,
      downloadTotal: snapshot.downloadTotal,
    );
    return true;
  }

  Future<bool> _legacy(int epoch) async {
    if (!_current(epoch)) return false;
    try {
      final result = await _request(_readLegacy);
      if (!_current(epoch)) return false;
      _state = ConnectionInspectionState._(
        status: ConnectionInspectionStatus.ready,
        source: ConnectionInspectionSource.legacy,
        failure: _fallbackCause,
        connections: result.connections,
        uploadTotal: result.uploadTotal,
        downloadTotal: result.downloadTotal,
      );
      return true;
    } on _RequestTimeout {
      return _unavailable(epoch, ConnectionInspectionFailure.requestTimeout);
    } catch (_) {
      return _unavailable(epoch, ConnectionInspectionFailure.legacyUnavailable);
    }
  }

  Future<bool> _refresh(int epoch) async {
    if (!_current(epoch)) return false;
    if (_legacyOnly) return _legacy(epoch);
    final before = _state.snapshot;
    ConnectionUpdatePacket packet;
    try {
      packet = await _request(() => _readUpdates(before.cursor));
    } on _RequestTimeout {
      if (!_current(epoch)) return false;
      _pinLegacy(ConnectionInspectionFailure.requestTimeout);
      return _unavailable(epoch, ConnectionInspectionFailure.requestTimeout);
    } catch (error) {
      if (!_current(epoch)) return false;
      _pinLegacy(
        error is FormatException
            ? ConnectionInspectionFailure.invalidUpdate
            : ConnectionInspectionFailure.updateUnavailable,
      );
      return _legacy(epoch);
    }
    if (!_current(epoch)) return false;
    if (packet.status == ConnectionUpdateStatus.fallbackRequired) {
      _pinLegacy(ConnectionInspectionFailure.capacity);
      return _legacy(epoch);
    }
    try {
      return _accept(epoch, before.apply(packet));
    } on FormatException {
      // One fresh FULL request, never a retry loop. If this also fails, defer
      // legacy to the next manual/poll refresh, keeping <=2 actions per refresh.
      try {
        final full = await _request(() => _readUpdates(''));
        if (!_current(epoch)) return false;
        if (full.status == ConnectionUpdateStatus.fallbackRequired) {
          _pinLegacy(ConnectionInspectionFailure.capacity);
          return _unavailable(epoch, ConnectionInspectionFailure.capacity);
        }
        return _accept(
          epoch,
          const ConnectionInspectionSnapshot.empty().apply(full),
        );
      } catch (error) {
        if (!_current(epoch)) return false;
        final reason = error is _RequestTimeout
            ? ConnectionInspectionFailure.requestTimeout
            : ConnectionInspectionFailure.resyncFailed;
        _pinLegacy(reason);
        return _unavailable(epoch, reason);
      }
    }
  }
}
