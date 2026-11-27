import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/mobile_v4/theme.dart';
import 'package:quanclash/views/proxies/chains/chain_dialogs.dart';
import 'package:quanclash/views/proxies/chains/chain_issue_l10n.dart';
import 'package:quanclash/views/proxies/chains/chain_node_drawer.dart';
import 'package:quanclash/views/proxies/common.dart' as proxies_common;
import 'package:quanclash/views/proxies/grouping.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:quanclash/widgets/widgets.dart';

/// Mobile v4 vertical two-card Proxy Chain editor with an 80% frosted
/// 2-column node picker bottom sheet.
class MobileV4ChainEditorPage extends ConsumerStatefulWidget {
  const MobileV4ChainEditorPage({
    super.key,
    required this.chainId,
    required this.profileId,
    required this.rawConfig,
    this.skipCoreReload = false,
  });

  final int chainId;
  final int profileId;
  final Map<String, dynamic> rawConfig;
  final bool skipCoreReload;

  @override
  ConsumerState<MobileV4ChainEditorPage> createState() =>
      _MobileV4ChainEditorPageState();
}

class _MobileV4ChainEditorPageState
    extends ConsumerState<MobileV4ChainEditorPage> {
  ProxyChain? _draft;
  bool _applying = false;

  bool _isStrictDns() {
    final network = ref.read(networkSettingProvider);
    return network.dnsSafetyMode == DnsSafetyMode.proxyOnly ||
        network.autoSetSystemDns;
  }

  ProxyChain? _appliedChain(List<ProxyChain> chains) {
    for (final c in chains) {
      if (c.id == widget.chainId) return c;
    }
    return null;
  }

  bool _isDirty(ProxyChain? applied) {
    return _draft != null && _draft != applied;
  }

  void _updateDraft(
    ProxyChain current,
    ProxyChain Function(ProxyChain c) updater,
  ) {
    setState(() {
      _draft = updater(_draft ?? current);
    });
  }

  Future<bool> _apply(ProxyChain working) async {
    final issues = validateSingleChain(
      working,
      widget.rawConfig,
      strictDns: _isStrictDns(),
    );
    final errors = issues.where((i) => i.isError).toList();
    if (errors.isNotEmpty) {
      globalState.showNotifier(
        formatChainIssue(context.appLocalizations, errors.first),
      );
      return false;
    }
    setState(() => _applying = true);
    try {
      await ref
          .read(profileProxyChainsProvider(widget.profileId).notifier)
          .put(working);
      _draft = null;
      if (!widget.skipCoreReload) {
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
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _setAsCurrent(ProxyChain chain) async {
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
      final hasDirect = targetGroup.all.any((p) => p.name == chain.groupName);
      final targetSelection = hasDirect
          ? chain.groupName
          : chainAggregateGroupName;
      ref
          .read(profilesActionProvider.notifier)
          .updateCurrentSelectedMap(targetGroup.name, targetSelection);
      ref
          .read(proxiesActionProvider.notifier)
          .changeProxyDebounce(targetGroup.name, targetSelection);
      HapticFeedback.lightImpact();
      globalState.showNotifier('${targetGroup.name} → ${chain.groupName}');
    }
  }

  Future<void> _handleBack(ProxyChain? applied, ProxyChain working) async {
    if (!_isDirty(applied)) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final choice = await showChainUnsavedDialog(context, working.name);
    if (choice == 'discard' && mounted) {
      Navigator.of(context).pop();
    } else if (choice == 'apply') {
      final ok = await _apply(working);
      if (ok && mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _delete(ProxyChain working) async {
    final refs = findChainRuleReferences(widget.rawConfig, working.groupName);
    final ok = await showChainDeleteConfirmDialog(
      context,
      working.name,
      refs.length,
    );
    if (!ok) return;
    await ref
        .read(profileProxyChainsProvider(widget.profileId).notifier)
        .deleteChain(working.id);
    if (!widget.skipCoreReload) {
      await ref
          .read(setupActionProvider.notifier)
          .applyProfile(force: true, silence: true);
    }
    if (mounted) Navigator.of(context).pop();
  }

  int? _lookupDelay(String name) {
    final delayMap = ref.watch(delayDataSourceProvider);
    for (final urlMap in delayMap.values) {
      final v = urlMap[name];
      if (v != null && v > 0) return v;
    }
    return null;
  }

  Future<void> _openNodePicker({
    required ProxyChain working,
    required String side,
    required List<ProxyChain> allChains,
  }) async {
    final staticProxies = extractStaticProxies(widget.rawConfig);
    final liveGroups = ref.read(groupsProvider);
    final generatedNames = <String>{
      chainAggregateGroupName,
      for (final c in allChains) ...[
        c.groupName,
        c.entryGroupName,
        for (final m in c.exit.members) c.exitCopyName(m),
      ],
    };

    final items = <_PickerNode>[];
    final seen = <String>{};
    for (final entry in staticProxies.entries) {
      final name = entry.key;
      if (isBuiltinPolicyName(name) || generatedNames.contains(name)) continue;
      final map = entry.value;
      final type = (map['type'] as String?) ?? 'unknown';
      final region = regionOfProxyName(name);
      items.add(
        _PickerNode(
          name: name,
          protocol: type,
          isProvider: false,
          supportsUdp: nodeSupportsUdp(map),
          isQuic: isQuicProtocol(type),
          server: map['server'] as String?,
          port: map['port'] is int ? map['port'] as int : null,
          regionId: region?.id ?? 'other',
          regionLabel: region?.label,
        ),
      );
      seen.add(name);
    }
    for (final g in liveGroups) {
      for (final proxy in g.all) {
        if (seen.contains(proxy.name) ||
            isBuiltinPolicyName(proxy.name) ||
            generatedNames.contains(proxy.name) ||
            GroupTypeExtension.valueList.contains(proxy.type)) {
          continue;
        }
        final region = regionOfProxyName(proxy.name);
        items.add(
          _PickerNode(
            name: proxy.name,
            protocol: proxy.type,
            isProvider: true,
            supportsUdp: true,
            isQuic: isQuicProtocol(proxy.type),
            regionId: region?.id ?? 'other',
            regionLabel: region?.label,
          ),
        );
        seen.add(proxy.name);
      }
    }

    final initialMembers = List<String>.from(
      side == 'entry' ? working.entry.members : working.exit.members,
    );
    final oppositeMembers = (side == 'entry'
            ? working.exit.members
            : working.entry.members)
        .toSet();

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: MobileV4Palette.of(context).sheetBarrier,
      builder: (_) => _MobileV4NodePickerSheet(
        side: side,
        items: items,
        initialSelected: initialMembers,
        oppositeMembers: oppositeMembers,
      ),
    );
    if (result != null) {
      _updateDraft(working, (c) {
        return side == 'entry'
            ? c.copyWith(entry: c.entry.copyWith(members: result))
            : c.copyWith(exit: c.exit.copyWith(members: result));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final l10n = context.appLocalizations;
    final chains = ref.watch(profileProxyChainsProvider(widget.profileId));
    final applied = _appliedChain(chains);
    final working = _draft ?? applied;
    if (working == null) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ),
      );
    }

    final dirty = _isDirty(applied);
    final staticProxies = extractStaticProxies(widget.rawConfig);
    final issues = validateSingleChain(
      working,
      widget.rawConfig,
      strictDns: _isStrictDns(),
    );
    final hasErrors = issues.any((i) => i.isError);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack(applied, working);
      },
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.lineSoft)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: p.text,
                      ),
                      onPressed: () => _handleBack(applied, working),
                    ),
                    MobiusIcon(size: 16, color: p.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final renamed = await showChainRenameDialog(
                            context,
                            working.name,
                          );
                          if (renamed != null) {
                            _updateDraft(
                              working,
                              (c) => c.copyWith(name: renamed),
                            );
                          }
                        },
                        child: Text(
                          working.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                      ),
                    ),
                    if (dirty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.warn.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.proxyChainUnapplied,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: p.warn,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      color: p.cardFill,
                      icon: Icon(
                        QuanXIcons.ellipsisVertical,
                        size: 18,
                        color: p.text2,
                      ),
                      onSelected: (value) async {
                        switch (value) {
                          case 'rename':
                            final renamed = await showChainRenameDialog(
                              context,
                              working.name,
                            );
                            if (renamed != null) {
                              _updateDraft(
                                working,
                                (c) => c.copyWith(name: renamed),
                              );
                            }
                          case 'yaml':
                            await showChainYamlDialog(context, working);
                          case 'policy':
                            final next = await showChainFailurePolicyDialog(
                              context,
                              working.failurePolicy,
                            );
                            if (next != null) {
                              _updateDraft(
                                working,
                                (c) => c.copyWith(failurePolicy: next),
                              );
                            }
                          case 'delete':
                            await _delete(working);
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
                            style: TextStyle(color: p.danger),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Conditional issues bar
              if (issues.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: (issues.first.isError ? p.danger : p.warn).withValues(
                    alpha: 0.12,
                  ),
                  child: Text(
                    formatChainIssue(l10n, issues.first),
                    style: TextStyle(
                      fontSize: 12,
                      color: issues.first.isError ? p.danger : p.warn,
                    ),
                  ),
                ),
              // Vertical Entry -> Exit stack
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    _buildHopCard(
                      context,
                      p: p,
                      working: working,
                      allChains: chains,
                      side: 'entry',
                      staticProxies: staticProxies,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: GestureDetector(
                          onTap: () => showChainYamlDialog(context, working),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: p.cardFill,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: hasErrors ? p.danger : p.line,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 13,
                                  color: hasErrors ? p.danger : p.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'dialer-proxy · YAML',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: hasErrors ? p.danger : p.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildHopCard(
                      context,
                      p: p,
                      working: working,
                      allChains: chains,
                      side: 'exit',
                      staticProxies: staticProxies,
                    ),
                  ],
                ),
              ),
              // Bottom action bar
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
                decoration: BoxDecoration(
                  color: p.cardFill,
                  border: Border(top: BorderSide(color: p.line)),
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              working.failurePolicy ==
                                  ChainFailurePolicy.directFallback
                              ? p.danger
                              : p.line,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final next = await showChainFailurePolicyDialog(
                          context,
                          working.failurePolicy,
                        );
                        if (next != null) {
                          _updateDraft(
                            working,
                            (c) => c.copyWith(failurePolicy: next),
                          );
                        }
                      },
                      child: Text(
                        working.failurePolicy ==
                                ChainFailurePolicy.directFallback
                            ? '⚠ ${l10n.proxyChainFailureDirectBadge}'
                            : l10n.proxyChainFailureBlock.split('（').first,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              working.failurePolicy ==
                                  ChainFailurePolicy.directFallback
                              ? p.danger
                              : p.text2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.nodeQualityTitle,
                      style: IconButton.styleFrom(
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(QuanXIcons.shield, size: 16, color: p.signal),
                      onPressed: () {
                        if (working.exit.members.isEmpty) {
                          globalState.showNotifier(l10n.nodeQualityPickNode);
                          return;
                        }
                        final target = dirty
                            ? working.exit.members.first
                            : working.exitCopyName(working.exit.members.first);
                        showDialog<void>(
                          context: context,
                          builder: (_) => NodeQualityDialog(proxyName: target),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.onAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _applying
                              ? null
                              : () async {
                                  if (dirty) {
                                    await _apply(working);
                                  } else {
                                    await _setAsCurrent(working);
                                  }
                                },
                          child: _applying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  dirty
                                      ? l10n.proxyChainApply
                                      : l10n.proxyChainSetCurrent,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildHopCard(
    BuildContext context, {
    required MobileV4Palette p,
    required ProxyChain working,
    required List<ProxyChain> allChains,
    required String side,
    required Map<String, Map<String, dynamic>> staticProxies,
  }) {
    final l10n = context.appLocalizations;
    final isEntry = side == 'entry';
    final hop = isEntry ? working.entry : working.exit;
    final allowedTypes = isEntry
        ? const [ChainGroupType.fallback, ChainGroupType.urlTest]
        : const [ChainGroupType.fallback, ChainGroupType.select];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardFill,
        borderRadius: BorderRadius.circular(MobileV4Theme.radiusCard),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                isEntry ? l10n.proxyChainEntry : l10n.proxyChainExit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
              ),
              const SizedBox(width: 8),
              if (hop.members.length == 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: p.fill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.proxyChainSingleNode,
                    style: TextStyle(fontSize: 10, color: p.muted),
                  ),
                )
              else
                Text(
                  '${hop.members.length}',
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
              const Spacer(),
              if (isEntry &&
                  hop.type == ChainGroupType.urlTest &&
                  hop.members.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () async {
                      final params = await showChainUrlTestParamsDialog(
                        context,
                        hop,
                      );
                      if (params != null) {
                        _updateDraft(
                          working,
                          (c) => c.copyWith(
                            entry: c.entry.copyWith(
                              tolerance: params.$1,
                              interval: params.$2,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.fill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '±${hop.tolerance}ms',
                        style: TextStyle(fontSize: 11, color: p.text2),
                      ),
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: p.fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in allowedTypes)
                      GestureDetector(
                        onTap: () {
                          _updateDraft(working, (c) {
                            return isEntry
                                ? c.copyWith(
                                    entry: c.entry.copyWith(type: type),
                                  )
                                : c.copyWith(exit: c.exit.copyWith(type: type));
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hop.type == type
                                ? p.cardFill
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type.yamlValue,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: hop.type == type ? p.accent : p.muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hop.members.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.lineSoft),
              ),
              child: Text(
                isEntry
                    ? l10n.proxyChainEntryDropHint
                    : l10n.proxyChainExitDropHint,
                style: TextStyle(fontSize: 12, color: p.muted),
              ),
            )
          else
            for (var i = 0; i < hop.members.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _buildMemberRow(
                context,
                p: p,
                working: working,
                side: side,
                index: i,
                name: hop.members[i],
                map: staticProxies[hop.members[i]],
              ),
            ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: p.line),
              foregroundColor: p.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(QuanXIcons.plus, size: 15),
            label: Text(
              isEntry ? l10n.proxyChainAddEntry : l10n.proxyChainAddExit,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _openNodePicker(
              working: working,
              side: side,
              allChains: allChains,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    BuildContext context, {
    required MobileV4Palette p,
    required ProxyChain working,
    required String side,
    required int index,
    required String name,
    required Map<String, dynamic>? map,
  }) {
    final isEntry = side == 'entry';
    final members = isEntry ? working.entry.members : working.exit.members;
    final missing = map == null;
    final delay = _lookupDelay(isEntry ? name : working.exitCopyName(name));

    return GestureDetector(
      onTap: () {
        showChainNodeDrawer(
          context,
          ChainNodeInfo(
            name: name,
            protocol: (map?['type'] as String?) ?? '?',
            isProvider: false,
            server: map?['server'] as String?,
            port: map?['port'] is int ? map!['port'] as int : null,
            supportsUdp: map != null && nodeSupportsUdp(map),
            isQuic: map != null && isQuicProtocol(map['type'] as String?),
            delay: _lookupDelay(name),
            fullChainDelay: isEntry ? null : delay,
            qualityProxyName: isEntry ? name : working.exitCopyName(name),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: missing ? p.danger : p.lineSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.cardFill,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: p.text2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: missing ? TextDecoration.lineThrough : null,
                      color: missing ? p.danger : p.text,
                    ),
                  ),
                  Text(
                    missing
                        ? 'MISSING'
                        : '${((map['type'] as String?) ?? '').toUpperCase()}${delay != null ? ' · ${delay}ms' : ''}',
                    style: TextStyle(
                      fontSize: 10,
                      color: missing ? p.danger : p.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (index > 0)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.arrow_upward_rounded, size: 15, color: p.muted),
                onPressed: () {
                  _updateDraft(working, (c) {
                    final list = List<String>.from(members);
                    final item = list.removeAt(index);
                    list.insert(index - 1, item);
                    return isEntry
                        ? c.copyWith(entry: c.entry.copyWith(members: list))
                        : c.copyWith(exit: c.exit.copyWith(members: list));
                  });
                },
              ),
            if (index < members.length - 1)
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.arrow_downward_rounded,
                  size: 15,
                  color: p.muted,
                ),
                onPressed: () {
                  _updateDraft(working, (c) {
                    final list = List<String>.from(members);
                    final item = list.removeAt(index);
                    list.insert(index + 1, item);
                    return isEntry
                        ? c.copyWith(entry: c.entry.copyWith(members: list))
                        : c.copyWith(exit: c.exit.copyWith(members: list));
                  });
                },
              ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(QuanXIcons.x, size: 14, color: p.muted),
              onPressed: () {
                _updateDraft(working, (c) {
                  final list = members.where((m) => m != name).toList();
                  return isEntry
                      ? c.copyWith(entry: c.entry.copyWith(members: list))
                      : c.copyWith(exit: c.exit.copyWith(members: list));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerNode {
  const _PickerNode({
    required this.name,
    required this.protocol,
    required this.isProvider,
    required this.supportsUdp,
    required this.isQuic,
    required this.regionId,
    this.regionLabel,
    this.server,
    this.port,
  });

  final String name;
  final String protocol;
  final bool isProvider;
  final bool supportsUdp;
  final bool isQuic;
  final String regionId;
  final String? regionLabel;
  final String? server;
  final int? port;
}

class _MobileV4NodePickerSheet extends ConsumerStatefulWidget {
  const _MobileV4NodePickerSheet({
    required this.side,
    required this.items,
    required this.initialSelected,
    required this.oppositeMembers,
  });

  final String side;
  final List<_PickerNode> items;
  final List<String> initialSelected;
  final Set<String> oppositeMembers;

  @override
  ConsumerState<_MobileV4NodePickerSheet> createState() =>
      _MobileV4NodePickerSheetState();
}

class _MobileV4NodePickerSheetState
    extends ConsumerState<_MobileV4NodePickerSheet> {
  late final List<String> _selected = List<String>.from(widget.initialSelected);
  String _regionId = 'all';
  bool _onlyUdp = false;
  String _query = '';
  bool _testing = false;

  int? _delayOf(String name) {
    final map = ref.watch(delayDataSourceProvider);
    for (final urlMap in map.values) {
      final v = urlMap[name];
      if (v != null && v > 0) return v;
    }
    return null;
  }

  Future<void> _testVisible(List<_PickerNode> visible) async {
    if (_testing || visible.isEmpty) return;
    setState(() => _testing = true);
    try {
      final proxies = visible
          .where((n) => !n.isProvider)
          .map((n) => Proxy(name: n.name, type: n.protocol))
          .toList();
      await proxies_common.delayTest(proxies);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final l10n = context.appLocalizations;
    final regionMap = <String, String>{};
    for (final item in widget.items) {
      if (item.regionId != 'other' && item.regionLabel != null) {
        regionMap.putIfAbsent(item.regionId, () => item.regionLabel!);
      }
    }
    final hasOther = widget.items.any((i) => i.regionId == 'other');

    final filtered = widget.items.where((item) {
      if (_regionId != 'all' && item.regionId != _regionId) return false;
      if (_onlyUdp && !item.supportsUdp) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!item.name.toLowerCase().contains(q) &&
            !item.protocol.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      expand: false,
      builder: (ctx, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MobileV4Theme.radiusSheet),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                color: p.sheet,
                border: Border(top: BorderSide(color: p.sheetTopBorder)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.sheetHandle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.side == 'entry'
                                ? l10n.proxyChainEntry
                                : l10n.proxyChainExit,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: p.text,
                            ),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.onAccent,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(_selected),
                          child: Text('${l10n.confirm} (${_selected.length})'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _query = v.trim()),
                              style: TextStyle(fontSize: 12, color: p.text),
                              decoration: InputDecoration(
                                hintText: l10n.search,
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: p.muted,
                                ),
                                prefixIcon: Icon(
                                  QuanXIcons.search,
                                  size: 14,
                                  color: p.muted,
                                ),
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: p.cardFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: p.line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: p.line),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: p.line),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _testing
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                    ),
                                  )
                                : Icon(
                                    QuanXIcons.zap,
                                    size: 13,
                                    color: p.accent,
                                  ),
                            label: Text(
                              l10n.delay,
                              style: TextStyle(fontSize: 12, color: p.text),
                            ),
                            onPressed: _testing
                                ? null
                                : () => _testVisible(filtered),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _regionChip(
                          p,
                          l10n.proxyChainAll,
                          _regionId == 'all',
                          () => setState(() => _regionId = 'all'),
                        ),
                        for (final e in regionMap.entries) ...[
                          const SizedBox(width: 6),
                          _regionChip(
                            p,
                            e.value,
                            _regionId == e.key,
                            () => setState(() => _regionId = e.key),
                          ),
                        ],
                        if (hasOther) ...[
                          const SizedBox(width: 6),
                          _regionChip(
                            p,
                            l10n.proxiesOtherRegion,
                            _regionId == 'other',
                            () => setState(() => _regionId = 'other'),
                          ),
                        ],
                        const SizedBox(width: 6),
                        _regionChip(
                          p,
                          l10n.proxyChainOnlyUdp,
                          _onlyUdp,
                          () => setState(() => _onlyUdp = !_onlyUdp),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      controller: controller,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        2,
                        20,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisExtent: 64,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isPicked = _selected.contains(item.name);
                        final onOpposite = widget.oppositeMembers.contains(
                          item.name,
                        );
                        final disabled = item.isProvider || onOpposite;
                        final delay = _delayOf(item.name);

                        return GestureDetector(
                          onTap: () {
                            if (item.isProvider) {
                              globalState.showNotifier(
                                l10n.proxyChainProviderStrictTip,
                              );
                              return;
                            }
                            if (onOpposite) {
                              globalState.showNotifier(
                                l10n.proxyChainErrBothSides(item.name),
                              );
                              return;
                            }
                            HapticFeedback.selectionClick();
                            setState(() {
                              if (isPicked) {
                                _selected.remove(item.name);
                              } else {
                                _selected.add(item.name);
                              }
                            });
                          },
                          onLongPress: () {
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
                                delay: delay,
                              ),
                            );
                          },
                          child: Opacity(
                            opacity: disabled ? 0.42 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isPicked ? p.accentSoft : p.cardFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isPicked ? p.accent : p.line,
                                  width: isPicked ? 1.4 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (item.isProvider)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            size: 12,
                                            color: p.muted,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: p.text,
                                          ),
                                        ),
                                      ),
                                      if (isPicked)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 15,
                                          color: p.accent,
                                        ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.protocol.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: p.muted,
                                          ),
                                        ),
                                      ),
                                      if (delay != null)
                                        Text(
                                          '${delay}ms',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: disabled
                                                ? p.muted
                                                : p.signal,
                                          ),
                                        ),
                                    ],
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
            ),
          ),
        );
      },
    );
  }

  Widget _regionChip(
    MobileV4Palette p,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? p.accentSoft : p.cardFill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? p.accent : p.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? p.accent : p.text2,
          ),
        ),
      ),
    );
  }
}
