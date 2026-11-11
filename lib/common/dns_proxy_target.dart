/// Inspect the config about to be installed, not the previous live snapshot.
/// Dynamic providers need a core-owned runtime gate before they can be trusted.
List<String> validateDnsProxyTarget(Map config, String target) {
  return _DnsProxyGraph(config).validate(target);
}

const _reservedDnsTargets = {
  'DIRECT',
  'REJECT',
  'REJECT-DROP',
  'PASS',
  'COMPATIBLE',
  'RULES',
  'GLOBAL',
};

/// Resolve the proxy a config would actually use, so DNS leak protection can
/// pin its resolvers without asking the user to type a node name.
///
/// Only statically declared proxies are returned: a provider-backed node is
/// not present in [config] and cannot be validated before the core starts.
/// Returns an empty string when no concrete, non-reserved proxy is reachable.
String resolveAutoDnsProxyTarget(
  Map config, {
  Map<String, String> selectedMap = const {},
  String? preferredGroup,
}) {
  final proxies = <String>{};
  final proxyEntries = config['proxies'];
  if (proxyEntries is List) {
    for (final entry in proxyEntries) {
      if (entry is Map && entry['name'] is String) {
        proxies.add(entry['name'] as String);
      }
    }
  }
  final groups = <String, Map>{};
  final groupEntries = config['proxy-groups'];
  if (groupEntries is List) {
    for (final entry in groupEntries) {
      if (entry is Map && entry['name'] is String) {
        groups[entry['name'] as String] = entry;
      }
    }
  }
  if (proxies.isEmpty || groups.isEmpty) {
    return '';
  }

  String? start;
  final preferred = preferredGroup?.trim() ?? '';
  if (preferred.isNotEmpty && groups.containsKey(preferred)) {
    start = preferred;
  }
  if (start == null) {
    for (final name in groups.keys) {
      final selected = selectedMap[name];
      if (selected != null && selected.isNotEmpty) {
        start = name;
        break;
      }
    }
  }
  if (start == null) {
    for (final entry in groups.values) {
      if (entry['type'] == 'select') {
        start = entry['name'] as String;
        break;
      }
    }
  }
  if (start == null) {
    return '';
  }
  return _resolveAutoTarget(
    start,
    groups: groups,
    proxies: proxies,
    selectedMap: selectedMap,
    visiting: <String>{},
    depth: 0,
  );
}

String _resolveAutoTarget(
  String name, {
  required Map<String, Map> groups,
  required Set<String> proxies,
  required Map<String, String> selectedMap,
  required Set<String> visiting,
  required int depth,
}) {
  if (depth > 32 || !visiting.add(name)) {
    return '';
  }
  try {
    final group = groups[name];
    if (group == null) {
      return proxies.contains(name) ? name : '';
    }
    final selected = selectedMap[name];
    if (selected != null && selected.isNotEmpty) {
      final resolved = _resolveAutoTarget(
        selected,
        groups: groups,
        proxies: proxies,
        selectedMap: selectedMap,
        visiting: visiting,
        depth: depth + 1,
      );
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    final now = group['now'];
    if (now is String && now.isNotEmpty) {
      final resolved = _resolveAutoTarget(
        now,
        groups: groups,
        proxies: proxies,
        selectedMap: selectedMap,
        visiting: visiting,
        depth: depth + 1,
      );
      if (resolved.isNotEmpty) {
        return resolved;
      }
    }
    final members = group['proxies'];
    if (members is List) {
      for (final member in members) {
        if (member is! String ||
            member.isEmpty ||
            _reservedDnsTargets.contains(member.toUpperCase())) {
          continue;
        }
        final resolved = _resolveAutoTarget(
          member,
          groups: groups,
          proxies: proxies,
          selectedMap: selectedMap,
          visiting: visiting,
          depth: depth + 1,
        );
        if (resolved.isNotEmpty) {
          return resolved;
        }
      }
    }
    return '';
  } finally {
    visiting.remove(name);
  }
}

class _DnsProxyGraph {
  _DnsProxyGraph(Map config) {
    for (final key in ['proxies', 'proxy-groups']) {
      final entries = config[key];
      if (entries is! List) {
        continue;
      }
      for (final entry in entries) {
        if (entry is! Map || entry['name'] is! String) {
          continue;
        }
        final name = entry['name'] as String;
        if (_nodes.containsKey(name)) {
          _duplicates.add(name);
        }
        _nodes[name] = entry;
        if (key == 'proxy-groups') {
          _groups.add(name);
        }
      }
    }
  }

  final _nodes = <String, Map>{};
  final _groups = <String>{};
  final _duplicates = <String>{};
  final _visiting = <String>{};
  final _visited = <String>{};
  final _errors = <String>{};

  List<String> validate(String target) {
    _visit(target);
    return _errors.toList();
  }

  void _visit(String name) {
    if (_visited.contains(name)) {
      return;
    }
    if (const {
      'DIRECT',
      'REJECT',
      'REJECT-DROP',
      'PASS',
      'COMPATIBLE',
      'GLOBAL',
      'RULES',
    }.contains(name.toUpperCase())) {
      _errors.add('dns-proxy-target-not-proxy');
      return;
    }
    if (_duplicates.contains(name)) {
      _errors.add('dns-proxy-target-duplicate');
      return;
    }
    final node = _nodes[name];
    if (node == null) {
      _errors.add('dns-proxy-target-not-found');
      return;
    }
    if (_visiting.length >= 128) {
      _errors.add('dns-proxy-target-too-deep');
      return;
    }
    if (!_visiting.add(name)) {
      _errors.add('dns-proxy-target-cycle');
      return;
    }
    if (_groups.contains(name)) {
      _visitGroup(node);
    } else {
      // Deliberately conservative: unfamiliar outbounds are not proof of a
      // proxy path. Do not infer safety from an arbitrary `type` string.
      if (!const {
        'ss',
        'ssr',
        'socks5',
        'http',
        'vmess',
        'vless',
        'trojan',
        'snell',
        'hysteria',
        'hysteria2',
        'tuic',
        'wireguard',
        'ssh',
        'anytls',
        'mieru',
        'masque',
        'trusttunnel',
      }.contains(node['type'])) {
        _errors.add('dns-proxy-target-unverified-type');
      }
      final dialerProxy = node['dialer-proxy'];
      if (dialerProxy != null && dialerProxy != '') {
        if (dialerProxy is String) {
          _visit(dialerProxy);
        } else {
          _errors.add('dns-proxy-target-invalid-chain');
        }
      }
    }
    _visiting.remove(name);
    _visited.add(name);
  }

  void _visitGroup(Map node) {
    if (!const {
      'select',
      'url-test',
      'fallback',
      'load-balance',
    }.contains(node['type'])) {
      _errors.add('dns-proxy-target-unverified-group');
    }
    final use = node['use'];
    if (node['include-all'] == true ||
        node['include-all-proxies'] == true ||
        node['include-all-providers'] == true ||
        (use != null && (use is! List || use.isNotEmpty))) {
      // A provider can refresh after validation, including an empty set which
      // upstream groups replace with DIRECT. A static snapshot cannot gate it.
      _errors.add('dns-proxy-target-dynamic-group');
    }
    final members = node['proxies'];
    if (members is! List || members.isEmpty) {
      _errors.add('dns-proxy-target-empty-group');
      return;
    }
    for (final member in members) {
      if (member is String) {
        _visit(member);
      } else {
        _errors.add('dns-proxy-target-invalid-member');
      }
    }
    // Group-level filtering may remove every candidate and trigger DIRECT.
    if ((node['filter'] != null && node['filter'] != '') ||
        (node['exclude-filter'] != null && node['exclude-filter'] != '') ||
        (node['exclude-type'] != null && node['exclude-type'] != '')) {
      _errors.add('dns-proxy-target-filtered-group');
    }
  }
}
