import 'package:quanclash/models/models.dart';

enum ConnectionUpdateStatus { ready, inactive, fallbackRequired }

/// Legacy action decoder for the opt-in inspection session. Unlike the old UI
/// decoder, absent/invalid fields never masquerade as an empty success.
class LegacyConnectionSnapshot {
  final List<TrackerInfo> connections;
  final int uploadTotal;
  final int downloadTotal;

  const LegacyConnectionSnapshot._(
    this.connections,
    this.uploadTotal,
    this.downloadTotal,
  );

  factory LegacyConnectionSnapshot.fromJson(Map<String, dynamic> json) {
    final upload = _integer(json['uploadTotal']);
    final download = _integer(json['downloadTotal']);
    if (!json.containsKey('connections')) _invalid();
    final raw = json['connections'];
    // Go encodes its nil connection slice as null, not an absent field.
    if (raw != null && (raw is! List || raw.length > _maxLegacyRecords)) {
      _invalid();
    }
    final records = <TrackerInfo>[];
    final ids = <String>{};
    var charge = 0;
    for (final value in (raw as List?) ?? const []) {
      final record = _object(value);
      final id = _id(record['id']);
      if (!ids.add(id)) _invalid();
      final metadata = Map<String, dynamic>.of(_object(record['metadata']));
      _string(metadata['network']);
      for (final key in const [
        'network',
        'sourceIP',
        'sourcePort',
        'destinationIP',
        'destinationPort',
        'host',
        'process',
        'processPath',
        'remoteDestination',
        'destinationIPASN',
        'sourceIPASN',
        'specialRules',
        'specialProxy',
      ]) {
        if (metadata.containsKey(key)) _string(metadata[key]);
      }
      if (metadata.containsKey('uid')) {
        _integer(metadata['uid'], max: 0xffffffff);
      }
      for (final key in const ['sourceGeoIP', 'destinationGeoIP']) {
        if (metadata.containsKey(key)) metadata[key] = _strings(metadata[key]);
      }
      final dnsMode = metadata['dnsMode'];
      if (dnsMode != null &&
          !const {
            'normal',
            'fake-ip',
            'redir-host',
            'hosts',
            'unknown',
          }.contains(dnsMode)) {
        _invalid();
      }
      if (dnsMode == 'unknown') metadata['dnsMode'] = null;
      if (!record.containsKey('chains')) _invalid();
      final chains = _strings(record['chains']);
      final tracker = TrackerInfo(
        id: id,
        upload: _integer(record['upload']),
        download: _integer(record['download']),
        start: _time(record['start']),
        metadata: Metadata.fromJson(metadata),
        chains: chains ?? const [],
        rule: _string(record['rule']),
        rulePayload: _string(record['rulePayload']),
      );
      charge += 1024;
      // Charge only retained UI fields; unrecognized legacy fields are dropped.
      for (final item in [
        ...tracker.metadata.toJson().values,
        chains,
        tracker.rule,
        tracker.rulePayload,
      ]) {
        if (item is String) charge += item.length * 2;
        if (item is List<String>) {
          charge += item.length * 16;
          for (final text in item) {
            charge += text.length * 2;
          }
        }
      }
      if (charge > _maxRetainedCharge) _invalid();
      records.add(tracker);
    }
    return LegacyConnectionSnapshot._(
      List.unmodifiable(records),
      upload,
      download,
    );
  }
}

const _maxRecords = 4096;
const _maxLegacyRecords = 16384;
const _maxOperations = 8192;
const _maxRetainedCharge = 16 * 1024 * 1024;
const _maxCounter = 0x7fffffffffffffff;
final _cursorPattern = RegExp(r'^[0-9a-f]{32}$');
final _idPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _timePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,9})?(Z|[+-]\d{2}:\d{2})$',
);

Never _invalid() => throw const FormatException('Invalid connection update');

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) _invalid();
  return value;
}

String _string(Object? value) {
  if (value is! String) _invalid();
  return value;
}

int _integer(Object? value, {int max = _maxCounter}) {
  if (value is! int || value < 0 || value > max) _invalid();
  return value;
}

String _id(Object? value) {
  final id = _string(value);
  if (id.length != 36 || !_idPattern.hasMatch(id)) _invalid();
  return id;
}

DateTime _time(Object? value, {bool utcOnly = false}) {
  final text = _string(value);
  final match = _timePattern.firstMatch(text);
  if (match == null || (utcOnly && match[7] != 'Z')) _invalid();
  final parts = [for (var i = 1; i <= 6; i++) int.parse(match[i]!)];
  final normalized = DateTime.utc(
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
    parts[5],
  );
  // DateTime.parse normalizes invalid dates (e.g. February 30). Refuse them.
  if (normalized.year != parts[0] ||
      normalized.month != parts[1] ||
      normalized.day != parts[2] ||
      normalized.hour != parts[3] ||
      normalized.minute != parts[4] ||
      normalized.second != parts[5]) {
    _invalid();
  }
  final zone = match[7]!;
  if (zone != 'Z' &&
      (int.parse(zone.substring(1, 3)) > 23 ||
          int.parse(zone.substring(4, 6)) > 59)) {
    _invalid();
  }
  return DateTime.parse(text);
}

List<String>? _strings(Object? value) {
  if (value == null) return null;
  if (value is! List || value.length > _maxOperations) _invalid();
  return List<String>.unmodifiable(value.map(_string));
}

/// Keeps schema-1 inspection fields that the legacy UI model does not expose.
/// Nullable chains/GeoIP preserve the core's nil-versus-empty distinction.
class ConnectionInspectionRecord {
  final TrackerInfo tracker;
  final Map<String, dynamic> metadata;
  final List<String>? chains;
  final List<String>? providerChains;
  final String startTimestamp;
  final int chargedBytes;

  const ConnectionInspectionRecord._({
    required this.tracker,
    required this.metadata,
    required this.chains,
    required this.providerChains,
    required this.startTimestamp,
    required this.chargedBytes,
  });

  String get id => tracker.id;

  factory ConnectionInspectionRecord.fromJson(Map<String, dynamic> json) {
    final rawMetadata = _object(json['metadata']);
    final metadata = <String, dynamic>{};
    for (final key in const [
      'network',
      'type',
      'sourceIP',
      'destinationIP',
      'sourcePort',
      'destinationPort',
      'inboundIP',
      'inboundPort',
      'sourceIPASN',
      'destinationIPASN',
      'inboundName',
      'inboundUser',
      'rematchName',
      'host',
      'dnsMode',
      'process',
      'processPath',
      'specialProxy',
      'specialRules',
      'remoteDestination',
      'sniffHost',
    ]) {
      metadata[key] = _string(rawMetadata[key]);
    }
    metadata['uid'] = _integer(rawMetadata['uid'], max: 0xffffffff);
    metadata['dscp'] = _integer(rawMetadata['dscp'], max: 255);
    for (final key in const ['sourceGeoIP', 'destinationGeoIP']) {
      if (!rawMetadata.containsKey(key)) _invalid();
      metadata[key] = _strings(rawMetadata[key]);
    }
    if (!const {'tcp', 'udp', 'all', 'invalid'}.contains(metadata['network']) ||
        !const {
          'normal',
          'fake-ip',
          'redir-host',
          'hosts',
          'unknown',
        }.contains(metadata['dnsMode'])) {
      _invalid();
    }
    for (final key in const ['sourcePort', 'destinationPort', 'inboundPort']) {
      final text = metadata[key] as String;
      final port = int.tryParse(text);
      if (port == null || port < 0 || port > 65535 || '$port' != text) {
        _invalid();
      }
    }
    if (!json.containsKey('chains') || !json.containsKey('providerChains')) {
      _invalid();
    }
    final chains = _strings(json['chains']);
    final providers = _strings(json['providerChains']);
    final start = _string(json['start']);
    final startedAt = _time(start);
    // This is a conservative retained-data charge, not a measurement of Dart
    // heap/RSS. Input JSON/transport allocation exists before these checks.
    var charge = 1024;
    for (final value in [
      ...metadata.values,
      chains,
      providers,
      start,
      _string(json['rule']),
      _string(json['rulePayload']),
    ]) {
      if (value is String) charge += value.length * 2;
      if (value is List<String>) {
        charge += value.length * 16;
        for (final text in value) {
          charge += text.length * 2;
        }
      }
      if (charge > _maxRetainedCharge) _invalid();
    }
    final uiMetadata = Map<String, dynamic>.of(metadata);
    // Unknown DNS mode is kept verbatim in inspection data, never guessed safe.
    if (uiMetadata['dnsMode'] == 'unknown') uiMetadata['dnsMode'] = null;
    final tracker = TrackerInfo(
      id: _id(json['id']),
      upload: _integer(json['upload']),
      download: _integer(json['download']),
      start: startedAt,
      metadata: Metadata.fromJson(uiMetadata),
      chains: chains ?? const [],
      rule: _string(json['rule']),
      rulePayload: _string(json['rulePayload']),
    );
    return ConnectionInspectionRecord._(
      tracker: tracker,
      metadata: Map<String, dynamic>.unmodifiable(metadata),
      chains: chains,
      providerChains: providers,
      startTimestamp: start,
      chargedBytes: charge,
    );
  }

  ConnectionInspectionRecord _withCounters(ConnectionCounterUpdate update) =>
      ConnectionInspectionRecord._(
        tracker: tracker.copyWith(
          upload: update.upload,
          download: update.download,
        ),
        metadata: metadata,
        chains: chains,
        providerChains: providerChains,
        startTimestamp: startTimestamp,
        chargedBytes: chargedBytes,
      );
}

class ConnectionCounterUpdate {
  final String id;
  final int upload;
  final int download;

  const ConnectionCounterUpdate._(this.id, this.upload, this.download);

  factory ConnectionCounterUpdate.fromJson(Map<String, dynamic> json) =>
      ConnectionCounterUpdate._(
        _id(json['id']),
        _integer(json['upload']),
        _integer(json['download']),
      );
}

/// Removal counts are last observed, NOT verified final byte totals or a quota.
class ConnectionRemoval extends ConnectionCounterUpdate {
  const ConnectionRemoval._(super.id, super.upload, super.download) : super._();

  bool get finalCountersVerified => false;

  factory ConnectionRemoval.fromJson(Map<String, dynamic> json) {
    if (json['finalCountersVerified'] != false) _invalid();
    return ConnectionRemoval._(
      _id(json['id']),
      _integer(json['upload']),
      _integer(json['download']),
    );
  }
}

class ConnectionUpdatePacket {
  final ConnectionUpdateStatus status;
  final bool full;
  final String baseCursor;
  final String cursor;
  final DateTime sampledAt;
  final int uploadTotal;
  final int downloadTotal;
  final List<ConnectionInspectionRecord> upserted;
  final List<ConnectionCounterUpdate> updated;
  final List<ConnectionRemoval> removed;

  const ConnectionUpdatePacket._({
    required this.status,
    required this.full,
    required this.baseCursor,
    required this.cursor,
    required this.sampledAt,
    required this.uploadTotal,
    required this.downloadTotal,
    required this.upserted,
    required this.updated,
    required this.removed,
  });

  factory ConnectionUpdatePacket.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) _invalid();
    final status = switch (json['status']) {
      'ready' => ConnectionUpdateStatus.ready,
      'inactive' => ConnectionUpdateStatus.inactive,
      'fallback-required' => ConnectionUpdateStatus.fallbackRequired,
      _ => _invalid(),
    };
    final full = json['full'];
    if (full is! bool) _invalid();
    final cursor = _string(json['cursor']);
    final base = _string(json['baseCursor']);
    final upserted = json['upserted'];
    final updated = json['updated'];
    final removed = json['removed'];
    if (upserted is! List ||
        updated is! List ||
        removed is! List ||
        upserted.length > _maxRecords ||
        updated.length > _maxRecords ||
        removed.length > _maxRecords ||
        upserted.length + updated.length + removed.length > _maxOperations) {
      _invalid();
    }
    final upload = _integer(json['uploadTotal']);
    final download = _integer(json['downloadTotal']);
    if (status == ConnectionUpdateStatus.ready) {
      if (cursor.length != 32 ||
          !_cursorPattern.hasMatch(cursor) ||
          (full
              ? base.isNotEmpty
              : base.length != 32 || !_cursorPattern.hasMatch(base)) ||
          (!full && cursor == base) ||
          (full && (updated.isNotEmpty || removed.isNotEmpty))) {
        _invalid();
      }
    } else if (!full ||
        cursor.isNotEmpty ||
        base.isNotEmpty ||
        upserted.isNotEmpty ||
        updated.isNotEmpty ||
        removed.isNotEmpty ||
        (status == ConnectionUpdateStatus.inactive &&
            (upload != 0 || download != 0))) {
      _invalid();
    }
    final records = <ConnectionInspectionRecord>[];
    var charged = 0;
    for (final value in upserted) {
      final record = ConnectionInspectionRecord.fromJson(_object(value));
      charged += record.chargedBytes;
      if (charged > _maxRetainedCharge) _invalid();
      records.add(record);
    }
    final counts = updated
        .map((v) => ConnectionCounterUpdate.fromJson(_object(v)))
        .toList();
    final removals = removed
        .map((v) => ConnectionRemoval.fromJson(_object(v)))
        .toList();
    final ids = <String>{};
    for (final id in [
      ...records.map((v) => v.id),
      ...counts.map((v) => v.id),
      ...removals.map((v) => v.id),
    ]) {
      if (!ids.add(id)) _invalid();
    }
    return ConnectionUpdatePacket._(
      status: status,
      full: full,
      baseCursor: base,
      cursor: cursor,
      sampledAt: _time(json['sampledAt'], utcOnly: true),
      uploadTotal: upload,
      downloadTotal: download,
      upserted: List.unmodifiable(records),
      updated: List.unmodifiable(counts),
      removed: List.unmodifiable(removals),
    );
  }
}

/// Pure, immutable merge. A rejected packet cannot partially change a cursor,
/// totals or records. Request serialization and lifecycle epochs belong to the
/// future consumer; a full packet alone cannot prove it is a current response.
class ConnectionInspectionSnapshot {
  final ConnectionUpdateStatus? status;
  final String cursor;
  final DateTime? sampledAt;
  final int uploadTotal;
  final int downloadTotal;
  final Map<String, ConnectionInspectionRecord> records;

  const ConnectionInspectionSnapshot.empty()
    : status = null,
      cursor = '',
      sampledAt = null,
      uploadTotal = 0,
      downloadTotal = 0,
      records = const {};

  const ConnectionInspectionSnapshot._({
    required this.status,
    required this.cursor,
    required this.sampledAt,
    required this.uploadTotal,
    required this.downloadTotal,
    required this.records,
  });

  bool get needsFull => cursor.isEmpty;
  bool get requiresLegacyFallback =>
      status == ConnectionUpdateStatus.fallbackRequired;

  ConnectionInspectionSnapshot apply(ConnectionUpdatePacket packet) {
    if (packet.status != ConnectionUpdateStatus.ready) {
      return ConnectionInspectionSnapshot._(
        status: packet.status,
        cursor: '',
        sampledAt: packet.sampledAt,
        uploadTotal: 0,
        downloadTotal: 0,
        records: const {},
      );
    }
    if (!packet.full && (needsFull || packet.baseCursor != cursor)) _invalid();
    // Copy before applying. Never mutate records shared with an older snapshot.
    final next = packet.full
        ? <String, ConnectionInspectionRecord>{}
        : Map<String, ConnectionInspectionRecord>.of(records);
    for (final record in packet.upserted) {
      next[record.id] = record;
    }
    for (final update in packet.updated) {
      final old = next[update.id];
      if (old == null) _invalid();
      next[update.id] = old._withCounters(update);
    }
    for (final removal in packet.removed) {
      if (next.remove(removal.id) == null) _invalid();
    }
    if (next.length > _maxRecords ||
        next.values.fold<int>(0, (sum, record) => sum + record.chargedBytes) >
            _maxRetainedCharge) {
      _invalid();
    }
    return ConnectionInspectionSnapshot._(
      status: packet.status,
      cursor: packet.cursor,
      sampledAt: packet.sampledAt,
      uploadTotal: packet.uploadTotal,
      downloadTotal: packet.downloadTotal,
      records: Map.unmodifiable(next),
    );
  }
}
