/// Inspect the config about to be installed, not the previous live snapshot.
/// Dynamic providers need a core-owned runtime gate before they can be trusted.
List<String> validateDnsProxyTarget(Map config, String target) {
  return _DnsProxyGraph(config).validate(target);
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
