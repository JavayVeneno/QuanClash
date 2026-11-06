import 'dart:async';

import 'traffic_class.dart';

enum TrafficClassSessionStatus { idle, prepared, inactive, unavailable }

enum TrafficClassFailure { unavailable, timeout, invalidAcknowledgment }

class TrafficClassSessionState {
  final TrafficClassSessionStatus status;
  final TrafficClassSnapshot? snapshot;
  final TrafficClassConfig? acknowledgedConfig;
  final TrafficClassFailure? failure;
  final bool needsRefresh;
  final bool writeOutcomeUncertain;

  const TrafficClassSessionState._({
    required this.status,
    this.snapshot,
    this.acknowledgedConfig,
    this.failure,
    this.needsRefresh = true,
    this.writeOutcomeUncertain = false,
  });
}

/// Opt-in and owner-driven: no persistence, retry, polling or lifecycle wiring.
/// A reread obtains a CAS base, not proof a timed-out config's selectors match.
class TrafficClassSession {
  final Future<TrafficClassSnapshot> Function() _read;
  final Future<TrafficClassSnapshot> Function(TrafficClassConfig, String)
  _write;
  final Duration _timeout;
  TrafficClassSessionState _state = const TrafficClassSessionState._(
    status: TrafficClassSessionStatus.idle,
  );
  Future<bool>? _inFlight;
  bool _refreshing = false;
  bool _callbackPending = false;
  bool _writePending = false;
  bool _uncertain = false;
  bool _active = true;
  bool _disposed = false;
  int _epoch = 0;

  TrafficClassSession({
    required Future<TrafficClassSnapshot> Function() read,
    required Future<TrafficClassSnapshot> Function(TrafficClassConfig, String)
    write,
    Duration requestTimeout = const Duration(seconds: 5),
  }) : _read = read,
       _write = write,
       _timeout = requestTimeout {
    if (requestTimeout <= Duration.zero ||
        requestTimeout > const Duration(seconds: 15)) {
      throw ArgumentError.value(requestTimeout, 'requestTimeout');
    }
  }

  TrafficClassSessionState get state => _state;

  /// Tracks the injected callback, not physical completion of native IPC work.
  bool get requestPending => _callbackPending;

  void reset() => _invalidate(true);
  void disconnect() => _invalidate(false);

  void dispose() {
    _disposed = true;
    _invalidate(false);
  }

  void _invalidate(bool active) {
    _epoch++;
    _active = active && !_disposed;
    // Epochs suppress publication, not server-side writes. Keep this warning
    // until an explicitly acknowledged new write resolves the uncertainty.
    _uncertain = _uncertain || _writePending;
    _state = TrafficClassSessionState._(
      status: _active
          ? TrafficClassSessionStatus.idle
          : TrafficClassSessionStatus.inactive,
      writeOutcomeUncertain: _uncertain,
    );
  }

  bool _current(int epoch) => _active && !_disposed && epoch == _epoch;
  bool get _canStart =>
      _active && !_disposed && _inFlight == null && !_callbackPending;

  Future<T> _request<T>(Future<T> Function() request, {bool writing = false}) {
    _callbackPending = true;
    _writePending = writing;
    final operation = Future<T>.sync(request).whenComplete(() {
      _callbackPending = false;
    });
    // This deadline cannot cancel native work; no new callback is admitted
    // until the injected future settles, even across owner reset.
    return operation.timeout(_timeout);
  }

  Future<bool> _track(
    Future<bool> Function(int) action, {
    bool reading = false,
  }) {
    final epoch = _epoch;
    _refreshing = reading;
    final work = Future<bool>.microtask(() => action(epoch));
    final tracked = work.whenComplete(() {
      _inFlight = null;
      _refreshing = false;
      _writePending = false;
    });
    _inFlight = tracked;
    return tracked;
  }

  /// true means state published (including unavailable), false skipped/obsolete.
  /// Only concurrent READs coalesce. No writes or follow-up reads are queued.
  /// Reset during a read shares obsolete work; refresh again once it settles.
  Future<bool> refresh() {
    if (!_active || _disposed) return Future.value(false);
    if (_refreshing && _inFlight != null) return _inFlight!;
    if (!_canStart) return Future.value(false);
    return _track(_refresh, reading: true);
  }

  /// Explicit submission only, using the current reread revision. Desired config
  /// stays with the owner; this session retains it only after a direct valid ack.
  Future<bool> submit(TrafficClassConfig config) {
    final before = _state.snapshot;
    if (!_canStart ||
        _state.needsRefresh ||
        before == null ||
        before.status != TrafficClassStatus.prepared) {
      return Future.value(false);
    }
    config.encodeRequest(before.revision);
    return _track((epoch) => _submit(epoch, config, before.revision));
  }

  bool _fail(int epoch, TrafficClassFailure failure, {bool writing = false}) {
    if (!_current(epoch)) return false;
    _uncertain = _uncertain || writing;
    _state = TrafficClassSessionState._(
      status: TrafficClassSessionStatus.unavailable,
      failure: failure,
      writeOutcomeUncertain: _uncertain,
    );
    return true;
  }

  Future<bool> _refresh(int epoch) async {
    if (!_current(epoch)) return false;
    final before = _state;
    try {
      final snapshot = await _request(_read);
      if (!_current(epoch)) return false;
      _state = TrafficClassSessionState._(
        status: snapshot.status == TrafficClassStatus.prepared
            ? TrafficClassSessionStatus.prepared
            : TrafficClassSessionStatus.inactive,
        snapshot: snapshot,
        acknowledgedConfig:
            !_uncertain && before.snapshot?.revision == snapshot.revision
            ? before.acknowledgedConfig
            : null,
        needsRefresh: false,
        writeOutcomeUncertain: _uncertain,
      );
      return true;
    } on TimeoutException {
      return _fail(epoch, TrafficClassFailure.timeout);
    } catch (_) {
      return _fail(epoch, TrafficClassFailure.unavailable);
    }
  }

  Future<bool> _submit(
    int epoch,
    TrafficClassConfig config,
    String revision,
  ) async {
    if (!_current(epoch)) return false;
    _state = TrafficClassSessionState._(
      status: TrafficClassSessionStatus.idle,
      writeOutcomeUncertain: _uncertain,
    );
    try {
      final snapshot = await _request(
        () => _write(config, revision),
        writing: true,
      );
      if (!_current(epoch)) return false;
      try {
        snapshot.validateAcknowledgment(config, revision);
      } catch (_) {
        return _fail(
          epoch,
          TrafficClassFailure.invalidAcknowledgment,
          writing: true,
        );
      }
      _uncertain = false;
      _state = TrafficClassSessionState._(
        status: TrafficClassSessionStatus.prepared,
        snapshot: snapshot,
        acknowledgedConfig: config,
        needsRefresh: false,
      );
      return true;
    } on TimeoutException {
      return _fail(epoch, TrafficClassFailure.timeout, writing: true);
    } catch (_) {
      return _fail(epoch, TrafficClassFailure.unavailable, writing: true);
    }
  }
}
