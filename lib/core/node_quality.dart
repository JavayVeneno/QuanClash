import 'dart:io';

enum NodeQualityStatus { ok, failed, timeout, unavailable, notRequested }

class NodeQualityProbe {
  final String provider;
  final NodeQualityStatus status;
  final String? reason;
  final String? egressIp;
  final String? colo;
  final String? country;
  final int? ttfbMs;
  final int? riskScore;
  final bool? isResidential;

  const NodeQualityProbe._({
    required this.provider,
    required this.status,
    this.reason,
    this.egressIp,
    this.colo,
    this.country,
    this.ttfbMs,
    this.riskScore,
    this.isResidential,
  });

  factory NodeQualityProbe.fromJson(
    Map<String, dynamic> json, {
    required String provider,
  }) {
    if (json['provider'] != provider) {
      throw const FormatException('Unexpected node quality provider');
    }
    final status = switch (json['status']) {
      'ok' => NodeQualityStatus.ok,
      'failed' => NodeQualityStatus.failed,
      'timeout' => NodeQualityStatus.timeout,
      'unavailable' => NodeQualityStatus.unavailable,
      'not-requested' => NodeQualityStatus.notRequested,
      _ => throw const FormatException('Invalid node quality status'),
    };
    final ip = json['egressIp'] as String?;
    final address = ip == null ? null : InternetAddress.tryParse(ip);
    if (ip != null &&
        (address == null ||
            ip.contains('%') ||
            address.isMulticast ||
            address.rawAddress.every((byte) => byte == 0))) {
      throw const FormatException('Invalid node quality IP');
    }
    final ttfb = json['ttfbMs'] as int?;
    final score = json['riskScore'] as int?;
    final residential = json['isResidential'] as bool?;
    final colo = json['colo'] as String?;
    final country = json['country'] as String?;
    if ((ttfb != null && (ttfb < 0 || ttfb > 12000)) ||
        (score != null && (score < 0 || score > 100)) ||
        (colo != null && !RegExp(r'^[A-Z]{3}$').hasMatch(colo)) ||
        (country != null && !RegExp(r'^[A-Z]{2}$').hasMatch(country))) {
      throw const FormatException('Invalid node quality metrics');
    }
    if (status == NodeQualityStatus.ok && address == null) {
      throw const FormatException('Missing node quality IP');
    }
    if (status != NodeQualityStatus.ok &&
        [ip, ttfb, score, residential, colo, country].any((v) => v != null)) {
      throw const FormatException('Failed probe contains success metrics');
    }
    if ((provider == 'cloudflare' && (score != null || residential != null)) ||
        (provider == 'ippure' &&
            (ttfb != null || colo != null || country != null))) {
      throw const FormatException('Mixed node quality metrics');
    }
    return NodeQualityProbe._(
      provider: provider,
      status: status,
      reason: json['reason'] as String?,
      egressIp: ip,
      colo: colo,
      country: country,
      ttfbMs: ttfb,
      // IPv6 scoring semantics are unverified, including beta default zeroes.
      riskScore: address?.type == InternetAddressType.IPv6 ? null : score,
      isResidential: residential,
    );
  }
}

class NodeQualityResult {
  final String proxyName;
  final DateTime sampledAt;
  final NodeQualityProbe network;
  final NodeQualityProbe quality;

  const NodeQualityResult._({
    required this.proxyName,
    required this.sampledAt,
    required this.network,
    required this.quality,
  });

  bool get egressMismatch =>
      network.egressIp != null &&
      quality.egressIp != null &&
      InternetAddress(network.egressIp!).rawAddress.join(',') !=
          InternetAddress(quality.egressIp!).rawAddress.join(',');

  bool matchesRequest(String name, {required bool includeIpPure}) =>
      proxyName == name &&
      network.status != NodeQualityStatus.notRequested &&
      (includeIpPure
          ? quality.status != NodeQualityStatus.notRequested
          : quality.status == NodeQualityStatus.notRequested);

  factory NodeQualityResult.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['source'] != 'selected-proxy') {
      throw const FormatException('Unsupported node quality schema');
    }
    final name = json['proxyName'] as String;
    final sampledAt = DateTime.tryParse(json['sampledAt'] as String);
    if (name.isEmpty || sampledAt == null || !sampledAt.isUtc) {
      throw const FormatException('Invalid node quality identity');
    }
    return NodeQualityResult._(
      proxyName: name,
      sampledAt: sampledAt,
      network: NodeQualityProbe.fromJson(
        Map<String, dynamic>.from(json['network'] as Map),
        provider: 'cloudflare',
      ),
      quality: NodeQualityProbe.fromJson(
        Map<String, dynamic>.from(json['quality'] as Map),
        provider: 'ippure',
      ),
    );
  }
}

typedef NodeQualityClock = DateTime Function();

/// Bounds repeated manual probes for the same node/provider pair.
///
/// This is a local courtesy limit, not an IP-level or server-enforced quota:
/// different node names may share an egress IP, and restarting the app clears it.
class NodeQualityCooldown {
  NodeQualityCooldown({
    this.interval = const Duration(seconds: 30),
    NodeQualityClock? clock,
    this.maxEntries = 256,
  }) : assert(interval >= Duration.zero),
       assert(maxEntries > 0),
       _clock = clock ?? DateTime.now;

  final Duration interval;
  final int maxEntries;
  final NodeQualityClock _clock;
  final Map<(String, String), DateTime> _lastAttempts =
      <(String, String), DateTime>{};

  Duration remaining(String proxyName, String provider) {
    final key = (proxyName, provider);
    final last = _lastAttempts[key];
    if (last == null) {
      return Duration.zero;
    }
    final elapsed = _clock().difference(last);
    if (elapsed >= interval) {
      _lastAttempts.remove(key);
      return Duration.zero;
    }
    return interval - elapsed;
  }

  void record(String proxyName, String provider) {
    final now = _clock();
    _lastAttempts[(proxyName, provider)] = now;
    if (_lastAttempts.length <= maxEntries) {
      return;
    }
    _lastAttempts.removeWhere((_, last) => now.difference(last) >= interval);
    while (_lastAttempts.length > maxEntries) {
      (String, String)? oldestKey;
      DateTime? oldestAt;
      for (final entry in _lastAttempts.entries) {
        if (oldestAt == null || entry.value.isBefore(oldestAt)) {
          oldestAt = entry.value;
          oldestKey = entry.key;
        }
      }
      if (oldestKey == null) {
        return;
      }
      _lastAttempts.remove(oldestKey);
    }
  }

  void clear() => _lastAttempts.clear();
}
