import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/controller.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/proxies/chains/chain_dialogs.dart';
import 'package:quanclash/views/proxies/chains/chain_issue_l10n.dart';
import 'package:quanclash/views/proxies/chains/chain_node_drawer.dart';
import 'package:quanclash/views/proxies/common.dart' as proxies_common;
import 'package:quanclash/views/proxies/grouping.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:quanclash/widgets/widgets.dart';

class _ChainDragPayload {
  const _ChainDragPayload({
    required this.nodeName,
    required this.from,
  });

  final String nodeName;
  final String from; // 'pool' | 'entry' | 'exit'
}

enum _NodePoolSort { delay, name }

class ProxyChainsPage extends ConsumerStatefulWidget {
  const ProxyChainsPage({
    super.key,
    this.initialRawConfig,
    this.initialProfileId,
  });

  /// Optional raw config map override (used in widget tests or when preloaded).
  final Map<String, dynamic>? initialRawConfig;

  /// Optional profile id override.
  final int? initialProfileId;

  @override
  ConsumerState<ProxyChainsPage> createState() => _ProxyChainsPageState();
}

class _ProxyChainsPageState extends ConsumerState<ProxyChainsPage> {
  Map<String, dynamic> _rawConfig = const {};
  bool _loadingConfig = true;
  int? _selectedChainId;
  final Map<int, ProxyChain> _drafts = {};
  String _selectedRegionId = 'all';
  _NodePoolSort _sort = _NodePoolSort.delay;
  bool _onlyUdp = false;
  String _searchQuery = '';
  String? _flashingTargetKey;
  Timer? _flashTimer;
  bool _applying = false;
  bool _testingDelay = false;

  int? get _profileId =>
      widget.initialProfileId ?? ref.read(currentProfileIdProvider);

  @override
  void initState() {
    super.initState();
    if (widget.initialRawConfig != null) {
      _rawConfig = widget.initialRawConfig!;
      _loadingConfig = false;
    } else {
      _loadRawConfig();
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRawConfig() async {
    final profileId = _profileId;
    if (profileId == null) {
      if (mounted) {
        setState(() {
          _rawConfig = const {};
          _loadingConfig = false;
        });
      }
      return;
    }
    try {
      final config = await coreController.getConfig(profileId);
      if (mounted) {
        setState(() {
          _rawConfig = config;
          _loadingConfig = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rawConfig = const {};
          _loadingConfig = false;
        });
      }
    }
  }

  bool _isStrictDns() {
    final network = ref.read(networkSettingProvider);
    return network.dnsSafetyMode == DnsSafetyMode.proxyOnly ||
        network.autoSetSystemDns;
  }

  ProxyChain? _getAppliedChain(List<ProxyChain> chains, int? id) {
    if (id == null) return null;
    for (final c in chains) {
      if (c.id == id) return c;
    }
    return null;
  }

  ProxyChain? _getWorkingChain(List<ProxyChain> chains, int? id) {
    if (id == null) return null;
    return _drafts[id] ?? _getAppliedChain(chains, id);
  }

  bool _isDirty(List<ProxyChain> chains, int? id) {
    if (id == null || !_drafts.containsKey(id)) return false;
    return _drafts[id] != _getAppliedChain(chains, id);
  }

  void _updateDraft(
    List<ProxyChain> chains,
    ProxyChain Function(ProxyChain current) updater,
  ) {
    final id = _selectedChainId;
    final current = _getWorkingChain(chains, id);
    if (id == null || current == null) return;
    setState(() {
      _drafts[id] = updater(current);
    });
  }

  Future<bool> _guardUnsaved(List<ProxyChain> chains) async {
    final id = _selectedChainId;
    if (!_isDirty(chains, id)) return true;
    final working = _getWorkingChain(chains, id);
    if (working == null) return true;
    final choice = await showChainUnsavedDialog(context, working.name);
    if (choice == 'discard') {
      setState(() {
        _drafts.remove(id);
      });
      return true;
    }
    if (choice == 'apply') {
      return _applyCurrentChain(chains);
    }
    return false;
  }

  Future<void> _selectChain(List<ProxyChain> chains, int id) async {
    if (id == _selectedChainId) return;
    if (!await _guardUnsaved(chains)) return;
    setState(() {
      _selectedChainId = id;
    });
  }

  Future<void> _createNewChain(List<ProxyChain> chains) async {
    final profileId = _profileId;
    if (profileId == null) return;
    if (!await _guardUnsaved(chains) || !mounted) return;
    final l10n = context.appLocalizations;
    final baseName = l10n.proxyChainNew;
    var candidate = '$baseName ${chains.length + 1}';
    final existing = chains.map((c) => c.name).toSet();
    var seq = chains.length + 1;
    while (existing.contains(candidate)) {
      seq++;
      candidate = '$baseName $seq';
    }
    final created = ProxyChain.create(
      profileId: profileId,
      name: candidate,
      order: chains.length,
    );
    await ref.read(profileProxyChainsProvider(profileId).notifier).put(created);
    if (mounted) {
      setState(() {
        _selectedChainId = created.id;
      });
    }
  }

  Future<void> _setChainAsCurrentProxy(
    List<ProxyChain> chains,
    ProxyChain chain,
  ) async {
    if (_isDirty(chains, chain.id)) {
      final ok = await _applyCurrentChain(chains);
      if (!ok) return;
    }
    final mode = ref.read(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final groups = ref.read(groupsProvider);
    final selectedMap = ref.read(selectedMapProvider);
    final preferredGroup = ref.read(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );

    final targetGroup = mode == Mode.global
        ? groups.getGroup(GroupName.GLOBAL.name)
        : computeCurrentGroup(
            groups,
            preferredName: preferredGroup == chainAggregateGroupName
                ? null
                : preferredGroup,
            selectedMap: selectedMap,
            mode: mode,
          );

    // Always update the aggregate `链式代理` group selection as well.
    if (groups.getGroup(chainAggregateGroupName) != null) {
      ref
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(chainAggregateGroupName, chain.groupName);
      ref
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(chainAggregateGroupName, chain.groupName);
    }

    if (targetGroup != null &&
        targetGroup.type == GroupType.Selector &&
        targetGroup.name != chainAggregateGroupName) {
      final hasDirectChain = targetGroup.all.any(
        (p) => p.name == chain.groupName,
      );
      final targetSelection = hasDirectChain
          ? chain.groupName
          : chainAggregateGroupName;
      ref
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(targetGroup.name, targetSelection);
      ref
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(targetGroup.name, targetSelection);
      if (mounted) {
        globalState.showNotifier(
          '${targetGroup.name} → ${chain.groupName}',
        );
      }
    } else if (mounted) {
      globalState.showNotifier(
        context.appLocalizations.proxyChainApplied(chain.groupName),
      );
    }
  }

  Future<bool> _applyCurrentChain(List<ProxyChain> chains) async {
    final profileId = _profileId;
    final id = _selectedChainId;
    final working = _getWorkingChain(chains, id);
    if (profileId == null || id == null || working == null) return false;

    final issues = validateSingleChain(
      working,
      _rawConfig,
      strictDns: _isStrictDns(),
    );
    final errors = issues.where((i) => i.isError).toList();
    if (errors.isNotEmpty) {
      _triggerFlash(_issueTargetKey(errors.first));
      globalState.showNotifier(
        formatChainIssue(context.appLocalizations, errors.first),
      );
      return false;
    }

    setState(() {
      _applying = true;
    });
    try {
      await ref
          .read(profileProxyChainsProvider(profileId).notifier)
          .put(working);
      _drafts.remove(id);
      if (widget.initialRawConfig == null) {
        await ref
            .read(setupActionProvider.notifier)
            .applyProfile(force: true, silence: true);
      }
      if (mounted) {
        globalState.showNotifier(
          context.appLocalizations.proxyChainApplied(working.groupName),
        );
      }
      return true;
    } finally {
      if (mounted) {
        setState(() {
          _applying = false;
        });
      }
    }
  }

  Future<void> _deleteChain(List<ProxyChain> chains, ProxyChain chain) async {
    final profileId = _profileId;
    if (profileId == null) return;
    final refs = findChainRuleReferences(_rawConfig, chain.groupName);
    final confirmed = await showChainDeleteConfirmDialog(
      context,
      chain.name,
      refs.length,
    );
    if (!confirmed) return;

    await ref
        .read(profileProxyChainsProvider(profileId).notifier)
        .deleteChain(chain.id);
    _drafts.remove(chain.id);
    if (_selectedChainId == chain.id) {
      final remaining = chains.where((c) => c.id != chain.id).toList();
      _selectedChainId = remaining.isNotEmpty ? remaining.first.id : null;
    }
    if (widget.initialRawConfig == null) {
      await ref
          .read(setupActionProvider.notifier)
          .applyProfile(force: true, silence: true);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleProfileChains(
    Profile profile,
    List<ProxyChain> chains,
  ) async {
    final nextEnabled = !profile.chainsEnabled;
    if (!nextEnabled) {
      var refCount = 0;
      for (final c in chains) {
        refCount += findChainRuleReferences(_rawConfig, c.groupName).length;
      }
      if (refCount > 0) {
        final l10n = context.appLocalizations;
        final quanX = context.quanX;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => CommonDialog(
            title: l10n.proxyChainDisabledTitle,
            backgroundColor: quanX.surface,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: quanX.danger),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
            child: Text(
              l10n.proxyChainRuleRefWarning(refCount),
              style: TextStyle(color: quanX.danger),
            ),
          ),
        );
        if (confirmed != true) return;
      }
    }
    ref
        .read(profilesProvider.notifier)
        .updateProfile(
          profile.id,
          (p) => p.copyWith(chainsEnabled: nextEnabled),
        );
    if (widget.initialRawConfig == null) {
      await ref
          .read(setupActionProvider.notifier)
          .applyProfile(force: true, silence: true);
    }
  }

  void _addNodeToSide(
    List<ProxyChain> chains,
    String nodeName,
    String side, {
    String from = 'pool',
  }) {
    final current = _getWorkingChain(chains, _selectedChainId);
    if (current == null) return;
    final other = side == 'entry' ? 'exit' : 'entry';
    final otherMembers = other == 'entry'
        ? current.entry.members
        : current.exit.members;
    if (from == 'pool' && otherMembers.contains(nodeName)) {
      globalState.showNotifier(
        context.appLocalizations.proxyChainErrBothSides(nodeName),
      );
      return;
    }
    _updateDraft(chains, (c) {
      final entryList = List<String>.from(c.entry.members);
      final exitList = List<String>.from(c.exit.members);
      if (from == 'entry' && side == 'exit') {
        entryList.remove(nodeName);
      } else if (from == 'exit' && side == 'entry') {
        exitList.remove(nodeName);
      }
      if (side == 'entry' && !entryList.contains(nodeName)) {
        entryList.add(nodeName);
      } else if (side == 'exit' && !exitList.contains(nodeName)) {
        exitList.add(nodeName);
      }
      return c.copyWith(
        entry: c.entry.copyWith(members: entryList),
        exit: c.exit.copyWith(members: exitList),
      );
    });
  }

  void _removeNodeFromSide(
    List<ProxyChain> chains,
    String side,
    String nodeName,
  ) {
    _updateDraft(chains, (c) {
      if (side == 'entry') {
        return c.copyWith(
          entry: c.entry.copyWith(
            members: c.entry.members.where((m) => m != nodeName).toList(),
          ),
        );
      }
      return c.copyWith(
        exit: c.exit.copyWith(
          members: c.exit.members.where((m) => m != nodeName).toList(),
        ),
      );
    });
  }

  void _moveNodeOrder(
    List<ProxyChain> chains,
    String side,
    int oldIndex,
    int newIndex,
  ) {
    _updateDraft(chains, (c) {
      final list = List<String>.from(
        side == 'entry' ? c.entry.members : c.exit.members,
      );
      if (oldIndex < 0 ||
          oldIndex >= list.length ||
          newIndex < 0 ||
          newIndex >= list.length) {
        return c;
      }
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      return side == 'entry'
          ? c.copyWith(entry: c.entry.copyWith(members: list))
          : c.copyWith(exit: c.exit.copyWith(members: list));
    });
  }

  String _issueTargetKey(ChainIssue issue) {
    if (issue.nodeName != null &&
        (issue.targetSide == ChainTargetSide.entry ||
            issue.targetSide == ChainTargetSide.exit)) {
      final side = issue.targetSide == ChainTargetSide.entry ? 'entry' : 'exit';
      return 'card-$side-${issue.nodeName}';
    }
    if (issue.targetSide == ChainTargetSide.entry) return 'box-entry';
    if (issue.targetSide == ChainTargetSide.exit) return 'box-exit';
    return 'connector';
  }

  void _triggerFlash(String key) {
    _flashTimer?.cancel();
    setState(() {
      _flashingTargetKey = key;
    });
    _flashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _flashingTargetKey = null;
        });
      }
    });
  }

  Set<String> _allGeneratedChainNames(List<ProxyChain> chains) {
    final names = <String>{chainAggregateGroupName};
    for (final c in chains) {
      names.add(c.groupName);
      names.add(c.entryGroupName);
      for (final m in c.exit.members) {
        names.add(c.exitCopyName(m));
      }
    }
    return names;
  }

  List<_PoolNodeItem> _buildPoolNodes(
    Map<String, Map<String, dynamic>> staticProxies,
    List<Group> liveGroups,
    List<ProxyChain> chains,
  ) {
    final items = <_PoolNodeItem>[];
    final seen = <String>{};
    final generated = _allGeneratedChainNames(chains);

    for (final entry in staticProxies.entries) {
      final name = entry.key;
      if (isBuiltinPolicyName(name) || generated.contains(name)) {
        continue;
      }
      final map = entry.value;
      final type = (map['type'] as String?) ?? 'unknown';
      final dialer = map['dialer-proxy'] is String
          ? (map['dialer-proxy'] as String).trim()
          : null;
      final region = regionOfProxyName(name);
      items.add(
        _PoolNodeItem(
          name: name,
          protocol: type,
          isProvider: false,
          server: map['server'] as String?,
          port: map['port'] is int ? map['port'] as int : null,
          supportsUdp: nodeSupportsUdp(map),
          isQuic: isQuicProtocol(type),
          existingDialer: (dialer?.isNotEmpty == true) ? dialer : null,
          regionId: region?.id ?? 'other',
          regionLabel: region?.label,
        ),
      );
      seen.add(name);
    }

    for (final group in liveGroups) {
      for (final proxy in group.all) {
        final name = proxy.name;
        if (seen.contains(name) ||
            isBuiltinPolicyName(name) ||
            generated.contains(name) ||
            GroupTypeExtension.valueList.contains(proxy.type)) {
          continue;
        }
        final region = regionOfProxyName(name);
        items.add(
          _PoolNodeItem(
            name: name,
            protocol: proxy.type,
            isProvider: true,
            supportsUdp: true,
            isQuic: isQuicProtocol(proxy.type),
            regionId: region?.id ?? 'other',
            regionLabel: region?.label,
          ),
        );
        seen.add(name);
      }
    }

    return items;
  }

  int? _lookupDelay(String proxyName) {
    final delayMap = ref.watch(delayDataSourceProvider);
    for (final urlMap in delayMap.values) {
      final val = urlMap[proxyName];
      if (val != null && val > 0) return val;
    }
    return null;
  }

  Future<void> _runPoolDelayTest(List<_PoolNodeItem> items) async {
    if (_testingDelay || items.isEmpty) return;
    setState(() {
      _testingDelay = true;
    });
    try {
      final proxies = items
          .where((item) => !item.isProvider)
          .map((item) => Proxy(name: item.name, type: item.protocol))
          .toList();
      await proxies_common.delayTest(proxies);
    } finally {
      if (mounted) {
        setState(() {
          _testingDelay = false;
        });
      }
    }
  }

  void _openQualityCheck(ProxyChain? applied, ProxyChain? working) {
    final chain = applied ?? working;
    final target = chain == null || chain.exit.members.isEmpty
        ? null
        : applied != null
        ? applied.exitCopyName(applied.exit.members.first)
        : chain.exit.members.first;
    if (target == null || target.isEmpty) {
      globalState.showNotifier(context.appLocalizations.nodeQualityPickNode);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(proxyName: target),
    );
  }

  List<String> _nodeOccupancies(List<ProxyChain> chains, String nodeName) {
    final l10n = context.appLocalizations;
    final list = <String>[];
    for (final c in chains) {
      final w = _getWorkingChain(chains, c.id) ?? c;
      if (w.entry.members.contains(nodeName)) {
        list.add('${w.name} · ${l10n.proxyChainEntry}');
      }
      if (w.exit.members.contains(nodeName)) {
        list.add('${w.name} · ${l10n.proxyChainExit}');
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final profileId = _profileId;
    final profile = profileId == null
        ? null
        : ref.watch(profileProvider(profileId));
    final chains = profileId == null
        ? const <ProxyChain>[]
        : ref.watch(profileProxyChainsProvider(profileId));
    final liveGroups = ref.watch(groupsProvider);
    final chainsEnabled = profile?.chainsEnabled ?? true;
    final quanX = context.quanX;
    final l10n = context.appLocalizations;

    if (_selectedChainId == null && chains.isNotEmpty) {
      _selectedChainId = chains.first.id;
    } else if (_selectedChainId != null &&
        chains.every((c) => c.id != _selectedChainId)) {
      _selectedChainId = chains.isNotEmpty ? chains.first.id : null;
    }

    final working = _getWorkingChain(chains, _selectedChainId);
    final applied = _getAppliedChain(chains, _selectedChainId);
    final dirty = _isDirty(chains, _selectedChainId);
    final staticProxies = extractStaticProxies(_rawConfig);
    final issues = working == null
        ? const <ChainIssue>[]
        : validateSingleChain(
            working,
            _rawConfig,
            strictDns: _isStrictDns(),
          );
    final poolNodes = _buildPoolNodes(staticProxies, liveGroups, chains);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          if (working != null && chainsEnabled) {
            _applyCurrentChain(chains);
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () async {
          if (await _guardUnsaved(chains) && context.mounted) {
            Navigator.of(context).maybePop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: quanX.background,
          body: Row(
            children: [
              _buildLeftSidebar(
                context,
                profile: profile,
                chains: chains,
                chainsEnabled: chainsEnabled,
              ),
              Expanded(
                child: Column(
                  children: [
                    // Top toolbar stays ABOVE disabled overlay so Back is always clickable.
                    _buildTopToolbar(
                      context,
                      chains: chains,
                      working: working,
                      applied: applied,
                      dirty: dirty,
                      chainsEnabled: chainsEnabled,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              if (working != null && issues.isNotEmpty)
                                _buildIssuesBanner(context, issues),
                              Expanded(
                                child: _loadingConfig
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : working == null
                                    ? _buildEmptyState(context, chains)
                                    : Column(
                                        children: [
                                          SizedBox(
                                            height: 256,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    18,
                                                    14,
                                                    18,
                                                    10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: _buildHopBox(
                                                      context,
                                                      chains: chains,
                                                      working: working,
                                                      side: 'entry',
                                                      staticProxies:
                                                          staticProxies,
                                                      issues: issues,
                                                    ),
                                                  ),
                                                  _buildConnector(
                                                    context,
                                                    working: working,
                                                    hasErrors: issues.any(
                                                      (i) => i.isError,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: _buildHopBox(
                                                      context,
                                                      chains: chains,
                                                      working: working,
                                                      side: 'exit',
                                                      staticProxies:
                                                          staticProxies,
                                                      issues: issues,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildNodePool(
                                              context,
                                              chains: chains,
                                              working: working,
                                              applied: applied,
                                              poolNodes: poolNodes,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                          if (!chainsEnabled && profile != null)
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.42),
                                child: Center(
                                  child: Container(
                                    width: 340,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: quanX.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: quanX.separator,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        MobiusIcon(
                                          size: 32,
                                          color: quanX.accent,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.proxyChainDisabledTitle,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: quanX.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          l10n.proxyChainDisabledDesc,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: quanX.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).maybePop(),
                                              child: Text(l10n.proxies),
                                            ),
                                            const SizedBox(width: 10),
                                            FilledButton(
                                              onPressed: () =>
                                                  _toggleProfileChains(
                                                    profile,
                                                    chains,
                                                  ),
                                              child: Text(
                                                l10n.proxyChainReenable,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar(
    BuildContext context, {
    required Profile? profile,
    required List<ProxyChain> chains,
    required bool chainsEnabled,
  }) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;
    return Container(
      width: 224,
      decoration: BoxDecoration(
        color: quanX.surface,
        border: Border(right: BorderSide(color: quanX.separator)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: quanX.separator)),
            ),
            child: Row(
              children: [
                MobiusIcon(size: 18, color: quanX.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.proxyChains,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: quanX.textPrimary,
                        ),
                      ),
                      if (profile != null && profile.label.isNotEmpty)
                        Text(
                          profile.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: quanX.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (profile != null)
                  Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: chainsEnabled,
                      onChanged: (_) => _toggleProfileChains(profile, chains),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: quanX.separator),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(QuanXIcons.plus, size: 14),
                label: Text(
                  l10n.proxyChainNew,
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: chainsEnabled ? () => _createNewChain(chains) : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: chains.length,
              separatorBuilder: (_, _) => const SizedBox(height: 3),
              itemBuilder: (context, index) {
                final c = chains[index];
                final w = _getWorkingChain(chains, c.id) ?? c;
                final selected = c.id == _selectedChainId;
                final dirty = _isDirty(chains, c.id);
                final cIssues = validateSingleChain(
                  w,
                  _rawConfig,
                  strictDns: _isStrictDns(),
                );
                final cErrors = cIssues.where((i) => i.isError).toList();
                final dotColor = cErrors.isNotEmpty
                    ? quanX.danger
                    : quanX.success;

                return Material(
                  color: selected
                      ? quanX.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _selectChain(chains, c.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              MobiusIcon(
                                size: 13,
                                color: selected
                                    ? quanX.accent
                                    : quanX.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  w.groupName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: quanX.textPrimary,
                                  ),
                                ),
                              ),
                              if (dirty)
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: quanX.warning,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              cErrors.isNotEmpty
                                  ? formatChainIssue(l10n, cErrors.first)
                                  : '${w.entry.members.length} ${l10n.proxyChainEntry} → ${w.exit.members.length} ${l10n.proxyChainExit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: cErrors.isNotEmpty
                                    ? quanX.danger
                                    : quanX.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToolbar(
    BuildContext context, {
    required List<ProxyChain> chains,
    required ProxyChain? working,
    required ProxyChain? applied,
    required bool dirty,
    required bool chainsEnabled,
  }) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;

    final fullDelay = applied == null || applied.exit.members.isEmpty
        ? null
        : _lookupDelay(applied.exitCopyName(applied.exit.members.first));

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: quanX.surface,
        border: Border(bottom: BorderSide(color: quanX.separator)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            onPressed: () async {
              if (await _guardUnsaved(chains) && context.mounted) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          const SizedBox(width: 4),
          if (working != null) ...[
            MobiusIcon(size: 16, color: quanX.accent),
            const SizedBox(width: 6),
            GestureDetector(
              onDoubleTap: () async {
                final renamed = await showChainRenameDialog(
                  context,
                  working.name,
                );
                if (renamed != null) {
                  _updateDraft(chains, (c) => c.copyWith(name: renamed));
                }
              },
              child: Text(
                working.groupName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: quanX.textPrimary,
                ),
              ),
            ),
            if (dirty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: quanX.warning.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.proxyChainUnapplied,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: quanX.warning,
                  ),
                ),
              ),
            ],
            if (working.failurePolicy == ChainFailurePolicy.directFallback) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openFailurePolicy(chains, working),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: quanX.danger.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⚠ ${l10n.proxyChainFailureDirectBadge}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: quanX.danger,
                    ),
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          if (applied != null &&
              applied.entry.members.isNotEmpty &&
              applied.exit.members.isNotEmpty) ...[
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: quanX.surfaceElevated,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: quanX.separator),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: quanX.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${applied.entry.members.first} ▸ ${applied.exit.members.first}',
                    style: TextStyle(fontSize: 11, color: quanX.textSecondary),
                  ),
                  if (fullDelay != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '${fullDelay}ms',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: quanX.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (dirty && working != null) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _drafts.remove(working.id);
                });
              },
              child: Text(l10n.proxyChainDiscard),
            ),
            const SizedBox(width: 4),
          ],
          if (working != null) ...[
            SizedBox(
              height: 32,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: quanX.separator),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (!chainsEnabled || _applying)
                    ? null
                    : () => _setChainAsCurrentProxy(chains, working),
                child: Text(
                  l10n.proxyChainSetCurrent,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: (!chainsEnabled || _applying)
                    ? null
                    : () => _applyCurrentChain(chains),
                child: _applying
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.proxyChainApply),
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              color: quanX.surface,
              icon: Icon(
                QuanXIcons.ellipsisVertical,
                size: 16,
                color: quanX.textSecondary,
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'rename':
                    final renamed = await showChainRenameDialog(
                      context,
                      working.name,
                    );
                    if (renamed != null) {
                      _updateDraft(chains, (c) => c.copyWith(name: renamed));
                    }
                  case 'yaml':
                    await showChainYamlDialog(context, working);
                  case 'policy':
                    await _openFailurePolicy(chains, working);
                  case 'delete':
                    await _deleteChain(chains, working);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(l10n.proxyChainRename),
                ),
                PopupMenuItem(
                  value: 'yaml',
                  child: Text(l10n.proxyChainYamlPreview),
                ),
                PopupMenuItem(
                  value: 'policy',
                  child: Text(l10n.proxyChainFailurePolicy),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    l10n.proxyChainDelete,
                    style: TextStyle(color: quanX.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFailurePolicy(
    List<ProxyChain> chains,
    ProxyChain working,
  ) async {
    final next = await showChainFailurePolicyDialog(
      context,
      working.failurePolicy,
    );
    if (next != null && next != working.failurePolicy) {
      _updateDraft(chains, (c) => c.copyWith(failurePolicy: next));
    }
  }

  Widget _buildIssuesBanner(BuildContext context, List<ChainIssue> issues) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;
    final first = issues.first;
    final color = first.isError ? quanX.danger : quanX.warning;
    final key = _issueTargetKey(first);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: quanX.separator)),
      ),
      child: Row(
        children: [
          Icon(
            first.isError ? QuanXIcons.circleAlert : QuanXIcons.triangleAlert,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatChainIssue(l10n, first),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
          if (issues.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '(${issues.length})',
                style: TextStyle(fontSize: 11, color: quanX.textTertiary),
              ),
            ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () => _triggerFlash(key),
            child: Text(
              l10n.proxyChainLocate,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, List<ProxyChain> chains) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: quanX.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: MobiusIcon(size: 28, color: quanX.accent)),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.proxyChainEmptyTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: quanX.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 360,
            child: Text(
              l10n.proxyChainEmptyDesc,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: quanX.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(QuanXIcons.plus, size: 15),
            label: Text(l10n.proxyChainNew),
            onPressed: () => _createNewChain(chains),
          ),
        ],
      ),
    );
  }

  Widget _buildHopBox(
    BuildContext context, {
    required List<ProxyChain> chains,
    required ProxyChain working,
    required String side,
    required Map<String, Map<String, dynamic>> staticProxies,
    required List<ChainIssue> issues,
  }) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;
    final isEntry = side == 'entry';
    final hop = isEntry ? working.entry : working.exit;
    final boxKey = 'box-$side';
    final isFlashing = _flashingTargetKey == boxKey;
    final hasEmptyError = issues.any(
      (i) =>
          i.isError &&
          i.code ==
              (isEntry ? ChainIssueCode.entryEmpty : ChainIssueCode.exitEmpty),
    );

    final allowedTypes = isEntry
        ? const [ChainGroupType.fallback, ChainGroupType.urlTest]
        : const [ChainGroupType.fallback, ChainGroupType.select];

    return DragTarget<_ChainDragPayload>(
      onWillAcceptWithDetails: (details) {
        final payload = details.data;
        if (payload.from == side) return false;
        final otherMembers = isEntry
            ? working.exit.members
            : working.entry.members;
        if (payload.from == 'pool' && otherMembers.contains(payload.nodeName)) {
          return false;
        }
        return !hop.members.contains(payload.nodeName);
      },
      onAcceptWithDetails: (details) {
        _addNodeToSide(
          chains,
          details.data.nodeName,
          side,
          from: details.data.from,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isAccepting = candidateData.isNotEmpty;
        final isRejecting = rejectedData.isNotEmpty;

        Color borderColor = quanX.separator;
        Color bgColor = quanX.surfaceElevated;
        if (isRejecting || hasEmptyError || isFlashing) {
          borderColor = quanX.danger;
          bgColor = quanX.danger.withValues(alpha: 0.08);
        } else if (isAccepting) {
          borderColor = quanX.accent;
          bgColor = quanX.accent.withValues(alpha: 0.08);
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: (isAccepting || isRejecting || isFlashing) ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Text(
                        isEntry ? l10n.proxyChainEntry : l10n.proxyChainExit,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: quanX.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hop.members.length == 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: quanX.surfaceSunken,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.proxyChainSingleNode,
                            style: TextStyle(
                              fontSize: 10,
                              color: quanX.textTertiary,
                            ),
                          ),
                        )
                      else
                        Text(
                          '${hop.members.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: quanX.textTertiary,
                          ),
                        ),
                      const Spacer(),
                      if (isEntry &&
                          hop.type == ChainGroupType.urlTest &&
                          hop.members.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () async {
                              final params = await showChainUrlTestParamsDialog(
                                context,
                                hop,
                              );
                              if (params != null) {
                                _updateDraft(
                                  chains,
                                  (c) => c.copyWith(
                                    entry: c.entry.copyWith(
                                      tolerance: params.$1,
                                      interval: params.$2,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              child: Text(
                                '±${hop.tolerance}ms',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: quanX.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: quanX.surfaceSunken,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final type in allowedTypes)
                              InkWell(
                                borderRadius: BorderRadius.circular(6),
                                onTap: () {
                                  _updateDraft(chains, (c) {
                                    return isEntry
                                        ? c.copyWith(
                                            entry: c.entry.copyWith(type: type),
                                          )
                                        : c.copyWith(
                                            exit: c.exit.copyWith(type: type),
                                          );
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hop.type == type
                                        ? quanX.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    type.yamlValue,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: hop.type == type
                                          ? quanX.accent
                                          : quanX.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: hop.members.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: quanX.separator,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEntry
                                    ? l10n.proxyChainEntryDropHint
                                    : l10n.proxyChainExitDropHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: quanX.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEntry
                                    ? l10n.proxyChainEntryDropSub
                                    : l10n.proxyChainExitDropSub,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: quanX.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 205,
                              mainAxisExtent: 60,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: hop.members.length,
                        itemBuilder: (context, idx) {
                          final name = hop.members[idx];
                          final map = staticProxies[name];
                          final missing = map == null;
                          final cardKey = 'card-$side-$name';
                          final cardFlashing = _flashingTargetKey == cardKey;
                          final cardErr = issues.any(
                            (i) => i.isError && _issueTargetKey(i) == cardKey,
                          );
                          final cardWarn = issues.any(
                            (i) => i.isWarning && _issueTargetKey(i) == cardKey,
                          );
                          final delay = _lookupDelay(
                            isEntry ? name : working.exitCopyName(name),
                          );
                          return _HopNodeCard(
                            name: name,
                            index: idx,
                            total: hop.members.length,
                            side: side,
                            protocol: (map?['type'] as String?) ?? '?',
                            isQuic: map != null &&
                                isQuicProtocol(map['type'] as String?),
                            missing: missing,
                            hasError: cardErr || cardFlashing,
                            hasWarning: cardWarn,
                            delay: delay,
                            onTap: () {
                              showChainNodeDrawer(
                                context,
                                ChainNodeInfo(
                                  name: name,
                                  protocol: (map?['type'] as String?) ?? '?',
                                  isProvider: false,
                                  server: map?['server'] as String?,
                                  port: map?['port'] is int
                                      ? map!['port'] as int
                                      : null,
                                  supportsUdp:
                                      map != null && nodeSupportsUdp(map),
                                  isQuic: map != null &&
                                      isQuicProtocol(map['type'] as String?),
                                  delay: _lookupDelay(name),
                                  fullChainDelay: isEntry ? null : delay,
                                  qualityProxyName: isEntry
                                      ? name
                                      : working.exitCopyName(name),
                                  occupancies: _nodeOccupancies(chains, name),
                                ),
                              );
                            },
                            onRemove: () =>
                                _removeNodeFromSide(chains, side, name),
                            onMoveUp: idx > 0
                                ? () => _moveNodeOrder(
                                    chains,
                                    side,
                                    idx,
                                    idx - 1,
                                  )
                                : null,
                            onMoveDown: idx < hop.members.length - 1
                                ? () => _moveNodeOrder(
                                    chains,
                                    side,
                                    idx,
                                    idx + 1,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnector(
    BuildContext context, {
    required ProxyChain working,
    required bool hasErrors,
  }) {
    final quanX = context.quanX;
    final color = hasErrors ? quanX.danger : quanX.accent;
    return SizedBox(
      width: 60,
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showChainYamlDialog(context, working),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_forward_rounded, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  'YAML',
                  style: TextStyle(fontSize: 10, color: quanX.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodePool(
    BuildContext context, {
    required List<ProxyChain> chains,
    required ProxyChain working,
    required ProxyChain? applied,
    required List<_PoolNodeItem> poolNodes,
  }) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;

    // Build dynamic region filter chips from actual pool nodes.
    final regionMap = <String, String>{};
    for (final item in poolNodes) {
      if (item.regionId != 'other' && item.regionLabel != null) {
        regionMap.putIfAbsent(item.regionId, () => item.regionLabel!);
      }
    }
    final hasOther = poolNodes.any((item) => item.regionId == 'other');
    if (_selectedRegionId != 'all' &&
        _selectedRegionId != 'other' &&
        !regionMap.containsKey(_selectedRegionId)) {
      _selectedRegionId = 'all';
    }

    final filtered = poolNodes.where((item) {
      if (_selectedRegionId != 'all' && item.regionId != _selectedRegionId) {
        return false;
      }
      if (_onlyUdp && !item.supportsUdp) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.protocol.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sort == _NodePoolSort.delay) {
        final da = _lookupDelay(a.name) ?? 999999;
        final db = _lookupDelay(b.name) ?? 999999;
        if (da != db) return da.compareTo(db);
      }
      return a.name.compareTo(b.name);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      child: Column(
        children: [
          Row(
            children: [
              // Region classification chips (horizontally scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SourceChip(
                        label: l10n.proxyChainAll,
                        selected: _selectedRegionId == 'all',
                        onTap: () =>
                            setState(() => _selectedRegionId = 'all'),
                      ),
                      for (final entry in regionMap.entries) ...[
                        const SizedBox(width: 4),
                        _SourceChip(
                          label: entry.value,
                          selected: _selectedRegionId == entry.key,
                          onTap: () =>
                              setState(() => _selectedRegionId = entry.key),
                        ),
                      ],
                      if (hasOther) ...[
                        const SizedBox(width: 4),
                        _SourceChip(
                          label: l10n.proxiesOtherRegion,
                          selected: _selectedRegionId == 'other',
                          onTap: () =>
                              setState(() => _selectedRegionId = 'other'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Delay test button
              SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(color: quanX.separator),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: _testingDelay
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.8),
                        )
                      : Icon(QuanXIcons.zap, size: 13, color: quanX.accent),
                  label: Text(
                    l10n.delay,
                    style: TextStyle(fontSize: 11, color: quanX.textPrimary),
                  ),
                  onPressed: _testingDelay
                      ? null
                      : () => _runPoolDelayTest(filtered),
                ),
              ),
              const SizedBox(width: 6),
              // Node quality (purity) test button
              SizedBox(
                height: 28,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    side: BorderSide(color: quanX.separator),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(QuanXIcons.shield, size: 13, color: quanX.success),
                  label: Text(
                    l10n.nodeQualityTitle,
                    style: TextStyle(fontSize: 11, color: quanX.textPrimary),
                  ),
                  onPressed: () => _openQualityCheck(applied, working),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                height: 28,
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: l10n.search,
                    prefixIcon: const Icon(QuanXIcons.search, size: 13),
                    prefixIconConstraints: const BoxConstraints(minWidth: 28),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: quanX.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: quanX.separator),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: quanX.separator),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _SourceChip(
                label: l10n.proxyChainOnlyUdp,
                selected: _onlyUdp,
                onTap: () => setState(() => _onlyUdp = !_onlyUdp),
              ),
              const SizedBox(width: 6),
              // Segmented sort toggle (replaces broken transparent DropdownButton)
              Container(
                height: 28,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: quanX.surfaceSunken,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SortSegment(
                      label: l10n.delay,
                      selected: _sort == _NodePoolSort.delay,
                      onTap: () => setState(() => _sort = _NodePoolSort.delay),
                    ),
                    _SortSegment(
                      label: l10n.name,
                      selected: _sort == _NodePoolSort.name,
                      onTap: () => setState(() => _sort = _NodePoolSort.name),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 215,
                mainAxisExtent: 62,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final delay = _lookupDelay(item.name);
                final role = working.entry.members.contains(item.name)
                    ? l10n.proxyChainEntry
                    : working.exit.members.contains(item.name)
                    ? l10n.proxyChainExit
                    : null;

                return _PoolNodeCard(
                  item: item,
                  delay: delay,
                  roleInCurrent: role,
                  onTap: () {
                    showChainNodeDrawer(
                      context,
                      ChainNodeInfo(
                        name: item.name,
                        protocol: item.protocol,
                        isProvider: item.isProvider,
                        server: item.server,
                        port: item.port,
                        supportsUdp: item.supportsUdp,
                        isQuic: item.isQuic,
                        existingDialer: item.existingDialer,
                        delay: delay,
                        occupancies: _nodeOccupancies(chains, item.name),
                      ),
                    );
                  },
                  onAddEntry: item.isProvider
                      ? null
                      : () => _addNodeToSide(chains, item.name, 'entry'),
                  onAddExit: item.isProvider
                      ? null
                      : () => _addNodeToSide(chains, item.name, 'exit'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortSegment extends StatelessWidget {
  const _SortSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected ? quanX.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? quanX.accent : quanX.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PoolNodeItem {
  const _PoolNodeItem({
    required this.name,
    required this.protocol,
    required this.isProvider,
    required this.regionId,
    this.regionLabel,
    this.server,
    this.port,
    this.supportsUdp = false,
    this.isQuic = false,
    this.existingDialer,
  });

  final String name;
  final String protocol;
  final bool isProvider;
  final String regionId;
  final String? regionLabel;
  final String? server;
  final int? port;
  final bool supportsUdp;
  final bool isQuic;
  final String? existingDialer;
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? quanX.accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? quanX.accent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? quanX.accent : quanX.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HopNodeCard extends StatefulWidget {
  const _HopNodeCard({
    required this.name,
    required this.index,
    required this.total,
    required this.side,
    required this.protocol,
    required this.isQuic,
    required this.missing,
    required this.hasError,
    required this.hasWarning,
    required this.delay,
    required this.onTap,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String name;
  final int index;
  final int total;
  final String side;
  final String protocol;
  final bool isQuic;
  final bool missing;
  final bool hasError;
  final bool hasWarning;
  final int? delay;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_HopNodeCard> createState() => _HopNodeCardState();
}

class _HopNodeCardState extends State<_HopNodeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final borderColor = widget.hasError
        ? quanX.danger
        : widget.hasWarning
        ? quanX.warning
        : _hover
        ? quanX.textTertiary
        : quanX.separator;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.name,
        waitDuration: const Duration(milliseconds: 500),
        child: Material(
          color: quanX.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: widget.hasError ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: quanX.surfaceSunken,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: quanX.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: widget.missing
                                ? TextDecoration.lineThrough
                                : null,
                            color: widget.missing
                                ? quanX.danger
                                : quanX.textPrimary,
                          ),
                        ),
                      ),
                      if (_hover) ...[
                        if (widget.onMoveUp != null)
                          InkWell(
                            onTap: widget.onMoveUp,
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 13,
                              color: quanX.textTertiary,
                            ),
                          ),
                        if (widget.onMoveDown != null)
                          InkWell(
                            onTap: widget.onMoveDown,
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              size: 13,
                              color: quanX.textTertiary,
                            ),
                          ),
                        const SizedBox(width: 2),
                        InkWell(
                          onTap: widget.onRemove,
                          child: Icon(
                            QuanXIcons.x,
                            size: 13,
                            color: quanX.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 22),
                      Expanded(
                        child: Text(
                          widget.missing
                              ? 'MISSING'
                              : '${widget.protocol.toUpperCase()}${widget.isQuic ? ' · QUIC' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.missing
                                ? quanX.danger
                                : quanX.textTertiary,
                          ),
                        ),
                      ),
                      if (widget.delay != null && widget.delay! > 0)
                        Text(
                          '${widget.delay}ms',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: quanX.success,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Draggable<_ChainDragPayload>(
      data: _ChainDragPayload(nodeName: widget.name, from: widget.side),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: quanX.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: quanX.accent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: quanX.textPrimary,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _PoolNodeCard extends StatefulWidget {
  const _PoolNodeCard({
    required this.item,
    required this.delay,
    required this.roleInCurrent,
    required this.onTap,
    this.onAddEntry,
    this.onAddExit,
  });

  final _PoolNodeItem item;
  final int? delay;
  final String? roleInCurrent;
  final VoidCallback onTap;
  final VoidCallback? onAddEntry;
  final VoidCallback? onAddExit;

  @override
  State<_PoolNodeCard> createState() => _PoolNodeCardState();
}

class _PoolNodeCardState extends State<_PoolNodeCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final l10n = context.appLocalizations;
    final isProvider = widget.item.isProvider;
    final hasRole = widget.roleInCurrent != null;

    final cardContent = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: isProvider
            ? l10n.proxyChainProviderStrictTip
            : widget.item.name,
        waitDuration: const Duration(milliseconds: 350),
        child: Opacity(
          opacity: isProvider ? 0.42 : 1,
          child: Material(
            color: quanX.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasRole
                        ? quanX.accent
                        : _hover && !isProvider
                        ? quanX.textTertiary
                        : quanX.separator,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isProvider)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 13,
                              color: quanX.textTertiary,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            widget.item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: quanX.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.delay != null && widget.delay! > 0)
                          Text(
                            '${widget.delay}ms',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isProvider
                                  ? quanX.textTertiary
                                  : quanX.success,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.item.protocol.toUpperCase()}${widget.item.isQuic ? ' · QUIC' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: quanX.textTertiary,
                            ),
                          ),
                        ),
                        if (hasRole)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: quanX.accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              widget.roleInCurrent!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: quanX.accent,
                              ),
                            ),
                          )
                        else if (_hover && !isProvider) ...[
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: widget.onAddEntry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: quanX.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                l10n.proxyChainAddEntry,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: quanX.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: widget.onAddExit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: quanX.surfaceSunken,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                l10n.proxyChainAddExit,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: quanX.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isProvider) {
      return cardContent;
    }

    return Draggable<_ChainDragPayload>(
      data: _ChainDragPayload(nodeName: widget.item.name, from: 'pool'),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 185,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: quanX.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: quanX.accent),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: quanX.textPrimary,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
      child: cardContent,
    );
  }
}
