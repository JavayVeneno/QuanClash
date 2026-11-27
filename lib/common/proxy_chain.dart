import 'dart:convert';

import 'package:quanclash/models/models.dart';

const Set<String> _builtinPolicies = {
  'DIRECT',
  'REJECT',
  'REJECT-DROP',
  'PASS',
  'COMPATIBLE',
  'GLOBAL',
  'RULES',
};

const Set<String> _quicProtocols = {
  'hysteria',
  'hysteria2',
  'tuic',
  'masque',
  'wireguard',
};

const Set<String> _udpNativeProtocols = {
  'hysteria',
  'hysteria2',
  'tuic',
  'masque',
  'wireguard',
  'snell',
};

enum ChainIssueLevel {
  error,
  warning,
}

enum ChainIssueCode {
  emptyName,
  entryEmpty,
  exitEmpty,
  builtinMember,
  nodeBothSides,
  exitHasDialer,
  cycle,
  providerNodeStrict,
  missingNode,
  nameConflict,
  invalidExitType,
  udpQuicMismatch,
}

enum ChainTargetSide {
  entry,
  exit,
  connector,
  chain,
}

class ChainIssue {
  const ChainIssue({
    required this.level,
    required this.code,
    required this.chainId,
    required this.chainName,
    this.nodeName,
    this.detail,
    this.targetSide = ChainTargetSide.chain,
  });

  final ChainIssueLevel level;
  final ChainIssueCode code;
  final int chainId;
  final String chainName;
  final String? nodeName;
  final String? detail;
  final ChainTargetSide targetSide;

  bool get isError => level == ChainIssueLevel.error;
  bool get isWarning => level == ChainIssueLevel.warning;
}

class ProxyChainApplyResult {
  const ProxyChainApplyResult({
    required this.config,
    required this.issues,
    required this.issuesByChainId,
    required this.activeChainGroupNames,
    this.matchSelectGroupName,
  });

  final Map<String, dynamic> config;
  final List<ChainIssue> issues;
  final Map<int, List<ChainIssue>> issuesByChainId;
  final List<String> activeChainGroupNames;
  final String? matchSelectGroupName;

  bool get hasErrors => issues.any((issue) => issue.isError);
}

bool isBuiltinPolicyName(String name) {
  return _builtinPolicies.contains(name.trim().toUpperCase());
}

bool isQuicProtocol(String? type) {
  if (type == null) return false;
  return _quicProtocols.contains(type.trim().toLowerCase());
}

bool nodeSupportsUdp(Map<String, dynamic> node) {
  final rawUdp = node['udp'];
  if (rawUdp is bool) {
    return rawUdp;
  }
  final type = (node['type'] as String?)?.trim().toLowerCase() ?? '';
  return _udpNativeProtocols.contains(type);
}

/// Extracts static proxy maps indexed by proxy name from [rawConfig].
Map<String, Map<String, dynamic>> extractStaticProxies(
  Map<String, dynamic> rawConfig,
) {
  final result = <String, Map<String, dynamic>>{};
  final proxies = rawConfig['proxies'];
  if (proxies is! List) {
    return result;
  }
  for (final item in proxies) {
    if (item is Map) {
      final name = item['name'];
      if (name is String && name.isNotEmpty) {
        result[name] = Map<String, dynamic>.from(item);
      }
    }
  }
  return result;
}

Set<String> extractExistingProxyAndGroupNames(Map<String, dynamic> rawConfig) {
  final names = <String>{};
  final proxies = rawConfig['proxies'];
  if (proxies is List) {
    for (final item in proxies) {
      if (item is Map && item['name'] is String) {
        names.add(item['name'] as String);
      }
    }
  }
  final groups = rawConfig['proxy-groups'];
  if (groups is List) {
    for (final item in groups) {
      if (item is Map && item['name'] is String) {
        names.add(item['name'] as String);
      }
    }
  }
  return names;
}

/// Finds the `MATCH` rule's target group name if it points to a `select` group.
String? findMatchSelectGroupName(Map<String, dynamic> rawConfig) {
  final rules = rawConfig['rules'];
  final groups = rawConfig['proxy-groups'];
  if (rules is! List || groups is! List) {
    return null;
  }
  String? matchTarget;
  for (var i = rules.length - 1; i >= 0; i--) {
    final entry = rules[i];
    if (entry is! String) continue;
    final parts = entry.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2 && parts[0].toUpperCase() == 'MATCH') {
      matchTarget = parts[1];
      break;
    }
  }
  if (matchTarget == null || matchTarget.isEmpty) {
    return null;
  }
  for (final group in groups) {
    if (group is Map &&
        group['name'] == matchTarget &&
        (group['type'] as String?)?.toLowerCase() == 'select') {
      return matchTarget;
    }
  }
  return null;
}

/// Counts rules referencing [chainGroupName] across raw config rules and extra rules.
List<String> findChainRuleReferences(
  Map<String, dynamic> rawConfig,
  String chainGroupName, {
  Iterable<Rule> extraRules = const [],
}) {
  final refs = <String>[];
  final rules = rawConfig['rules'];
  if (rules is List) {
    for (final entry in rules) {
      if (entry is! String) continue;
      final parsed = Rule.parse(entry);
      if (parsed.ruleTarget == chainGroupName) {
        refs.add(entry);
      }
    }
  }
  for (final rule in extraRules) {
    if (rule.ruleTarget == chainGroupName) {
      refs.add(rule.rawValue);
    }
  }
  return refs;
}

/// Validates a single [chain] against [rawConfig].
List<ChainIssue> validateSingleChain(
  ProxyChain chain,
  Map<String, dynamic> rawConfig, {
  bool strictDns = true,
  Set<String> reservedNames = const {},
}) {
  final issues = <ChainIssue>[];
  final staticProxies = extractStaticProxies(rawConfig);
  final existingNames = {
    ...extractExistingProxyAndGroupNames(rawConfig),
    ...reservedNames,
  };
  final trimmedName = chain.name.trim();

  if (trimmedName.isEmpty) {
    issues.add(
      ChainIssue(
        level: ChainIssueLevel.error,
        code: ChainIssueCode.emptyName,
        chainId: chain.id,
        chainName: chain.name,
        targetSide: ChainTargetSide.chain,
      ),
    );
  }

  if (chain.sourceType == ChainSourceType.provider && strictDns) {
    issues.add(
      ChainIssue(
        level: ChainIssueLevel.error,
        code: ChainIssueCode.providerNodeStrict,
        chainId: chain.id,
        chainName: chain.name,
        targetSide: ChainTargetSide.chain,
      ),
    );
  }

  if (chain.exit.type != ChainGroupType.fallback &&
      chain.exit.type != ChainGroupType.select) {
    issues.add(
      ChainIssue(
        level: ChainIssueLevel.error,
        code: ChainIssueCode.invalidExitType,
        chainId: chain.id,
        chainName: chain.name,
        detail: chain.exit.type.yamlValue,
        targetSide: ChainTargetSide.exit,
      ),
    );
  }

  final entryMembers = chain.entry.members;
  final exitMembers = chain.exit.members;

  if (entryMembers.isEmpty) {
    issues.add(
      ChainIssue(
        level: ChainIssueLevel.error,
        code: ChainIssueCode.entryEmpty,
        chainId: chain.id,
        chainName: chain.name,
        targetSide: ChainTargetSide.entry,
      ),
    );
  }
  if (exitMembers.isEmpty) {
    issues.add(
      ChainIssue(
        level: ChainIssueLevel.error,
        code: ChainIssueCode.exitEmpty,
        chainId: chain.id,
        chainName: chain.name,
        targetSide: ChainTargetSide.exit,
      ),
    );
  }

  if (trimmedName.isNotEmpty) {
    if (existingNames.contains(chain.groupName)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.nameConflict,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: chain.groupName,
          targetSide: ChainTargetSide.chain,
        ),
      );
    }
    if (entryMembers.length > 1 &&
        existingNames.contains(chain.entryGroupName)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.nameConflict,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: chain.entryGroupName,
          targetSide: ChainTargetSide.entry,
        ),
      );
    }
  }

  final entrySet = entryMembers.toSet();
  for (final member in entryMembers) {
    if (isBuiltinPolicyName(member)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.builtinMember,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          targetSide: ChainTargetSide.entry,
        ),
      );
      continue;
    }
    if (!staticProxies.containsKey(member)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.missingNode,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          targetSide: ChainTargetSide.entry,
        ),
      );
    }
  }

  for (final member in exitMembers) {
    if (isBuiltinPolicyName(member)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.builtinMember,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          targetSide: ChainTargetSide.exit,
        ),
      );
      continue;
    }
    if (entrySet.contains(member)) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.nodeBothSides,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          targetSide: ChainTargetSide.exit,
        ),
      );
    }
    final node = staticProxies[member];
    if (node == null) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.missingNode,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          targetSide: ChainTargetSide.exit,
        ),
      );
      continue;
    }
    final existingDialer = node['dialer-proxy'];
    if (existingDialer is String && existingDialer.trim().isNotEmpty) {
      issues.add(
        ChainIssue(
          level: ChainIssueLevel.error,
          code: ChainIssueCode.exitHasDialer,
          chainId: chain.id,
          chainName: chain.name,
          nodeName: member,
          detail: existingDialer.trim(),
          targetSide: ChainTargetSide.exit,
        ),
      );
    }
  }

  // Detect dialer-proxy cycles starting from entry members or referencing
  // generated chain names.
  final generatedNames = <String>{
    chain.groupName,
    if (entryMembers.length > 1) chain.entryGroupName,
    for (final m in exitMembers) chain.exitCopyName(m),
  };
  for (final member in entryMembers) {
    final visited = <String>{};
    String? cursor = member;
    while (cursor != null && cursor.isNotEmpty) {
      if (generatedNames.contains(cursor) || !visited.add(cursor)) {
        issues.add(
          ChainIssue(
            level: ChainIssueLevel.error,
            code: ChainIssueCode.cycle,
            chainId: chain.id,
            chainName: chain.name,
            nodeName: member,
            detail: [...visited, cursor].join(' → '),
            targetSide: ChainTargetSide.connector,
          ),
        );
        break;
      }
      final node = staticProxies[cursor];
      final next = node?['dialer-proxy'];
      cursor = next is String && next.trim().isNotEmpty ? next.trim() : null;
    }
  }

  // Non-blocking warning: QUIC exit requires UDP forwarding on entry nodes.
  final quicExits = exitMembers.where((name) {
    final node = staticProxies[name];
    return node != null && isQuicProtocol(node['type'] as String?);
  }).toList();
  if (quicExits.isNotEmpty) {
    for (final entryName in entryMembers) {
      final node = staticProxies[entryName];
      if (node != null && !nodeSupportsUdp(node)) {
        issues.add(
          ChainIssue(
            level: ChainIssueLevel.warning,
            code: ChainIssueCode.udpQuicMismatch,
            chainId: chain.id,
            chainName: chain.name,
            nodeName: entryName,
            detail: quicExits.first,
            targetSide: ChainTargetSide.entry,
          ),
        );
        break;
      }
    }
  }

  return issues;
}

/// Applies valid [chains] onto a deep copy of [rawConfig].
///
/// Must run after script evaluation and before DNS repair/validation so all
/// three overwrite modes (`standard`, `script`, `custom`) share one pipeline
/// and strict DNS validation checks the generated static groups and dialer
/// paths.
ProxyChainApplyResult applyProxyChains(
  Map<String, dynamic> rawConfig,
  List<ProxyChain> chains, {
  bool chainsEnabled = true,
  bool strictDns = true,
  String defaultTestUrl = 'https://www.gstatic.com/generate_204',
}) {
  if (!chainsEnabled || chains.isEmpty) {
    return ProxyChainApplyResult(
      config: rawConfig,
      issues: const [],
      issuesByChainId: const {},
      activeChainGroupNames: const [],
    );
  }

  final config =
      jsonDecode(jsonEncode(rawConfig)) as Map<String, dynamic>;
  final staticProxies = extractStaticProxies(config);
  final proxiesList = config['proxies'] is List
      ? List<dynamic>.from(config['proxies'] as List)
      : <dynamic>[];
  final groupsList = config['proxy-groups'] is List
      ? List<dynamic>.from(config['proxy-groups'] as List)
      : <dynamic>[];

  final allIssues = <ChainIssue>[];
  final issuesByChainId = <int, List<ChainIssue>>{};
  final activeChainGroupNames = <String>[];
  final reservedNames = <String>{};

  for (final chain in chains) {
    if (!chain.enabled) {
      continue;
    }
    final chainIssues = validateSingleChain(
      chain,
      config,
      strictDns: strictDns,
      reservedNames: reservedNames,
    );
    issuesByChainId[chain.id] = chainIssues;
    allIssues.addAll(chainIssues);

    final hasError = chainIssues.any((i) => i.isError);
    if (hasError) {
      // Never inject invalid or empty chain groups, and never fall back to DIRECT.
      continue;
    }

    final entryMembers = List<String>.from(chain.entry.members);
    final exitMembers = List<String>.from(chain.exit.members);
    final isSingleEntry = entryMembers.length == 1;
    final dialerTarget = isSingleEntry
        ? entryMembers.first
        : chain.entryGroupName;

    if (!isSingleEntry) {
      final entryGroup = <String, dynamic>{
        'name': chain.entryGroupName,
        'type': chain.entry.type == ChainGroupType.urlTest
            ? ChainGroupType.urlTest.yamlValue
            : ChainGroupType.fallback.yamlValue,
        'hidden': true,
        'url': (chain.entry.testUrl?.trim().isNotEmpty == true)
            ? chain.entry.testUrl!.trim()
            : defaultTestUrl,
        'interval': chain.entry.interval > 0 ? chain.entry.interval : 300,
        if (chain.entry.type == ChainGroupType.urlTest)
          'tolerance': chain.entry.tolerance >= 0 ? chain.entry.tolerance : 50,
        'proxies': entryMembers,
      };
      groupsList.add(entryGroup);
      reservedNames.add(chain.entryGroupName);
    }

    final isSingleExitBlock =
        exitMembers.length == 1 &&
        chain.failurePolicy == ChainFailurePolicy.block;

    final exitCopyNames = <String>[];
    for (final member in exitMembers) {
      final original = staticProxies[member]!;
      final copy =
          jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
      final copyName = chain.exitCopyName(member);
      copy['name'] = copyName;
      copy['dialer-proxy'] = dialerTarget;
      proxiesList.add(copy);
      exitCopyNames.add(copyName);
      reservedNames.add(copyName);
    }

    if (!isSingleExitBlock) {
      final exitGroupMembers = <String>[
        ...exitCopyNames,
        if (chain.failurePolicy == ChainFailurePolicy.directFallback)
          ...exitMembers,
      ];
      final exitGroup = <String, dynamic>{
        'name': chain.groupName,
        'type': chain.exit.type == ChainGroupType.select
            ? ChainGroupType.select.yamlValue
            : ChainGroupType.fallback.yamlValue,
        if (chain.exit.type != ChainGroupType.select) ...{
          'url': (chain.exit.testUrl?.trim().isNotEmpty == true)
              ? chain.exit.testUrl!.trim()
              : defaultTestUrl,
          'interval': chain.exit.interval > 0 ? chain.exit.interval : 300,
        },
        'proxies': exitGroupMembers,
      };
      groupsList.add(exitGroup);
      reservedNames.add(chain.groupName);
    }

    activeChainGroupNames.add(chain.groupName);
  }

  String? matchSelectGroupName;
  if (activeChainGroupNames.isNotEmpty) {
    final existingGroupNames = groupsList
        .whereType<Map>()
        .map((g) => g['name'])
        .whereType<String>()
        .toSet();
    if (!existingGroupNames.contains(chainAggregateGroupName)) {
      groupsList.add(<String, dynamic>{
        'name': chainAggregateGroupName,
        'type': 'select',
        'proxies': List<String>.from(activeChainGroupNames),
      });
    }

    matchSelectGroupName = findMatchSelectGroupName(config);
    final generatedGroupNames = <String>{
      chainAggregateGroupName,
      ...activeChainGroupNames,
      for (final c in chains) c.entryGroupName,
    };

    // Inject active chains at the top of every proxy-selecting `select` group
    // (such as `🔰国外流量`, `🐟漏网之鱼`, `🤖OpenAI`, etc.) so users can pick any
    // chain directly in any selector group without being limited to MATCH.
    for (final item in groupsList) {
      if (item is! Map) continue;
      final groupName = item['name'];
      final groupType = (item['type'] as String?)?.toLowerCase();
      if (groupName is! String ||
          groupType != 'select' ||
          generatedGroupNames.contains(groupName)) {
        continue;
      }
      final rawMembers = item['proxies'] is List
          ? List<dynamic>.from(item['proxies'] as List)
          : <dynamic>[];
      final hasUse = item['use'] is List && (item['use'] as List).isNotEmpty;
      final hasIncludeAll =
          item['include-all'] == true ||
          item['include-all-proxies'] == true ||
          item['include-all-providers'] == true;
      final hasNonBuiltinMember = rawMembers.any(
        (m) => m is String && !isBuiltinPolicyName(m),
      );
      if (!hasNonBuiltinMember && !hasUse && !hasIncludeAll) {
        continue;
      }
      final toPrepend = <String>[
        for (final chainName in activeChainGroupNames)
          if (!rawMembers.contains(chainName)) chainName,
      ];
      if (toPrepend.isNotEmpty) {
        item['proxies'] = [...toPrepend, ...rawMembers];
      }
    }
  }

  config['proxies'] = proxiesList;
  config['proxy-groups'] = groupsList;

  return ProxyChainApplyResult(
    config: config,
    issues: allIssues,
    issuesByChainId: issuesByChainId,
    activeChainGroupNames: activeChainGroupNames,
    matchSelectGroupName: matchSelectGroupName,
  );
}

/// Resolves whether the currently active proxy or group selection corresponds
/// to a configured [ProxyChain] (matching either the chain group name or any
/// of its cloned exit node names).
ProxyChain? resolveActiveProxyChain(
  List<ProxyChain> chains, {
  required String? proxyName,
  String? groupNow,
  bool chainsEnabled = true,
}) {
  if (!chainsEnabled || chains.isEmpty) {
    return null;
  }
  final candidates = <String>{
    if (proxyName != null && proxyName.isNotEmpty) proxyName,
    if (groupNow != null && groupNow.isNotEmpty) groupNow,
  };
  if (candidates.isEmpty) {
    return null;
  }
  for (final chain in chains) {
    if (!chain.enabled) continue;
    if (candidates.contains(chain.groupName)) {
      return chain;
    }
    for (final member in chain.exit.members) {
      if (candidates.contains(chain.exitCopyName(member))) {
        return chain;
      }
    }
  }
  return null;
}

/// Generates a human-readable YAML preview snippet for a single [chain].
String generateChainYamlPreview(
  ProxyChain chain, {
  String defaultTestUrl = 'https://www.gstatic.com/generate_204',
}) {
  final entryMembers = chain.entry.members;
  final exitMembers = chain.exit.members;
  final isSingleEntry = entryMembers.length == 1;
  final isSingleExitBlock =
      exitMembers.length == 1 &&
      chain.failurePolicy == ChainFailurePolicy.block;
  final dialerTarget = isSingleEntry
      ? entryMembers.first
      : chain.entryGroupName;

  final buf = StringBuffer()
    ..writeln(
      '# ${chain.groupName} (${chain.failurePolicy == ChainFailurePolicy.block ? 'block' : 'direct-fallback'})',
    )
    ..writeln('proxies:');
  for (final member in exitMembers) {
    final copyName = chain.exitCopyName(member);
    buf
      ..writeln('  - name: "$copyName"')
      ..writeln('    # cloned from $member')
      ..writeln('    dialer-proxy: "$dialerTarget"');
  }

  if (!isSingleEntry || !isSingleExitBlock) {
    buf
      ..writeln()
      ..writeln('proxy-groups:');
  }
  if (!isSingleEntry && entryMembers.isNotEmpty) {
    buf
      ..writeln('  - name: "${chain.entryGroupName}"')
      ..writeln('    type: ${chain.entry.type.yamlValue}')
      ..writeln('    hidden: true')
      ..writeln('    url: ${chain.entry.testUrl ?? defaultTestUrl}')
      ..writeln('    interval: ${chain.entry.interval}');
    if (chain.entry.type == ChainGroupType.urlTest) {
      buf.writeln('    tolerance: ${chain.entry.tolerance}');
    }
    buf.writeln(
      '    proxies: [${entryMembers.map((m) => '"$m"').join(', ')}]',
    );
  }
  if (!isSingleExitBlock && exitMembers.isNotEmpty) {
    final members = <String>[
      for (final m in exitMembers) '"${chain.exitCopyName(m)}"',
      if (chain.failurePolicy == ChainFailurePolicy.directFallback)
        for (final m in exitMembers) '"$m"',
    ];
    buf
      ..writeln('  - name: "${chain.groupName}"')
      ..writeln('    type: ${chain.exit.type.yamlValue}')
      ..writeln('    proxies: [${members.join(', ')}]');
  }
  return buf.toString().trimRight();
}
