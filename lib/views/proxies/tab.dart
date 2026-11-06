import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dashboard_style.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'card.dart';
import 'common.dart';
import 'grouping.dart';

typedef ProxyGroupViewKeyMap =
    Map<String, GlobalObjectKey<_ProxyGroupViewState>>;

const _sectionHeaderHeight = 40.0;
const _sectionGap = 8.0;

class ProxiesTabView extends ConsumerStatefulWidget {
  final bool listMode;

  const ProxiesTabView({super.key, this.listMode = false});

  static Map<String, PageStorageKey> pageListStoreMap = {};

  @override
  ConsumerState<ProxiesTabView> createState() => ProxiesTabViewState();
}

class ProxiesTabViewState extends ConsumerState<ProxiesTabView>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final _hasMoreButtonNotifier = ValueNotifier<bool>(false);
  ProxyGroupViewKeyMap _keyMap = {};

  @override
  void initState() {
    super.initState();
    ref.listenManual(proxiesTabControllerStateProvider, (prev, next) {
      if (prev == next) {
        return;
      }
      if (!stringListEquality.equals(prev?.a, next.a)) {
        _destroyTabController();
        final groupNames = next.a;
        final currentGroupName = next.b;
        final index = groupNames.indexWhere((item) => item == currentGroupName);
        _updateTabController(groupNames.length, index);
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _destroyTabController();
    super.dispose();
  }

  void scrollToGroupSelected() {
    final currentGroupName = getCurrentGroupName();
    _keyMap[currentGroupName]?.currentState?.scrollToSelected();
  }

  Future<void> delayTestCurrentGroup() async {
    final currentGroupName = getCurrentGroupName();
    final currentState = _keyMap[currentGroupName]?.currentState;
    await delayTest(currentState?.currentProxies ?? [], currentState?.testUrl);
  }

  Widget _buildMoreButton() {
    return Consumer(
      builder: (_, ref, _) {
        final isMobileView = ref.watch(isMobileViewProvider);
        return IconButton(
          onPressed: _showMoreMenu,
          icon: isMobileView
              ? const Icon(QuanXIcons.chevronDown)
              : const Icon(QuanXIcons.chevronRight),
        );
      },
    );
  }

  void _showMoreMenu() {
    showSheet(
      context: context,
      props: const SheetProps(isScrollControlled: false),
      builder: (_) {
        return AdaptiveSheetScaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (_, ref, _) {
                final state = ref.watch(proxiesTabControllerStateProvider);
                final groupNames = state.a;
                final currentGroupName = state.b;
                return SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runSpacing: 8,
                    spacing: 8,
                    children: [
                      for (final groupName in groupNames)
                        SettingTextCard(
                          groupName,
                          onPressed: () {
                            final index = groupNames.indexWhere(
                              (item) => item == groupName,
                            );
                            if (index == -1) return;
                            _tabController?.animateTo(index);
                            updateCurrentGroupName(groupName);
                            Navigator.of(context).pop();
                          },
                          isSelected: groupName == currentGroupName,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          title: context.appLocalizations.proxyGroup,
        );
      },
    );
  }

  void _tabControllerListener([int? index]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? groupIndex = index;
      if (groupIndex == -1) {
        return;
      }
      if (groupIndex == null) {
        final currentIndex = _tabController?.index;
        groupIndex = currentIndex;
      }
      final currentGroups = getCurrentGroups();
      if (groupIndex == null || groupIndex > currentGroups.length) {
        return;
      }
      final currentGroup = currentGroups[groupIndex];
      updateCurrentGroupName(currentGroup.name);
    });
  }

  void _destroyTabController() {
    _tabController?.removeListener(_tabControllerListener);
    _tabController?.dispose();
    _tabController = null;
  }

  void _updateTabController(int length, int index) {
    _destroyTabController();
    if (length == 0) {
      return;
    }
    final realIndex = index == -1 ? 0 : index;
    _tabController ??= TabController(
      length: length,
      initialIndex: realIndex,
      vsync: this,
    );
    _tabControllerListener(realIndex);
    _tabController?.addListener(_tabControllerListener);
  }

  Widget _buildTabs(BuildContext context, List<Group> groups) {
    final quanX = context.quanX;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (scrollNotification) {
        _hasMoreButtonNotifier.value =
            scrollNotification.metrics.maxScrollExtent > 0;
        return false;
      },
      child: ValueListenableBuilder(
        valueListenable: _hasMoreButtonNotifier,
        builder: (_, value, child) {
          return Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              TabBar(
                controller: _tabController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16 + (value ? 40 : 0),
                ),
                dividerColor: Colors.transparent,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: DashboardPalette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                labelColor: DashboardPalette.primary,
                unselectedLabelColor: quanX.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                tabs: [
                  for (final group in groups)
                    Tab(
                      height: 32,
                      child: Builder(
                        builder: (context) {
                          return EmojiText(
                            group.name,
                            style: DefaultTextStyle.of(context).style,
                          );
                        },
                      ),
                    ),
                ],
              ),
              if (value)
                Positioned(
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          DashboardPalette.background(
                            context,
                          ).withValues(alpha: 0),
                          DashboardPalette.background(context),
                        ],
                        stops: const [0.0, 0.35],
                      ),
                    ),
                    child: child!,
                  ),
                ),
            ],
          );
        },
        child: _buildMoreButton(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    ref.watch(themeSettingProvider.select((state) => state.textScale));
    final state = ref.watch(proxiesTabStateProvider.select((state) => state));
    final groups = state.groups;
    if (groups.isEmpty || _tabController == null) {
      return NullStatus(
        illustration: const ProxyEmptyIllustration(),
        label: appLocalizations.nullTip(appLocalizations.proxies),
      );
    }
    final query = ref.watch(queryProvider(QueryTag.proxies));
    final mode = query.isNotEmpty
        ? ProxiesGroupMode.all
        : ref.watch(proxiesViewModeProvider);
    _keyMap = {};
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTabs(context, groups),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              for (final group in groups)
                ProxyGroupView(
                  key: _keyMap.updateCacheValue(
                    group.name,
                    () => GlobalObjectKey<_ProxyGroupViewState>(group.name),
                  ),
                  group: group,
                  columns: state.columns,
                  cardType: state.proxyCardType,
                  mode: mode,
                  listMode: widget.listMode,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProxyGroupView extends ConsumerStatefulWidget {
  final Group group;
  final int columns;
  final ProxyCardType cardType;
  final ProxiesGroupMode mode;
  final bool listMode;

  const ProxyGroupView({
    super.key,
    required this.group,
    required this.columns,
    required this.cardType,
    required this.mode,
    this.listMode = false,
  });

  @override
  ConsumerState<ProxyGroupView> createState() => _ProxyGroupViewState();
}

class _ProxyGroupViewState extends ConsumerState<ProxyGroupView> {
  late final ScrollController _controller;
  final Map<String, bool> _toggled = {};
  List<ProxySection> _sections = const [];
  Map<String, double> _sectionOffsets = const {};

  List<Proxy> currentProxies = [];
  String? testUrl;
  Timer? _navHideTimer;
  bool _navVisible = false;

  static const _rowHeight = 48.0;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  void _showNav() {
    _navHideTimer?.cancel();
    if (!_navVisible) {
      setState(() => _navVisible = true);
    }
  }

  void _scheduleHideNav() {
    _navHideTimer?.cancel();
    _navHideTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && _navVisible) {
        setState(() => _navVisible = false);
      }
    });
  }

  PageStorageKey _getPageStorageKey() {
    final profile = globalState.container.read(currentProfileProvider);
    final key =
        '${profile?.id}_${ScrollPositionCacheKey.proxiesTabList.name}_${widget.group.name}';
    return ProxiesTabView.pageListStoreMap.updateCacheValue(
      key,
      () => PageStorageKey(key),
    );
  }

  @override
  void dispose() {
    _navHideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool _isExpanded(ProxySection section) {
    if (!section.collapsible) {
      return true;
    }
    return _toggled[section.id] ?? section.expandedByDefault;
  }

  double _sectionContentHeight(ProxySection section, double itemHeight) {
    if (!_isExpanded(section)) {
      return 0;
    }
    if (widget.listMode) {
      return section.proxies.length * _rowHeight;
    }
    final rows = (section.proxies.length / widget.columns).ceil();
    if (rows <= 0) {
      return 0;
    }
    return rows * itemHeight + (rows - 1) * 8;
  }

  void _scrollToSelected() {
    final selectedName = ref.read(
      selectedProxyNameProvider(widget.group.name),
    );
    if (selectedName == null || selectedName.isEmpty) {
      return;
    }
    final index = _sections.indexWhere(
      (section) => section.proxies.any((proxy) => proxy.name == selectedName),
    );
    if (index == -1) {
      return;
    }
    final section = _sections[index];
    if (section.collapsible && !_isExpanded(section)) {
      setState(() {
        _toggled[section.id] = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelected();
      });
      return;
    }
    if (!_controller.hasClients) {
      return;
    }
    final itemHeight = getItemHeight(widget.cardType);
    final proxyIndex = section.proxies.indexWhere(
      (proxy) => proxy.name == selectedName,
    );
    final row = proxyIndex == -1 ? 0 : (proxyIndex / widget.columns).floor();
    final contentOffset = widget.listMode
        ? (proxyIndex == -1 ? 0 : proxyIndex * _rowHeight)
        : row * (itemHeight + 8);
    final offset =
        (_sectionOffsets[section.id] ?? 0) +
        (section.title != null ? _sectionHeaderHeight + _sectionGap : 0) +
        contentOffset;
    _controller.animateTo(
      offset.clamp(0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  void scrollToSelected() {
    _scrollToSelected();
  }

  Map<String, double> _computeSectionOffsets(
    List<ProxySection> sections,
    double itemHeight,
  ) {
    final offsets = <String, double>{};
    var offset = 16.0;
    for (final section in sections) {
      offsets[section.id] = offset;
      if (section.title != null) {
        offset += _sectionHeaderHeight + _sectionGap;
      }
      offset += _sectionContentHeight(section, itemHeight);
      offset += _sectionGap;
    }
    return offsets;
  }

  Widget _buildSectionNav(BuildContext context) {
    final sections = _sections
        .where((section) => section.title != null)
        .toList();
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return AnimatedOpacity(
      opacity: _navVisible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !_navVisible,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = _controller.hasClients ? _controller.offset : 0.0;
            var activeIndex = 0;
            for (var i = 0; i < sections.length; i++) {
              final sectionOffset = _sectionOffsets[sections[i].id] ?? 0;
              if (offset >= sectionOffset - 12) {
                activeIndex = i;
              }
            }
            return Container(
              width: 92,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              decoration: BoxDecoration(
                color: DashboardPalette.surface(
                  context,
                ).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: quanX.separator),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < sections.length; i++)
                      _SectionNavItem(
                        label: sections[i].title ?? '',
                        selected: i == activeIndex,
                        onTap: () {
                          if (!_controller.hasClients) {
                            return;
                          }
                          final target = _sectionOffsets[sections[i].id] ?? 0;
                          _controller.animateTo(
                            target.clamp(
                              0,
                              _controller.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final proxies = group.all;
    testUrl = group.testUrl;
    currentProxies = proxies;
    final usage = ref.watch(nodeUsageProvider);
    final l10n = context.appLocalizations;
    final sections = buildProxySections(
      proxies: proxies,
      mode: widget.mode,
      usage: usage,
      otherRegionLabel: l10n.proxiesOtherRegion,
      recentLabel: l10n.proxiesRecent,
      frequentLabel: l10n.proxiesFrequent,
      providerInfoLabel: l10n.proxiesProviderInfo,
    );
    _sections = sections;
    final itemHeight = getItemHeight(widget.cardType);
    _sectionOffsets = _computeSectionOffsets(sections, itemHeight);
    return CommonScrollBar(
      controller: _controller,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification ||
                  notification is ScrollUpdateNotification) {
                _showNav();
              } else if (notification is ScrollEndNotification) {
                _scheduleHideNav();
              }
              return false;
            },
            child: CustomScrollView(
              key: _getPageStorageKey(),
              controller: _controller,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                for (final section in sections) ...[
                  if (section.title != null)
                    SliverToBoxAdapter(
                      child: _ProxySectionHeader(
                        section: section,
                        expanded: _isExpanded(section),
                        onToggle: section.collapsible
                            ? () {
                                setState(() {
                                  _toggled[section.id] = !_isExpanded(section);
                                });
                              }
                            : null,
                      ),
                    ),
                  if (_isExpanded(section))
                    if (widget.listMode)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList.builder(
                          itemCount: section.proxies.length,
                          itemBuilder: (_, index) {
                            final proxy = section.proxies[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: ProxyRow(
                                key: ValueKey(
                                  '${section.id}.${proxy.name}',
                                ),
                                testUrl: group.testUrl,
                                groupType: group.type,
                                proxy: proxy,
                                groupName: group.name,
                              ),
                            );
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: widget.columns,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                mainAxisExtent: itemHeight,
                              ),
                          itemCount: section.proxies.length,
                          itemBuilder: (_, index) {
                            final proxy = section.proxies[index];
                            return ProxyCard(
                              testUrl: group.testUrl,
                              groupType: group.type,
                              type: widget.cardType,
                              proxy: proxy,
                              groupName: group.name,
                              key: ValueKey('${section.id}.${proxy.name}'),
                            );
                          },
                        ),
                      ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _sectionGap),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
          Positioned(
            right: 6,
            top: 12,
            bottom: 12,
            child: _buildSectionNav(context),
          ),
        ],
      ),
    );
  }
}

class _SectionNavItem extends StatelessWidget {
  const _SectionNavItem({
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
    return Material(
      color: selected
          ? DashboardPalette.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 9.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? DashboardPalette.primary
                  : quanX.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProxySectionHeader extends StatelessWidget {
  const _ProxySectionHeader({
    required this.section,
    required this.expanded,
    this.onToggle,
  });

  final ProxySection section;
  final bool expanded;
  final VoidCallback? onToggle;

  (IconData, Color) get _icon {
    return switch (section.id) {
      'recent' => (QuanXIcons.clock, DashboardPalette.blue),
      'frequent' => (QuanXIcons.star, DashboardPalette.orange),
      'provider-info' => (QuanXIcons.info, DashboardPalette.purple),
      _ => (QuanXIcons.globe, DashboardPalette.primary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final (icon, color) = _icon;
    final flag = section.flag;
    final title = section.title ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, _sectionGap),
      child: SizedBox(
        height: _sectionHeaderHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: [
                  if (flag != null && flag.isNotEmpty)
                    SizedBox(
                      width: 26,
                      child: EmojiText(
                        flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    DashboardIconTile(icon: icon, color: color, size: 26),
                  const SizedBox(width: 8),
                  Flexible(
                    child: EmojiText(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: quanX.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: quanX.separator),
                    ),
                    child: Text(
                      '${section.proxies.length}',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w600,
                        color: quanX.textTertiary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onToggle != null)
                    AnimatedRotation(
                      turns: expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        QuanXIcons.chevronRight,
                        size: 18,
                        color: quanX.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DelayTestButton extends StatefulWidget {
  final Future Function() onClick;

  const DelayTestButton({super.key, required this.onClick});

  @override
  State<DelayTestButton> createState() => _DelayTestButtonState();
}

class _DelayTestButtonState extends State<DelayTestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Future<void> _healthcheck() async {
    if (_controller.isAnimating) {
      return;
    }
    _controller.forward();
    await widget.onClick();
    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: (_, child) {
        return FadeTransition(
          opacity: _animation,
          child: ScaleTransition(scale: _animation, child: child),
        );
      },
      child: CommonFloatingActionButton(
        onPressed: _healthcheck,
        label: appLocalizations.delayTest,
        icon: const Icon(QuanXIcons.radar),
      ),
    );
  }
}
