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
import 'package:quanclash/views/mobile_v4/liquid_switch.dart';
import 'package:quanclash/views/mobile_v4/sheets/chain_editor_page.dart';
import 'package:quanclash/views/mobile_v4/sheets/sheet_primitives.dart';
import 'package:quanclash/views/mobile_v4/theme.dart';
import 'package:quanclash/views/proxies/chains/chain_issue_l10n.dart';
import 'package:quanclash/widgets/widgets.dart';

/// Mobile v4 80% frosted sheet for listing and managing Proxy Chains.
class MobileV4ChainsSheet extends ConsumerStatefulWidget {
  const MobileV4ChainsSheet({
    super.key,
    required this.controller,
    this.initialRawConfig,
    this.initialProfileId,
  });

  final ScrollController controller;
  final Map<String, dynamic>? initialRawConfig;
  final int? initialProfileId;

  @override
  ConsumerState<MobileV4ChainsSheet> createState() =>
      _MobileV4ChainsSheetState();
}

class _MobileV4ChainsSheetState extends ConsumerState<MobileV4ChainsSheet> {
  Map<String, dynamic> _rawConfig = const {};
  bool _loadingConfig = true;

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
    HapticFeedback.selectionClick();
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

  Future<void> _createNewChain(List<ProxyChain> chains) async {
    final profileId = _profileId;
    if (profileId == null) return;
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
    if (!mounted) return;
    await pushMobileV4Subpage<void>(
      context,
      MobileV4ChainEditorPage(
        chainId: created.id,
        profileId: profileId,
        rawConfig: _rawConfig,
        skipCoreReload: widget.initialRawConfig != null,
      ),
    );
  }

  Future<void> _setChainAsCurrent(ProxyChain chain) async {
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

  int? _lookupDelay(ProxyChain chain) {
    if (chain.exit.members.isEmpty) return null;
    final target = chain.exitCopyName(chain.exit.members.first);
    final delayMap = ref.watch(delayDataSourceProvider);
    for (final urlMap in delayMap.values) {
      final v = urlMap[target];
      if (v != null && v > 0) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final l10n = context.appLocalizations;
    final profileId = _profileId;
    final profile = profileId == null
        ? null
        : ref.watch(profileProvider(profileId));
    final chains = profileId == null
        ? const <ProxyChain>[]
        : ref.watch(profileProxyChainsProvider(profileId));
    final chainsEnabled = profile?.chainsEnabled ?? true;
    final groups = ref.watch(groupsProvider);
    final selectedMap = ref.watch(selectedMapProvider);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final currentGroup = computeCurrentGroup(
      groups,
      preferredName: profile?.currentGroupName,
      selectedMap: selectedMap,
      mode: mode,
    );
    final rawSelected = currentGroup?.now ?? '';
    final resolved = rawSelected.isEmpty
        ? ''
        : computeRealSelectedProxyState(
            rawSelected,
            groups: groups,
            selectedMap: selectedMap,
          ).proxyName;
    final activeChain = resolveActiveProxyChain(
      chains,
      proxyName: resolved,
      groupNow: rawSelected,
      chainsEnabled: chainsEnabled,
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (_loadingConfig) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.controller,
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomInset),
            children: [
              // Profile-level switch row matching Mobile v4 card language.
              if (profile != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: p.cardFill,
                    borderRadius: BorderRadius.circular(
                      MobileV4Theme.radiusCard,
                    ),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: p.accentSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: MobiusIcon(size: 18, color: p.accent),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.proxyChainTitle,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            if (profile.label.isNotEmpty)
                              Text(
                                profile.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      MobileV4LiquidSwitch(
                        value: chainsEnabled,
                        onChanged: (_) => _toggleProfileChains(profile, chains),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              if (!chainsEnabled)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: p.cardFill,
                    borderRadius: BorderRadius.circular(
                      MobileV4Theme.radiusCard,
                    ),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      MobiusIcon(size: 28, color: p.accent),
                      const SizedBox(height: 10),
                      Text(
                        l10n.proxyChainDisabledTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.proxyChainDisabledDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: p.text2),
                      ),
                    ],
                  ),
                )
              else if (chains.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: p.cardFill,
                    borderRadius: BorderRadius.circular(
                      MobileV4Theme.radiusCard,
                    ),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      MobiusIcon(size: 28, color: p.accent),
                      const SizedBox(height: 10),
                      Text(
                        l10n.proxyChainEmptyTitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.proxyChainEmptyDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: p.text2),
                      ),
                    ],
                  ),
                )
              else
                for (final chain in chains) ...[
                  _buildChainCard(
                    context,
                    p: p,
                    chain: chain,
                    isCurrent: activeChain?.id == chain.id,
                    profileId: profileId!,
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
        if (chainsEnabled && profileId != null)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 14 + bottomInset),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(QuanXIcons.plus, size: 16),
                label: Text(
                  l10n.proxyChainNew,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _createNewChain(chains),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChainCard(
    BuildContext context, {
    required MobileV4Palette p,
    required ProxyChain chain,
    required bool isCurrent,
    required int profileId,
  }) {
    final l10n = context.appLocalizations;
    final issues = validateSingleChain(
      chain,
      _rawConfig,
      strictDns: _isStrictDns(),
    );
    final errors = issues.where((i) => i.isError).toList();
    final invalid = errors.isNotEmpty;
    final delay = _lookupDelay(chain);

    return GestureDetector(
      onTap: () {
        pushMobileV4Subpage<void>(
          context,
          MobileV4ChainEditorPage(
            chainId: chain.id,
            profileId: profileId,
            rawConfig: _rawConfig,
            skipCoreReload: widget.initialRawConfig != null,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.cardFill,
          borderRadius: BorderRadius.circular(MobileV4Theme.radiusCard),
          border: Border.all(
            color: isCurrent && !invalid ? p.accent : p.line,
            width: isCurrent && !invalid ? 1.4 : 1,
          ),
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
                    shape: BoxShape.circle,
                    color: invalid ? p.danger : p.signal,
                  ),
                ),
                const SizedBox(width: 8),
                MobiusIcon(
                  size: 15,
                  color: invalid ? p.muted : p.accent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    chain.groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (invalid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.danger.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.proxyChainInvalid,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.danger,
                      ),
                    ),
                  )
                else if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.proxyChainSetCurrent,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.accent,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _setChainAsCurrent(chain),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        l10n.proxyChainSetCurrent,
                        style: TextStyle(fontSize: 11, color: p.text2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      invalid
                          ? formatChainIssue(l10n, errors.first)
                          : '${chain.entry.members.length} ${l10n.proxyChainEntry} → ${chain.exit.members.length} ${l10n.proxyChainExit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: invalid ? p.danger : p.muted,
                      ),
                    ),
                  ),
                  if (!invalid && delay != null)
                    Text(
                      '$delay ms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.signal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
