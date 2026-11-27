import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'world_data.dart';

/// A city pin on the dot-matrix globe.
class MobileV4GeoCity {
  const MobileV4GeoCity(this.name, this.lat, this.lon, {this.active = false});

  final String name;
  final double lat;
  final double lon;
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is MobileV4GeoCity &&
      other.name == name &&
      other.lat == lat &&
      other.lon == lon &&
      other.active == active;

  @override
  int get hashCode => Object.hash(name, lat, lon, active);
}

/// Pseudo-3D dot-matrix globe supporting both Dark and Light v4 palettes.
///
/// Renders Natural Earth 110m country outlines (285 rings / 6008 points),
/// land-only Fibonacci dots (2303 points) batched into six depth buckets,
/// a 30-degree graticule, great-circle network arcs with animated packets,
/// city pins with a dynamic breathing active beacon, and an atmospheric rim.
class MobileV4GlobePainter extends CustomPainter {
  const MobileV4GlobePainter({
    required this.rotation,
    required this.pulse,
    required this.connected,
    this.isDark = true,
    this.activeCity = defaultActiveCity,
    this.baseYaw,
  });

  static const defaultActiveCity = MobileV4GeoCity(
    'Tokyo',
    35.68,
    139.69,
    active: true,
  );

  /// Yaw in radians. Animate 0 -> 2*pi over ~80s for a slow spin.
  final double rotation;

  /// 0..1 breathing phase for the active node and travelling packets.
  final double pulse;

  /// Dims the active beacon when disconnected.
  final bool connected;

  /// Selects the dark space-glass or light porcelain-glass globe rendering.
  final bool isDark;

  /// Current active proxy node city rendered with the golden breathing beacon.
  final MobileV4GeoCity activeCity;

  /// Optional yaw offset replacing the default Tokyo front-center yaw so the
  /// globe can smoothly rotate toward [activeCity].
  final double? baseYaw;

  static const double _tilt = 0.31;

  static const List<MobileV4GeoCity> _hubCities = [
    MobileV4GeoCity('Tokyo', 35.68, 139.69),
    MobileV4GeoCity('Singapore', 1.35, 103.82),
    MobileV4GeoCity('Frankfurt', 50.11, 8.68),
    MobileV4GeoCity('New York', 40.71, -74.01),
    MobileV4GeoCity('San Francisco', 37.77, -122.42),
    MobileV4GeoCity('Sydney', -33.87, 151.21),
    MobileV4GeoCity('Sao Paulo', -23.55, -46.63),
  ];

  static const List<List<int>> _backgroundLinks = [
    [2, 4],
    [1, 5],
    [3, 6],
    [2, 1],
  ];

  static const List<double> _darkAlpha = [.03, .05, .085, .135, .21, .32];
  static const List<double> _lightAlpha = [.04, .07, .12, .19, .28, .42];
  static const List<double> _levelRadius = [.45, .55, .65, .75, .88, 1.0];

  /// Land-only Fibonacci dots (Natural Earth mask, 2303 points).
  static final List<_V3> _landDots = _decodeDots(landDotsEncoded);

  /// Country outlines, 285 rings / 6008 points.
  static final List<List<_V3>> _worldRings = _decodeRings(worldRingsEncoded);

  /// Precomputed unit vectors for peer hub cities to avoid trig per frame.
  static final List<_V3> _hubVectors = [
    for (final city in _hubCities) _llToVec(city.lat, city.lon),
  ];

  /// Yaw that puts a geographic coordinate dead-center on the front hemisphere.
  static double yawForLatLon(double lat, double lon) {
    final v = _llToVec(lat, lon);
    return math.atan2(-v.x, v.z);
  }

  /// Yaw that puts Tokyo at the front of the sphere.
  static final double _tokyoYaw = yawForLatLon(35.68, 139.69);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.44;
    if (radius <= 0) {
      return;
    }

    final yaw = rotation + (baseYaw ?? _tokyoYaw);
    final activeVec = _llToVec(activeCity.lat, activeCity.lon);

    // Subtle drop shadow beneath the porcelain sphere in light mode.
    if (!isDark) {
      canvas.drawCircle(
        center.translate(0, 12),
        radius * 0.96,
        Paint()
          ..color = _rgba(86, 74, 128, .12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    }

    // Sphere body: radial top-left highlight gives glass volume.
    final body = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-radius * .35, -radius * .4),
        radius * 1.05,
        isDark
            ? [
                _rgba(255, 255, 255, .055),
                _rgba(255, 255, 255, .016),
                _rgba(255, 255, 255, 0),
              ]
            : [
                _rgba(255, 255, 255, .94),
                _rgba(246, 244, 254, .62),
                _rgba(226, 222, 244, .34),
              ],
        const [0, .55, 1],
      );
    canvas.drawCircle(center, radius, body);

    _drawGraticule(canvas, center, radius, yaw);

    // Land dots, batched into 6 depth buckets.
    final buckets = List.generate(6, (_) => <Offset>[]);
    for (final v in _landDots) {
      final p = _project(v, yaw, center, radius);
      final t = (p.z + 1) / 2;
      final level = math.min(5, math.max(0, (t * 6).floor()));
      buckets[level].add(Offset(p.x, p.y));
    }
    final alphas = isDark ? _darkAlpha : _lightAlpha;
    for (var i = 0; i < 6; i++) {
      final pts = buckets[i];
      if (pts.isEmpty) {
        continue;
      }
      final paint = Paint()
        ..color = isDark
            ? _rgba(226, 230, 240, alphas[i])
            : _rgba(54, 48, 84, alphas[i])
        ..strokeWidth = _levelRadius[i] * 2
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(ui.PointMode.points, pts, paint);
    }

    _drawBorders(canvas, center, radius, yaw);
    _drawArcs(canvas, center, radius, yaw, activeVec);
    _drawCities(canvas, center, radius, yaw, activeVec);
    _drawLimb(canvas, center, radius);
  }

  void _drawBorders(Canvas canvas, Offset c, double r, double yaw) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..strokeJoin = StrokeJoin.round
      ..color = isDark
          ? _rgba(214, 222, 240, .32)
          : _rgba(74, 66, 112, .30);
    final path = Path();
    for (final ring in _worldRings) {
      var started = false;
      for (final v in ring) {
        final p = _project(v, yaw, c, r);
        if (p.z > .02) {
          if (!started) {
            path.moveTo(p.x, p.y);
            started = true;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          started = false;
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawGraticule(Canvas canvas, Offset c, double r, double yaw) {
    final path = Path();
    for (var lat = -60.0; lat <= 60; lat += 30) {
      var started = false;
      for (var lon = 0.0; lon <= 360; lon += 4) {
        final p = _project(_llToVec(lat, lon), yaw, c, r);
        if (p.z > .015) {
          if (!started) {
            path.moveTo(p.x, p.y);
            started = true;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          started = false;
        }
      }
    }
    for (var lon = 0.0; lon < 360; lon += 30) {
      var started = false;
      for (var lat = -80.0; lat <= 80; lat += 4) {
        final p = _project(_llToVec(lat, lon), yaw, c, r);
        if (p.z > .015) {
          if (!started) {
            path.moveTo(p.x, p.y);
            started = true;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          started = false;
        }
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = isDark
            ? _rgba(220, 225, 240, .055)
            : _rgba(86, 74, 128, .085),
    );
  }

  void _drawArcs(Canvas canvas, Offset c, double r, double yaw, _V3 activeVec) {
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: c, radius: r * .995)),
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = isDark
          ? _rgba(198, 184, 255, .19)
          : _rgba(108, 92, 231, .28);

    // Connect the active city to up to 3 peer hubs, plus background links.
    final pairs = <(_V3, _V3)>[];
    for (var i = 0; i < _hubVectors.length && pairs.length < 3; i++) {
      final hub = _hubVectors[i];
      if (_dot(activeVec, hub) < 0.996) {
        pairs.add((activeVec, hub));
      }
    }
    for (final link in _backgroundLinks) {
      pairs.add((_hubVectors[link[0]], _hubVectors[link[1]]));
    }

    for (var li = 0; li < pairs.length; li++) {
      final (a, b) = pairs[li];

      final path = Path();
      var started = false;
      for (var k = 0; k <= 48; k++) {
        final t = k / 48;
        final v = _slerp(a, b, t);
        final lift = 1.015 + math.sin(math.pi * t) * .07;
        final p = _project(v.scale(lift), yaw, c, r);
        if (p.z > -.05) {
          if (!started) {
            path.moveTo(p.x, p.y);
            started = true;
          } else {
            path.lineTo(p.x, p.y);
          }
        } else {
          started = false;
        }
      }
      canvas.drawPath(path, arcPaint);

      // A packet travelling along every other route (including primary active routes).
      if (li.isEven) {
        final t = (pulse * 1.7 + li * .21) % 1;
        final v = _slerp(a, b, t);
        final lift = 1.015 + math.sin(math.pi * t) * .07;
        final p = _project(v.scale(lift), yaw, c, r);
        if (p.z > .1) {
          canvas.drawCircle(
            Offset(p.x, p.y),
            1.7,
            Paint()
              ..color = isDark
                  ? _rgba(214, 204, 255, .85)
                  : _rgba(108, 92, 231, .92),
          );
        }
      }
    }
    canvas.restore();
  }

  void _drawCities(
    Canvas canvas,
    Offset c,
    double r,
    double yaw,
    _V3 activeVec,
  ) {
    // Peer hub dots (skipping any hub overlapping the active city).
    for (var i = 0; i < _hubVectors.length; i++) {
      final hubVec = _hubVectors[i];
      if (_dot(activeVec, hubVec) > 0.996) {
        continue;
      }
      final p = _project(hubVec, yaw, c, r);
      if (p.z <= .02) {
        continue;
      }
      canvas.drawCircle(
        Offset(p.x, p.y),
        1.8,
        Paint()
          ..color = isDark
              ? _rgba(226, 230, 240, (.25 + p.z * .75) * .6)
              : _rgba(74, 66, 112, (.25 + p.z * .75) * .55),
      );
    }

    // Active city golden breathing beacon.
    final activeProj = _project(activeVec, yaw, c, r);
    if (activeProj.z > .02) {
      final pos = Offset(activeProj.x, activeProj.y);
      final strength = connected ? 1.0 : .48;
      final (int nr, int ng, int nb) = isDark
          ? (242, 193, 78)
          : (229, 160, 29);
      canvas.drawCircle(
        pos,
        4 + pulse * 15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = _rgba(nr, ng, nb, .55 * (1 - pulse) * strength),
      );
      canvas.drawCircle(
        pos,
        4,
        Paint()
          ..color = _rgba(nr, ng, nb, .5 * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        pos,
        isDark ? 3.0 : 3.2,
        Paint()..color = _rgba(nr, ng, nb, strength),
      );
    }
  }

  void _drawLimb(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = isDark
            ? _rgba(170, 145, 255, .22)
            : _rgba(108, 92, 231, .20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = isDark
            ? _rgba(208, 200, 255, .22)
            : _rgba(108, 92, 231, .26),
    );
  }

  @override
  bool shouldRepaint(covariant MobileV4GlobePainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.pulse != pulse ||
      oldDelegate.connected != connected ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activeCity != activeCity ||
      oldDelegate.baseYaw != baseYaw;

  static List<_V3> _decodeDots(String s) =>
      s.split(';').map(_decodePoint).toList();

  static List<List<_V3>> _decodeRings(String s) => s
      .split('|')
      .map((ring) => ring.split(';').map(_decodePoint).toList())
      .toList();

  static _V3 _decodePoint(String p) {
    final parts = p.split(',');
    return _llToVec(int.parse(parts[1]) / 10, int.parse(parts[0]) / 10);
  }

  /// Right-handed sphere mapping (front = +z, right/East = +x, up/North = +y).
  static _V3 _llToVec(double lat, double lon) {
    final la = lat * math.pi / 180;
    final lo = lon * math.pi / 180;
    return _V3(
      math.cos(la) * math.sin(lo),
      math.sin(la),
      math.cos(la) * math.cos(lo),
    );
  }

  /// Projects a geographic coordinate at [yaw] for verification/testing.
  @visibleForTesting
  static Offset projectLatLonForTest(
    double lat,
    double lon, {
    required double yaw,
    Offset center = const Offset(100, 100),
    double radius = 100,
  }) {
    final p = _project(_llToVec(lat, lon), yaw, center, radius);
    return Offset(p.x, p.y);
  }

  static double _dot(_V3 a, _V3 b) => a.x * b.x + a.y * b.y + a.z * b.z;

  static _Proj _project(_V3 v, double yaw, Offset c, double r) {
    final cy = math.cos(yaw);
    final sy = math.sin(yaw);
    final x = v.x * cy + v.z * sy;
    final z0 = -v.x * sy + v.z * cy;
    final ct = math.cos(_tilt);
    final st = math.sin(_tilt);
    final y = v.y * ct - z0 * st;
    final z = v.y * st + z0 * ct;
    final persp = 1 / (1 - z * .26);
    return _Proj(c.dx + x * r * persp, c.dy - y * r * persp, z, persp);
  }

  static _V3 _slerp(_V3 a, _V3 b, double t) {
    final dot = _dot(a, b).clamp(-1.0, 1.0);
    final th = math.acos(dot);
    if (th < 1e-4) {
      return a;
    }
    final s = math.sin(th);
    final w1 = math.sin((1 - t) * th) / s;
    final w2 = math.sin(t * th) / s;
    return _V3(
      a.x * w1 + b.x * w2,
      a.y * w1 + b.y * w2,
      a.z * w1 + b.z * w2,
    );
  }

  static Color _rgba(int r, int g, int b, double a) =>
      Color.fromARGB((a.clamp(0.0, 1.0) * 255).round(), r, g, b);
}

class _V3 {
  const _V3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V3 scale(double s) => _V3(x * s, y * s, z * s);
}

class _Proj {
  const _Proj(this.x, this.y, this.z, this.scale);

  final double x;
  final double y;
  final double z;
  final double scale;
}
