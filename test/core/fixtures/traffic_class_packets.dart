import 'package:quanclash/core/traffic_class.dart';

String classRevision(int n) => n.toRadixString(16).padLeft(32, '0');

Map<String, dynamic> classConfigWire({
  String id = 'interactive',
  int priority = 5,
}) => {
  'schemaVersion': 1,
  'classes': [
    {
      'id': id,
      'priority': priority,
      'match': <String, dynamic>{
        'networks': ['tcp'],
      },
    },
  ],
};

TrafficClassConfig classConfig({String id = 'interactive', int priority = 5}) =>
    TrafficClassConfig.fromJson(classConfigWire(id: id, priority: priority));

Map<String, dynamic> classStateWire({
  int revision = 1,
  bool inactive = false,
  TrafficClassConfig? config,
}) => {
  'schemaVersion': 1,
  'status': inactive ? 'inactive' : 'prepared',
  'revision': inactive ? '' : classRevision(revision),
  'enforcing': false,
  'classes': [
    if (!inactive && config != null)
      for (final c in config.classes) {'id': c.id, 'priority': c.priority},
  ],
};

TrafficClassSnapshot classState({
  int revision = 1,
  bool inactive = false,
  TrafficClassConfig? config,
}) => TrafficClassSnapshot.fromJson(
  classStateWire(revision: revision, inactive: inactive, config: config),
);
