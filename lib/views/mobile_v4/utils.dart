import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/views/proxies/grouping.dart';

String mobileV4ModeLabel(Mode mode) {
  return switch (mode) {
    Mode.rule => '规则模式',
    Mode.global => '全局模式',
    Mode.direct => '直连模式',
  };
}

String mobileV4ModeShortLabel(Mode mode) {
  return switch (mode) {
    Mode.rule => '规则',
    Mode.global => '全局',
    Mode.direct => '直连',
  };
}

Mode? mobileV4ModeFromLabel(String label) {
  return switch (label) {
    '规则模式' => Mode.rule,
    '全局模式' => Mode.global,
    '直连模式' => Mode.direct,
    _ => null,
  };
}

List<Mode> get mobileV4Modes => const [Mode.rule, Mode.global, Mode.direct];

/// Formats bytes-per-second into a tabular numeric value and unit string.
///
/// Displays `0.0 KB/s` when idle so the readout matches the v4 design spec.
(String value, String unit) mobileV4FormatSpeed(num bytesPerSecond) {
  final raw = bytesPerSecond.toDouble();
  if (raw <= 0) {
    return ('0.0', 'KB/s');
  }
  const kb = 1024.0;
  const mb = kb * 1024.0;
  const gb = mb * 1024.0;
  if (raw < mb) {
    return ((raw / kb).toStringAsFixed(1), 'KB/s');
  }
  if (raw < gb) {
    return ((raw / mb).toStringAsFixed(1), 'MB/s');
  }
  return ((raw / gb).toStringAsFixed(2), 'GB/s');
}

/// Formats byte counts into compact human-readable value and unit strings.
(String value, String unit) mobileV4FormatBytes(num bytes) {
  final raw = bytes.toDouble();
  if (raw <= 0) {
    return ('0', 'GB');
  }
  const kb = 1024.0;
  const mb = kb * 1024.0;
  const gb = mb * 1024.0;
  const tb = gb * 1024.0;
  if (raw >= tb) {
    final v = raw / tb;
    return (
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
      'TB',
    );
  }
  if (raw >= gb) {
    return ((raw / gb).toStringAsFixed(1), 'GB');
  }
  if (raw >= mb) {
    return ((raw / mb).toStringAsFixed(1), 'MB');
  }
  return ((raw / kb).toStringAsFixed(0), 'KB');
}

/// Geographic location target for the 3D dot-matrix globe.
class MobileV4GeoTarget {
  const MobileV4GeoTarget({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;

  static const defaultTokyo = MobileV4GeoTarget(
    id: 'jp',
    name: 'Tokyo',
    lat: 35.68,
    lon: 139.69,
  );
}

const Map<String, MobileV4GeoTarget> _regionGeoTargets = {
  'hk': MobileV4GeoTarget(id: 'hk', name: 'Hong Kong', lat: 22.32, lon: 114.17),
  'tw': MobileV4GeoTarget(id: 'tw', name: 'Taipei', lat: 25.03, lon: 121.57),
  'mo': MobileV4GeoTarget(id: 'mo', name: 'Macao', lat: 22.20, lon: 113.54),
  'sg': MobileV4GeoTarget(id: 'sg', name: 'Singapore', lat: 1.35, lon: 103.82),
  'jp': MobileV4GeoTarget.defaultTokyo,
  'kr': MobileV4GeoTarget(id: 'kr', name: 'Seoul', lat: 37.57, lon: 126.98),
  'us': MobileV4GeoTarget(
    id: 'us',
    name: 'San Francisco',
    lat: 37.77,
    lon: -122.42,
  ),
  'gb': MobileV4GeoTarget(id: 'gb', name: 'London', lat: 51.51, lon: -0.13),
  'de': MobileV4GeoTarget(id: 'de', name: 'Frankfurt', lat: 50.11, lon: 8.68),
  'fr': MobileV4GeoTarget(id: 'fr', name: 'Paris', lat: 48.86, lon: 2.35),
  'nl': MobileV4GeoTarget(id: 'nl', name: 'Amsterdam', lat: 52.37, lon: 4.90),
  'ru': MobileV4GeoTarget(id: 'ru', name: 'Moscow', lat: 55.76, lon: 37.62),
  'ca': MobileV4GeoTarget(id: 'ca', name: 'Toronto', lat: 43.65, lon: -79.38),
  'au': MobileV4GeoTarget(id: 'au', name: 'Sydney', lat: -33.87, lon: 151.21),
  'id': MobileV4GeoTarget(id: 'id', name: 'Jakarta', lat: -6.21, lon: 106.85),
  'in': MobileV4GeoTarget(id: 'in', name: 'Mumbai', lat: 19.08, lon: 72.88),
  'my': MobileV4GeoTarget(
    id: 'my',
    name: 'Kuala Lumpur',
    lat: 3.14,
    lon: 101.69,
  ),
  'th': MobileV4GeoTarget(id: 'th', name: 'Bangkok', lat: 13.76, lon: 100.50),
  'vn': MobileV4GeoTarget(
    id: 'vn',
    name: 'Ho Chi Minh',
    lat: 10.82,
    lon: 106.63,
  ),
  'ph': MobileV4GeoTarget(id: 'ph', name: 'Manila', lat: 14.60, lon: 120.98),
  'tr': MobileV4GeoTarget(id: 'tr', name: 'Istanbul', lat: 41.01, lon: 28.98),
  'ae': MobileV4GeoTarget(id: 'ae', name: 'Dubai', lat: 25.20, lon: 55.27),
  'br': MobileV4GeoTarget(id: 'br', name: 'Sao Paulo', lat: -23.55, lon: -46.63),
  'ar': MobileV4GeoTarget(
    id: 'ar',
    name: 'Buenos Aires',
    lat: -34.60,
    lon: -58.38,
  ),
  'ch': MobileV4GeoTarget(id: 'ch', name: 'Zurich', lat: 47.37, lon: 8.54),
  'se': MobileV4GeoTarget(id: 'se', name: 'Stockholm', lat: 59.33, lon: 18.07),
  'fi': MobileV4GeoTarget(id: 'fi', name: 'Helsinki', lat: 60.17, lon: 24.94),
  'pl': MobileV4GeoTarget(id: 'pl', name: 'Warsaw', lat: 52.23, lon: 21.01),
  'ua': MobileV4GeoTarget(id: 'ua', name: 'Kyiv', lat: 50.45, lon: 30.52),
  'cn': MobileV4GeoTarget(id: 'cn', name: 'Shanghai', lat: 31.23, lon: 121.47),
};

/// Resolves an active proxy node name into real-world city coordinates for the
/// 3D globe beacon and smooth yaw focus.
///
/// Reuses [regionOfProxyName] from `grouping.dart` and applies lightweight
/// city-level disambiguation (e.g. New York vs Los Angeles / San Francisco).
/// Falls back to Tokyo when the node name has no recognizable region.
MobileV4GeoTarget mobileV4GeoForNode(String nodeName) {
  final trimmed = nodeName.trim();
  if (trimmed.isEmpty) {
    return MobileV4GeoTarget.defaultTokyo;
  }
  final lower = trimmed.toLowerCase();
  if (trimmed.contains('纽约') || lower.contains('new york') || lower.contains('nyc')) {
    return const MobileV4GeoTarget(
      id: 'us-nyc',
      name: 'New York',
      lat: 40.71,
      lon: -74.01,
    );
  }
  if (trimmed.contains('洛杉矶') || lower.contains('los angeles') || lower.contains('lax')) {
    return const MobileV4GeoTarget(
      id: 'us-lax',
      name: 'Los Angeles',
      lat: 34.05,
      lon: -118.24,
    );
  }
  if (trimmed.contains('西雅图') || lower.contains('seattle')) {
    return const MobileV4GeoTarget(
      id: 'us-sea',
      name: 'Seattle',
      lat: 47.61,
      lon: -122.33,
    );
  }
  if (trimmed.contains('大阪') || lower.contains('osaka')) {
    return const MobileV4GeoTarget(
      id: 'jp-osa',
      name: 'Osaka',
      lat: 34.69,
      lon: 135.50,
    );
  }
  final region = regionOfProxyName(trimmed);
  if (region == null) {
    return MobileV4GeoTarget.defaultTokyo;
  }
  return _regionGeoTargets[region.id] ?? MobileV4GeoTarget.defaultTokyo;
}
