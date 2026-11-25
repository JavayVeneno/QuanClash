import 'dart:async';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/proxies/card.dart';
import 'package:quanclash/views/proxies/common.dart';
import 'package:quanclash/views/proxies/grouping.dart';
import 'package:quanclash/views/proxies/node_quality.dart';
import 'package:quanclash/views/proxies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import 'sheet_primitives.dart';

class MobileV4ProxySheet extends ConsumerStatefulWidget {
  const MobileV4ProxySheet({super.key, required this.controller});

  final ScrollController controller;

  @override
  ConsumerState<MobileV4ProxySheet> createState() => _MobileV4ProxySheetState();
}

class _MobileV4ProxySheetState extends ConsumerState<MobileV4ProxySheet> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _activeProxyKey = GlobalKey();
  String _query = '';
  String? _selectedRegionGroupName;
  final Map<String, bool> _groupExpandedOverrides = {};
  final Map<String, bool> _sectionExpandedOverrides = {};
  bool _batchTesting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _sortLabel(ProxiesSortType sortType) {
    return switch (sortType) {
      ProxiesSortType.none => '默认排序',
      ProxiesSortType.delay => '按延迟',
      ProxiesSortType.name => '按名称',
    };
  }

  IconData _sortIcon(ProxiesSortType sortType) {
    return switch (sortType) {
      ProxiesSortType.none => QuanXIcons.arrowUpDown,
      ProxiesSortType.delay => QuanXIcons.zap,
      ProxiesSortType.name => QuanXIcons.arrowDownAZ,
    };
  }

  void _cycleSortType(ProxiesSortType current) {
    HapticFeedback.selectionClick();
    const order = ProxiesSortType.values;
    final next = order[(order.indexOf(current) + 1) % order.length];
    ref
        .read(proxiesStyleSettingProvider.notifier)
        .update((state) => state.copyWith(sortType: next));
  }

  void _toggleGroupMode(ProxiesGroupMode current) {
    HapticFeedback.selectionClick();
    final next = current == ProxiesGroupMode.region
        ? ProxiesGroupMode.all
        : ProxiesGroupMode.region;
    ref.read(proxiesViewModeProvider.notifier).updateMode(next);
  }

  List<Proxy> _filterAndSortProxies(
    List<Proxy> proxies, {
    required String query,
    required ProxiesSortType sortType,
    required DelayMap delayMap,
    required String testUrl,
  }) {
    final trimmed = query.trim().toLowerCase();
    final filtered = trimmed.isEmpty
        ? List<Proxy>.from(proxies)
        : proxies
              .where(
                (proxy) =>
                    proxy.name.toLowerCase().contains(trimmed) ||
                    proxy.type.toLowerCase().contains(trimmed),
              )
              .toList();

    switch (sortType) {
      case ProxiesSortType.none:
        return filtered;
      case ProxiesSortType.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return filtered;
      case ProxiesSortType.delay:
        final urlMap = delayMap[testUrl];
        int rankOf(Proxy proxy) {
          final d = urlMap?[proxy.name];
          if (d == null || d == 0) {
            return 900000;
          }
          if (d < 0) {
            return 950000;
          }
          return d;
        }
        filtered.sort((a, b) {
          final byDelay = rankOf(a).compareTo(rankOf(b));
          if (byDelay != 0) {
            return byDelay;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return filtered;
    }
  }

  Future<void> _runBatchDelayTest(List<Group> targetGroups) async {
    if (_batchTesting || targetGroups.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _batchTesting = true);
    try {
      for (final group in targetGroups) {
        if (group.all.isEmpty) {
          continue;
        }
        await delayTest(group.all, group.testUrl);
      }
    } finally {
      if (mounted) {
        setState(() => _batchTesting = false);
      }
    }
  }

  void _locateActiveNode(
    List<Group> groups,
    Group primaryGroup,
    ProxiesGroupMode viewMode,
    Map<String, String> selectedMap,
  ) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_query.isNotEmpty) {
        _query = '';
        _searchController.clear();
      }
      if (viewMode == ProxiesGroupMode.all) {
        _groupExpandedOverrides[primaryGroup.name] = true;
      } else {
        _selectedRegionGroupName = primaryGroup.name;
        final selectedName = primaryGroup.getCurrentSelectedName(
          selectedMap[primaryGroup.name] ?? '',
        );
        final region = regionOfProxyName(selectedName);
        if (region != null) {
          _sectionExpandedOverrides['region:${region.id}'] = true;
        } else {
          _sectionExpandedOverrides['region:other'] = true;
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _activeProxyKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
      }
    });
  }

  void _openNodeQuality(BuildContext context, Proxy proxy) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (_) => NodeQualityDialog(
        proxyName: proxy.name,
        includeRiskByDefault: true,
        autoRun: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final groups = mobileV4VisibleGroups(ref.watch(groupsProvider), mode);
    final selectedMap = ref.watch(selectedMapProvider);
    final preferredGroup = ref.watch(
      currentProfileProvider.select((state) => state?.currentGroupName),
    );
    final sortType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.sortType),
    );
    final viewMode = ref.watch(proxiesViewModeProvider);
    final delayMap = ref.watch(delayDataSourceProvider);
    final usage = ref.watch(nodeUsageProvider);
    final providers = ref.watch(providersProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (groups.isEmpty) {
      return ListView(
        controller: widget.controller,
        padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
        children: [
          const MobileV4GroupLabel('PROXY', trailing: '0 个节点', topPadding: 10),
          MobileV4Card(
            children: [
              MobileV4EmptyRow(
                text: mode == Mode.direct
                    ? '当前为直连模式，点击地球可切换模式'
                    : context.appLocalizations.proxiesEmpty,
              ),
            ],
          ),
          if (providers.isNotEmpty) _buildProvidersSection(context, providers),
        ],
      );
    }

    final primaryGroup = groups.firstWhere(
      (g) => g.name == preferredGroup,
      orElse: () => groups.first,
    );
    final activeRegionGroup = groups.firstWhere(
      (g) => g.name == (_selectedRegionGroupName ?? primaryGroup.name),
      orElse: () => primaryGroup,
    );

    final isSearching = _query.trim().isNotEmpty;
    final batchTargets = viewMode == ProxiesGroupMode.region
        ? [activeRegionGroup]
        : [primaryGroup];

    // Precompute sections when in region mode so we can also power the
    // one-tap expand-all / collapse-all toggle accurately.
    List<ProxySection> regionSections = const [];
    if (viewMode == ProxiesGroupMode.region) {
      final testUrl = ref.watch(realTestUrlProvider(activeRegionGroup.testUrl));
      final sortedProxies = _filterAndSortProxies(
        activeRegionGroup.all,
        query: _query,
        sortType: sortType,
        delayMap: delayMap,
        testUrl: testUrl,
      );
      if (sortedProxies.isNotEmpty) {
        regionSections = buildProxySections(
          proxies: sortedProxies,
          mode: ProxiesGroupMode.region,
          usage: usage,
          otherRegionLabel: '其他地区',
          recentLabel: '最近使用',
          frequentLabel: '常用节点',
          providerInfoLabel: '节点信息',
        );
      }
    }

    final bool anyExpanded = viewMode == ProxiesGroupMode.region
        ? regionSections.any(
            (s) =>
                isSearching ||
                (_sectionExpandedOverrides[s.id] ?? s.expandedByDefault),
          )
        : groups.any((g) {
            final defaultExpanded =
                groups.length <= 2 || g.name == primaryGroup.name;
            return isSearching ||
                (_groupExpandedOverrides[g.name] ?? defaultExpanded);
          });

    void toggleExpandAll() {
      HapticFeedback.selectionClick();
      final nextExpanded = !anyExpanded;
      setState(() {
        if (viewMode == ProxiesGroupMode.region) {
          for (final section in regionSections) {
            _sectionExpandedOverrides[section.id] = nextExpanded;
          }
        } else {
          for (final group in groups) {
            _groupExpandedOverrides[group.name] = nextExpanded;
          }
        }
      });
    }

    final listChildren = <Widget>[
      _buildSearchBar(p),
      const SizedBox(height: 10),
      _buildActionBar(
        sortType: sortType,
        viewMode: viewMode,
        anyExpanded: anyExpanded,
        onToggleExpandAll: toggleExpandAll,
        onBatchTest: () => unawaited(_runBatchDelayTest(batchTargets)),
        onLocate: () =>
            _locateActiveNode(groups, primaryGroup, viewMode, selectedMap),
      ),
    ];

    if (viewMode == ProxiesGroupMode.region) {
      if (groups.length > 1) {
        listChildren.add(const SizedBox(height: 10));
        listChildren.add(
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, index) {
                final g = groups[index];
                final selected = g.name == activeRegionGroup.name;
                return MobileV4PillButton(
                  label: g.name,
                  active: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRegionGroupName = g.name);
                  },
                );
              },
            ),
          ),
        );
      }
      final selectedName = activeRegionGroup.getCurrentSelectedName(
        selectedMap[activeRegionGroup.name] ?? '',
      );
      if (regionSections.isEmpty) {
        listChildren.add(const SizedBox(height: 16));
        listChildren.add(
          const MobileV4Card(
            children: [MobileV4EmptyRow(text: '没有匹配的节点')],
          ),
        );
      } else {
        var attachedActiveKey = false;
        for (final section in regionSections) {
          final isExpanded = isSearching
              ? true
              : (_sectionExpandedOverrides[section.id] ??
                    section.expandedByDefault);
          final sectionTitle = section.flag != null
              ? '${section.flag} ${section.title ?? ''}'
              : (section.title ?? activeRegionGroup.name);
          listChildren.add(
            MobileV4GroupLabel(
              sectionTitle,
              leadingIcon: isExpanded
                  ? QuanXIcons.chevronDown
                  : QuanXIcons.chevronRight,
              trailing: '${section.proxies.length} 个',
              trailingIcon: QuanXIcons.zap,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _sectionExpandedOverrides[section.id] = !isExpanded;
                });
              },
              onTrailingTap: () {
                HapticFeedback.selectionClick();
                delayTest(section.proxies, activeRegionGroup.testUrl);
              },
            ),
          );
          if (isExpanded) {
            listChildren.add(
              MobileV4Card(
                children: [
                  for (final proxy in section.proxies)
                    () {
                      final isSelected = selectedName == proxy.name;
                      final rowKey = (isSelected && !attachedActiveKey)
                          ? _activeProxyKey
                          : null;
                      if (rowKey != null) {
                        attachedActiveKey = true;
                      }
                      return _ProxyRow(
                        key: rowKey,
                        group: activeRegionGroup,
                        proxy: proxy,
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          changeProxyForNode(
                            ref,
                            activeRegionGroup.name,
                            proxy,
                            activeRegionGroup.type,
                          );
                        },
                        onInspectQuality: () =>
                            _openNodeQuality(context, proxy),
                      );
                    }(),
                ],
              ),
            );
          }
        }
      }
    } else {
      var matchCount = 0;
      var attachedActiveKey = false;
      for (final group in groups) {
        final testUrl = ref.watch(realTestUrlProvider(group.testUrl));
        final proxies = _filterAndSortProxies(
          group.all,
          query: _query,
          sortType: sortType,
          delayMap: delayMap,
          testUrl: testUrl,
        );
        if (isSearching && proxies.isEmpty) {
          continue;
        }
        matchCount += proxies.length;
        final selectedName = group.getCurrentSelectedName(
          selectedMap[group.name] ?? '',
        );
        final defaultExpanded =
            groups.length <= 2 || group.name == primaryGroup.name;
        final isExpanded = isSearching
            ? true
            : (_groupExpandedOverrides[group.name] ?? defaultExpanded);
        final trailingSummary = isExpanded
            ? mobileV4GroupTypeDescription(group.type)
            : '${proxies.length} 个 · ${selectedName.isEmpty ? '未选' : selectedName}';

        listChildren.add(
          MobileV4GroupLabel(
            group.name,
            leadingIcon: isExpanded
                ? QuanXIcons.chevronDown
                : QuanXIcons.chevronRight,
            trailing: trailingSummary,
            trailingIcon: QuanXIcons.zap,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _groupExpandedOverrides[group.name] = !isExpanded;
              });
            },
            onTrailingTap: () {
              HapticFeedback.selectionClick();
              delayTest(proxies, group.testUrl);
            },
          ),
        );
        if (isExpanded) {
          listChildren.add(
            MobileV4Card(
              children: [
                if (proxies.isEmpty)
                  const MobileV4EmptyRow(text: '该策略组暂无节点')
                else
                  for (final proxy in proxies)
                    () {
                      final isSelected = selectedName == proxy.name;
                      final rowKey =
                          (isSelected &&
                              group.name == primaryGroup.name &&
                              !attachedActiveKey)
                          ? _activeProxyKey
                          : null;
                      if (rowKey != null) {
                        attachedActiveKey = true;
                      }
                      return _ProxyRow(
                        key: rowKey,
                        group: group,
                        proxy: proxy,
                        selected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          changeProxyForNode(ref, group.name, proxy, group.type);
                        },
                        onInspectQuality: () =>
                            _openNodeQuality(context, proxy),
                      );
                    }(),
              ],
            ),
          );
        }
      }
      if (isSearching && matchCount == 0) {
        listChildren.add(const SizedBox(height: 16));
        listChildren.add(
          const MobileV4Card(
            children: [MobileV4EmptyRow(text: '没有匹配的节点')],
          ),
        );
      }
    }

    if (providers.isNotEmpty) {
      listChildren.add(_buildProvidersSection(context, providers));
    }

    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: listChildren,
    );
  }

  Widget _buildSearchBar(MobileV4Palette p) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: p.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.lineSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(QuanXIcons.search, size: 14, color: p.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(
                fontSize: 13,
                color: p.text,
                height: 1.2,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '搜索节点名或协议...',
                hintStyle: TextStyle(fontSize: 12, color: p.faint),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(QuanXIcons.x, size: 13, color: p.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionBar({
    required ProxiesSortType sortType,
    required ProxiesGroupMode viewMode,
    required bool anyExpanded,
    required VoidCallback onToggleExpandAll,
    required VoidCallback onBatchTest,
    required VoidCallback onLocate,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          MobileV4PillButton(
            icon: anyExpanded ? QuanXIcons.minimize2 : QuanXIcons.listTree,
            label: anyExpanded ? '全部收起' : '全部展开',
            onTap: onToggleExpandAll,
          ),
          const SizedBox(width: 6),
          MobileV4PillButton(
            icon: _sortIcon(sortType),
            label: _sortLabel(sortType),
            active: sortType != ProxiesSortType.none,
            onTap: () => _cycleSortType(sortType),
          ),
          const SizedBox(width: 6),
          MobileV4PillButton(
            icon: viewMode == ProxiesGroupMode.region
                ? QuanXIcons.globe
                : QuanXIcons.list,
            label: viewMode == ProxiesGroupMode.region ? '按地区' : '策略组',
            active: viewMode == ProxiesGroupMode.region,
            onTap: () => _toggleGroupMode(viewMode),
          ),
          const SizedBox(width: 6),
          MobileV4PillButton(
            icon: QuanXIcons.zap,
            label: _batchTesting ? '测速中' : '全部测速',
            loading: _batchTesting,
            onTap: onBatchTest,
          ),
          const SizedBox(width: 6),
          MobileV4PillButton(
            icon: QuanXIcons.locate,
            label: '定位当前',
            onTap: onLocate,
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersSection(
    BuildContext context,
    List<ExternalProvider> providers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MobileV4GroupLabel(
          '外部节点源',
          trailing: '管理全部',
          trailingIcon: QuanXIcons.chevronRight,
          onTrailingTap: () => pushMobileV4Subpage(
            context,
            const ProvidersView(),
          ),
        ),
        MobileV4Card(
          children: [
            for (final provider in providers)
              _ProviderRow(provider: provider),
          ],
        ),
      ],
    );
  }
}

class _ProviderRow extends ConsumerWidget {
  const _ProviderRow({required this.provider});

  final ExternalProvider provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final updating = ref.watch(isUpdatingProvider(provider.updatingKey));
    final updatedDesc = provider.updateAt.getLastUpdateTimeDesc(context);
    return MobileV4SettingsRow(
      icon: QuanXIcons.cloudDownload,
      title: provider.name,
      sub: updating
          ? '正在更新...'
          : '${provider.type} · $updatedDesc更新',
      trailing: updating
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: p.accent,
              ),
            )
          : Icon(QuanXIcons.refreshCw, size: 13, color: p.muted),
      onTap: updating
          ? null
          : () {
              HapticFeedback.selectionClick();
              ref
                  .read(proxiesActionProvider.notifier)
                  .updateProvider(provider, showLoading: true);
            },
    );
  }
}

class _ProxyRow extends ConsumerWidget {
  const _ProxyRow({
    super.key,
    required this.group,
    required this.proxy,
    required this.selected,
    required this.onTap,
    required this.onInspectQuality,
  });

  final Group group;
  final Proxy proxy;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInspectQuality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: group.testUrl),
    );
    final qualityResult = ref.watch(
      nodeQualityResultsProvider.select((state) => state[proxy.name]),
    );
    final freshRisk =
        qualityResult != null &&
            isNodeQualityFresh(qualityResult) &&
            qualityResult.quality.status == NodeQualityStatus.ok
        ? qualityResult.quality.riskScore
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onInspectQuality,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              MobileV4RadioCircle(selected: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proxy.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                        color: p.text,
                      ),
                    ),
                    if (proxy.type.isNotEmpty || freshRisk != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (proxy.type.isNotEmpty)
                            Flexible(
                              child: Text(
                                proxy.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          if (freshRisk != null) ...[
                            if (proxy.type.isNotEmpty)
                              const SizedBox(width: 6),
                            _RiskMiniBadge(score: freshRisk),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onInspectQuality,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  child: Icon(
                    QuanXIcons.shield,
                    size: 13,
                    color: freshRisk == null
                        ? p.faint
                        : _riskColor(p, freshRisk),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => proxyDelayTest(proxy, group.testUrl),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _LatencyLabel(delay: delay),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _riskColor(MobileV4Palette p, int score) {
    if (score <= 30) {
      return p.signal;
    }
    if (score <= 60) {
      return p.warn;
    }
    return p.danger;
  }
}

class _RiskMiniBadge extends StatelessWidget {
  const _RiskMiniBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final color = score <= 30
        ? p.signal
        : score <= 60
        ? p.warn
        : p.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '风 $score',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LatencyLabel extends StatelessWidget {
  const _LatencyLabel({required this.delay});

  final int? delay;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final d = delay;
    if (d == 0) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: p.accent,
        ),
      );
    }
    final (String text, Color color) = switch (d) {
      null => ('—', p.faint),
      < 0 => ('超时', p.danger),
      < 200 => ('$d ms', p.signal),
      < 500 => ('$d ms', p.warn),
      _ => ('$d ms', p.danger),
    };
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
