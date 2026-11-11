import 'dart:convert';
import 'dart:io';

import 'package:quanclash/common/dns_proxy_target.dart';
import 'package:quanclash/common/string.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/clash_config.dart';

const systemDnsNameserver = 'system://';

/// Returns [raw] as an IP literal host, or null when it is not one.
///
/// Accepts a bare address (`8.8.8.8`) and a resolver URI (`udp://8.8.8.8`).
String? ipLiteralHost(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (!value.contains('://')) {
    return InternetAddress.tryParse(value) != null ? value : null;
  }
  try {
    final host = Uri.parse(value).host;
    return InternetAddress.tryParse(host) != null ? host : null;
  } catch (_) {
    return null;
  }
}

/// Make the DNS bootstrap resolvers acceptable to the strict validator.
///
/// `default-nameserver` and `proxy-server-nameserver` exist to resolve the
/// hostnames of the real resolvers, so both must be IP literals: a hostname or
/// `system` there cannot be resolved and is rejected by [_checkBootstrap].
/// Providers do ship `default-nameserver: [system, ...]`; without this repair
/// the whole leak-protection config is discarded and DNS silently stays
/// unpinned.
Map<String, dynamic> repairDnsBootstrap(Map<String, dynamic> dns) {
  var changed = false;
  final next = Map<String, dynamic>.from(dns);

  final defaults = dns['default-nameserver'];
  final keptDefaults = defaults is List
      ? [
          for (final value in defaults)
            if (value is String && ipLiteralHost(value) != null) value,
        ]
      : <Object>[];
  if (defaults is List && keptDefaults.length != defaults.length) {
    next['default-nameserver'] = keptDefaults;
    changed = true;
  }

  String? bootstrapHost;
  final bootstrap = next['proxy-server-nameserver'];
  for (final value in bootstrap is List ? bootstrap : [bootstrap]) {
    if (value is String) {
      bootstrapHost = ipLiteralHost(value);
      if (bootstrapHost != null) {
        break;
      }
    }
  }
  if (bootstrapHost == null) {
    for (final value in keptDefaults) {
      bootstrapHost = ipLiteralHost(value as String);
      if (bootstrapHost != null) {
        next['proxy-server-nameserver'] = [bootstrapHost];
        changed = true;
        break;
      }
    }
  }
  if (keptDefaults.isEmpty && bootstrapHost != null) {
    next['default-nameserver'] = [bootstrapHost];
    changed = true;
  }
  return changed ? next : dns;
}

class EffectiveDnsConfig {
  const EffectiveDnsConfig({
    required this.config,
    required this.mode,
    required this.warnings,
    required this.errors,
  });

  final Map<String, dynamic> config;
  final DnsSafetyMode mode;
  final List<String> warnings;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

EffectiveDnsConfig buildEffectiveDnsConfig({
  required Map? profileDns,
  required Dns patchDns,
  required bool overrideDns,
  required bool appendSystemDns,
  DnsSafetyMode safetyMode = DnsSafetyMode.compatible,
  String proxyTarget = '',
  Map? proxyConfig,
}) {
  final usePatchDns = overrideDns || profileDns?['enable'] != true;
  final dns =
      jsonDecode(jsonEncode(usePatchDns ? patchDns : profileDns))
          as Map<String, dynamic>;
  if (usePatchDns) {
    dns['nameserver-policy'] = {
      for (final entry in patchDns.nameserverPolicy.entries)
        entry.key: entry.value.splitByMultipleSeparators,
    };
  }
  final warnings = <String>[];
  final errors = <String>[];

  if (appendSystemDns) {
    final nameservers = _serverList(dns['nameserver']);
    if (!nameservers.any(_isSystemNameserver)) {
      nameservers.add(systemDnsNameserver);
    }
    dns['nameserver'] = nameservers;
    warnings.add('dns-system-dns-appended');
  }

  switch (safetyMode) {
    case DnsSafetyMode.compatible:
      if (dns['enable'] == false) {
        warnings.add('dns-disabled');
      }
      warnings.add('dns-compatible-mode-not-strict');
    case DnsSafetyMode.custom:
      warnings.add('dns-custom-mode-unverified');
    case DnsSafetyMode.proxyOnly:
      _applyProxyOnly(dns, proxyTarget, proxyConfig, warnings, errors);
  }
  return EffectiveDnsConfig(
    config: dns,
    mode: safetyMode,
    warnings: List.unmodifiable(warnings.toSet()),
    errors: List.unmodifiable(errors.toSet()),
  );
}

void _applyProxyOnly(
  Map<String, dynamic> dns,
  String proxyTarget,
  Map? proxyConfig,
  List<String> warnings,
  List<String> errors,
) {
  final target = proxyTarget.trim();
  if (target.isEmpty) {
    errors.add('dns-proxy-target-required');
  } else if (_isReservedTarget(target)) {
    errors.add('dns-proxy-target-reserved');
  } else if (RegExp(r'[&#=%\r\n]').hasMatch(target)) {
    errors.add('dns-proxy-target-invalid-fragment');
  } else {
    errors.addAll(validateDnsProxyTarget(proxyConfig ?? {}, target));
  }
  if (dns['enable'] != true) {
    errors.add('dns-disabled');
  }
  if (dns['respect-rules'] == true) {
    errors.add('dns-respect-rules-not-strict');
  }
  // Also pin direct-traffic DNS. Leaving this role direct would bypass the
  // ordinary-query privacy policy when a routing rule selects DIRECT.
  for (final role in ['nameserver', 'fallback', 'direct-nameserver']) {
    if (role == 'nameserver' || dns.containsKey(role)) {
      final servers = _strictServerList(dns[role], role, errors);
      if (role == 'nameserver' && servers.isEmpty) {
        errors.add('dns-nameserver-missing');
      }
      dns[role] = [
        for (final value in servers) _pinServer(role, value, target, errors),
      ];
    }
  }
  final policy = dns['nameserver-policy'];
  if (policy != null && policy is! Map) {
    errors.add('dns-nameserver-policy-invalid-shape');
  } else if (policy is Map) {
    dns['nameserver-policy'] = {
      for (final entry in policy.entries)
        entry.key: [
          for (final value in _strictServerList(
            entry.value,
            'nameserver-policy',
            errors,
            allowString: true,
          ))
            _pinServer('nameserver-policy', value, target, errors),
        ],
    };
  }
  for (final role in ['default-nameserver', 'proxy-server-nameserver']) {
    final servers = _strictServerList(dns[role], role, errors);
    if (servers.isEmpty) {
      errors.add('dns-$role-missing');
    }
    _checkBootstrap(role, servers, errors);
  }
  final bootstrapPolicy = dns['proxy-server-nameserver-policy'];
  if (bootstrapPolicy != null && bootstrapPolicy is! Map) {
    errors.add('dns-proxy-server-nameserver-policy-invalid-shape');
  } else if (bootstrapPolicy is Map) {
    for (final value in bootstrapPolicy.values) {
      final servers = _strictServerList(
        value,
        'proxy-server-nameserver-policy',
        errors,
        allowString: true,
      );
      if (servers.isEmpty) {
        errors.add('dns-proxy-server-nameserver-policy-missing');
      }
      _checkBootstrap('proxy-server-nameserver-policy', servers, errors);
    }
  }
  warnings.add('dns-explicit-bootstrap-direct');
  warnings.add('configuration-only-not-a-leak-test');
}

String _pinServer(
  String role,
  String value,
  String target,
  List<String> errors,
) {
  final uri = _serverUri(value);
  if (uri == null) {
    errors.add('dns-$role-invalid-resolver');
    return value;
  }
  if (uri.scheme == 'rcode') {
    return value;
  }
  if (_isHostResolver(uri)) {
    errors.add('dns-$role-system-resolver');
    return value;
  }
  if (!_isOrdinaryResolver(uri)) {
    errors.add('dns-$role-unverified-transport');
    return value;
  }
  final fragment = _decodedFragment(uri);
  if (fragment == null) {
    errors.add('dns-$role-invalid-fragment');
    return value;
  }
  final fragments = fragment.split('&').where((part) => part.isNotEmpty);
  final tags = fragments.where((part) => !part.contains('=')).toList();
  if (tags.any(_isReservedTarget)) {
    errors.add('dns-$role-direct-path');
    return value;
  }
  // Upstream uses the LAST bare fragment, not the first. Do not allow multiple
  // selectors or a different group to evade the single validated target.
  if (tags.length > 1 || (tags.isNotEmpty && tags.single != target)) {
    errors.add('dns-$role-proxy-target-mismatch');
    return value;
  }
  if (target.isEmpty) {
    return value;
  }
  final params = fragments.where((part) => part.contains('='));
  return uri.replace(fragment: [target, ...params].join('&')).toString();
}

void _checkBootstrap(String role, List<String> servers, List<String> errors) {
  for (final value in servers) {
    final uri = _serverUri(value);
    if (uri == null || !_isOrdinaryResolver(uri)) {
      errors.add('dns-$role-invalid-bootstrap');
    } else if (InternetAddress.tryParse(uri.host) == null) {
      errors.add('dns-$role-not-ip-literal');
    } else if (_decodedFragment(uri) == null ||
        _decodedFragment(
          uri,
        )!.split('&').any((part) => part.isNotEmpty && !part.contains('='))) {
      errors.add('dns-$role-bootstrap-proxy-cycle');
    }
  }
}

String? _decodedFragment(Uri uri) {
  try {
    // Dart exposes encoded fragments; Go's url.Parse exposes a decoded one.
    return Uri.decodeComponent(uri.fragment);
  } on FormatException {
    return null;
  }
}

List<String> _strictServerList(
  Object? value,
  String role,
  List<String> errors, {
  bool allowString = false,
}) {
  if (value == null) {
    return [];
  }
  if (allowString && value is String) {
    // YAML policy strings represent ONE server (including spaces in a group
    // name), while patch policy separator conversion happens before this step.
    return value.isEmpty ? [] : [value];
  }
  if (value is List &&
      value.every((item) => item is String && item.isNotEmpty)) {
    return List<String>.from(value);
  }
  errors.add('dns-$role-invalid-shape');
  return [];
}

List<String> _serverList(Object? value) {
  if (value is String) {
    return [value];
  }
  return value is List ? [for (final item in value) '$item'] : [];
}

Uri? _serverUri(String raw) {
  try {
    var value = raw.trim();
    if (value == 'system') {
      value = 'system://';
    } else if (!value.contains('://')) {
      final ip = InternetAddress.tryParse(value);
      value = ip?.type == InternetAddressType.IPv6
          ? 'udp://[$value]'
          : 'udp://$value';
    }
    final uri = Uri.parse(value);
    // Force validation of malformed ports and percent escapes here.
    uri.port;
    return uri;
  } on FormatException {
    return null;
  }
}

bool _isSystemNameserver(String value) {
  final uri = _serverUri(value);
  return uri?.scheme == 'system' ||
      (uri?.scheme == 'dhcp' && uri?.host == 'system');
}

bool _isHostResolver(Uri uri) => uri.scheme == 'system' || uri.scheme == 'dhcp';

bool _isOrdinaryResolver(Uri uri) =>
    const {'udp', 'tcp', 'tls', 'http', 'https', 'quic'}.contains(uri.scheme) &&
    uri.host.isNotEmpty;

bool _isReservedTarget(String value) => const {
  'DIRECT',
  'REJECT',
  'REJECT-DROP',
  'PASS',
  'COMPATIBLE',
  'RULES',
  'GLOBAL',
}.contains(value.toUpperCase());
