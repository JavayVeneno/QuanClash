import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

const _maxDocumentBytes = 1024 * 1024;
final _idPattern = RegExp(r'^[a-zA-Z0-9._-]{1,64}$');
final _revisionPattern = RegExp(r'^[0-9a-f]{32}$');

bool _matches(RegExp pattern, String value) =>
    pattern.firstMatch(value)?.end == value.length;

bool isTrafficClassRevision(String value) => _matches(_revisionPattern, value);

Never _invalid() => throw const FormatException('Invalid traffic class data');

Map<String, dynamic> _object(Object? value, Set<String> keys) {
  if (value is! Map<String, dynamic> ||
      value.keys.any((key) => !keys.contains(key)) ||
      value.values.any((value) => value == null)) {
    _invalid();
  }
  return value;
}

String _id(Object? value) {
  if (value is! String || !_matches(_idPattern, value)) _invalid();
  return value;
}

int _integer(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) _invalid();
  return value;
}

String _text(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      utf8.encode(value).length > 1024 ||
      value.runes.any((v) => v < 32 || v == 127)) {
    _invalid();
  }
  return value;
}

List<String> _strings(Object? value) {
  if (value is! List || value.isEmpty || value.length > 128) _invalid();
  return List.unmodifiable(value.map(_text));
}

void _unique(Iterable<Object> values) {
  final list = values.toList();
  if (list.toSet().length != list.length) _invalid();
}

String _encodeBounded(Map<String, dynamic> value) {
  final encoded = jsonEncode(value);
  if (utf8.encode(encoded).length > _maxDocumentBytes) _invalid();
  return encoded;
}

/// Immutable selectors. Path validation is textual for this host, not file or
/// process identity. The core remains authoritative for normalized duplicates.
class TrafficClassDefinition {
  final String id;
  final int priority;
  final Map<String, List<Object>> _match;

  TrafficClassDefinition._(this.id, this.priority, this._match);

  factory TrafficClassDefinition.fromJson(Map<String, dynamic> json) {
    final fields = _object(json, {'id', 'priority', 'match'});
    final id = _id(fields['id']);
    final priority = fields.containsKey('priority')
        ? _integer(fields['priority'], -2147483648, 2147483647)
        : 0;
    final match = _object(fields['match'], {
      'processNames',
      'processPaths',
      'uids',
      'packages',
      'networks',
    });
    if (match.isEmpty) _invalid();
    final detached = <String, List<Object>>{};
    for (final entry in match.entries) {
      if (entry.key == 'uids') {
        final raw = entry.value;
        if (raw is! List || raw.isEmpty || raw.length > 128) _invalid();
        final values = raw.map((v) => _integer(v, 0, 4294967295)).toList();
        _unique(values);
        detached[entry.key] = List.unmodifiable(values);
        continue;
      }
      final values = _strings(entry.value);
      final normalized = <String>[];
      for (final value in values) {
        var key = value;
        if (entry.key == 'networks') {
          key = value.toLowerCase();
          if (key != 'tcp' && key != 'udp') _invalid();
        } else if (entry.key == 'processPaths') {
          if (!p.isAbsolute(value)) _invalid();
          key = p.normalize(value);
          if (Platform.isWindows) key = key.toLowerCase();
        } else if (entry.key == 'processNames' && Platform.isWindows) {
          key = value.toLowerCase();
        }
        normalized.add(key);
      }
      _unique(normalized);
      detached[entry.key] = values;
    }
    return TrafficClassDefinition._(id, priority, Map.unmodifiable(detached));
  }

  Map<String, List<Object>> get match => _match;

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority,
    'match': {for (final e in _match.entries) e.key: e.value.toList()},
  };
}

class TrafficClassConfig {
  final List<TrafficClassDefinition> classes;

  TrafficClassConfig._(this.classes);

  factory TrafficClassConfig.fromJson(Map<String, dynamic> json) {
    final fields = _object(json, {'schemaVersion', 'classes'});
    if (fields['schemaVersion'] is! int || fields['schemaVersion'] != 1) {
      _invalid();
    }
    final raw = fields['classes'];
    if (raw is! List || raw.length > 256) _invalid();
    final classes = raw.map((v) {
      if (v is! Map<String, dynamic>) _invalid();
      return TrafficClassDefinition.fromJson(v);
    }).toList();
    _unique(classes.map((c) => c.id));
    final result = TrafficClassConfig._(List.unmodifiable(classes));
    _encodeBounded(result.toJson());
    return result;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'classes': classes.map((v) => v.toJson()).toList(),
  };

  String encodeRequest(String expectedRevision) {
    if (!isTrafficClassRevision(expectedRevision)) _invalid();
    return _encodeBounded({
      'schemaVersion': 1,
      'expectedRevision': expectedRevision,
      'config': toJson(),
    });
  }
}

enum TrafficClassStatus { prepared, inactive }

class TrafficClassSummary {
  final String id;
  final int priority;

  const TrafficClassSummary._(this.id, this.priority);
}

/// A redacted preparation summary, never proof of selectors or active QoS.
class TrafficClassSnapshot {
  final TrafficClassStatus status;
  final String revision;
  final List<TrafficClassSummary> classes;

  TrafficClassSnapshot._(this.status, this.revision, this.classes);

  factory TrafficClassSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['enforcing'] != false ||
        json['enforcing'] is! bool) {
      _invalid();
    }
    final status = switch (json['status']) {
      'prepared' => TrafficClassStatus.prepared,
      'inactive' => TrafficClassStatus.inactive,
      _ => _invalid(),
    };
    final revision = json['revision'];
    if (revision is! String ||
        (status == TrafficClassStatus.prepared
            ? !isTrafficClassRevision(revision)
            : revision.isNotEmpty)) {
      _invalid();
    }
    final raw = json['classes'];
    if (raw is! List ||
        raw.length > 256 ||
        (status == TrafficClassStatus.inactive && raw.isNotEmpty)) {
      _invalid();
    }
    final classes = raw.map((value) {
      if (value is! Map<String, dynamic>) _invalid();
      return TrafficClassSummary._(
        _id(value['id']),
        _integer(value['priority'], -2147483648, 2147483647),
      );
    }).toList();
    _unique(classes.map((v) => v.id));
    return TrafficClassSnapshot._(status, revision, List.unmodifiable(classes));
  }

  void validateAcknowledgment(TrafficClassConfig config, String previous) {
    if (status != TrafficClassStatus.prepared ||
        revision == previous ||
        classes.length != config.classes.length) {
      _invalid();
    }
    for (var i = 0; i < classes.length; i++) {
      if (classes[i].id != config.classes[i].id ||
          classes[i].priority != config.classes[i].priority) {
        _invalid();
      }
    }
  }
}
