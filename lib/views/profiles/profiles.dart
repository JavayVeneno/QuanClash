import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/dashboard/widgets/dashboard_style.dart';
import 'package:fl_clash/views/profiles/edit.dart';
import 'package:fl_clash/views/profiles/overwrite/overwrite.dart';
import 'package:fl_clash/views/profiles/preview.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilesView extends StatefulWidget {
  const ProfilesView({super.key});

  @override
  State<ProfilesView> createState() => _ProfilesViewState();
}

class _ProfilesViewState extends State<ProfilesView> {
  final GlobalKey<ProfilesCarouselState> _carouselKey = GlobalKey();

  Widget _buildFAB() {
    return CommonFloatingActionButton(
      onPressed: () => _carouselKey.currentState?.startAdd(),
      icon: const Icon(QuanXIcons.plus),
      label: context.appLocalizations.addProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (_, ref, _) {
        final appLocalizations = context.appLocalizations;
        final isLoading = ref.watch(loadingProvider(LoadingTag.profiles));
        final state = ref.watch(profilesStateProvider);
        final background = DashboardPalette.background(context);
        return CommonScaffold(
          hideTitle: true,
          isLoading: isLoading,
          backgroundColor: background,
          appBarBackgroundColor: background,
          showAppBarDivider: false,
          title: appLocalizations.profiles,
          floatingActionButton: _buildFAB(),
          body: ProfilesCarousel(
            key: _carouselKey,
            profiles: state.profiles,
            currentProfileId: state.currentProfileId,
          ),
        );
      },
    );
  }
}

/// 配置页的堆叠轮播。
///
/// 当前卡片居中并展开摘要，左右各露出前一张 / 后一张；支持点击两侧卡片、
/// 左右按钮和鼠标拖动切换，3 个以上配置时首尾循环。
class ProfilesCarousel extends ConsumerStatefulWidget {
  final List<Profile> profiles;
  final int? currentProfileId;

  const ProfilesCarousel({
    super.key,
    required this.profiles,
    required this.currentProfileId,
  });

  @override
  ConsumerState<ProfilesCarousel> createState() => ProfilesCarouselState();
}

class ProfilesCarouselState extends ConsumerState<ProfilesCarousel> {
  int _currentIndex = 0;
  int? _focusedProfileId;
  bool _expanded = false;
  bool _editing = false;
  Set<int> _snapIds = const {};
  Profile? _draft;

  List<Profile> get _displayProfiles =>
      [?_draft, ...widget.profiles];

  @override
  void initState() {
    super.initState();
    final activeIndex = widget.profiles.indexWhere(
      (profile) => profile.id == widget.currentProfileId,
    );
    _currentIndex = activeIndex == -1 ? 0 : activeIndex;
    _focusedProfileId = widget.profiles.isEmpty
        ? null
        : widget.profiles[_currentIndex].id;
  }

  @override
  void didUpdateWidget(covariant ProfilesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final display = _displayProfiles;
    if (display.isEmpty) {
      return;
    }
    if (_draft != null) {
      _currentIndex = display.indexWhere(
        (profile) => profile.id == _draft!.id,
      );
      if (_currentIndex == -1) {
        _currentIndex = 0;
      }
      _focusedProfileId = _draft!.id;
      return;
    }
    var index = display.indexWhere(
      (profile) => profile.id == _focusedProfileId,
    );
    if (index == -1) {
      final activeIndex = display.indexWhere(
        (profile) => profile.id == widget.currentProfileId,
      );
      index = activeIndex == -1 ? 0 : activeIndex;
    }
    if (widget.currentProfileId != oldWidget.currentProfileId) {
      final activeIndex = display.indexWhere(
        (profile) => profile.id == widget.currentProfileId,
      );
      if (activeIndex != -1 && activeIndex != index) {
        index = activeIndex;
      }
    }
    _currentIndex = index;
    _focusedProfileId = display[index].id;
  }

  void startAdd() {
    if (_draft != null) {
      return;
    }
    setState(() {
      _draft = const Profile(
        id: -1,
        label: '',
        url: '',
        autoUpdate: true,
        autoUpdateDuration: Duration(hours: 24),
      );
      _currentIndex = 0;
      _focusedProfileId = -1;
      _expanded = true;
      _editing = true;
    });
  }

  void _cancelDraft() {
    if (_draft == null) {
      return;
    }
    setState(() {
      _draft = null;
      _editing = false;
      _expanded = false;
      final activeIndex = widget.profiles.indexWhere(
        (profile) => profile.id == widget.currentProfileId,
      );
      _currentIndex = activeIndex == -1 ? 0 : activeIndex;
      _focusedProfileId = widget.profiles.isEmpty
          ? null
          : widget.profiles[_currentIndex].id;
    });
  }

  Future<void> _saveDraft(
    String name,
    String url,
    bool autoUpdate,
    Duration duration,
  ) async {
    final l10n = context.appLocalizations;
    final profile = Profile.normal(
      label: name,
      url: url,
    ).copyWith(autoUpdate: autoUpdate, autoUpdateDuration: duration);
    final created = await globalState.loadingRun<Profile>(() async {
      return profile.update();
    }, tag: LoadingTag.profiles, title: l10n.addProfile);
    if (created == null || !mounted) {
      return;
    }
    ref.read(profilesActionProvider.notifier).putProfile(created);
    final profiles = ref.read(profilesProvider);
    final index = profiles.indexWhere((item) => item.id == created.id);
    setState(() {
      _draft = null;
      _editing = false;
      _expanded = false;
      _focusedProfileId = created.id;
      _currentIndex = index == -1 ? 0 : index;
    });
  }

  Future<void> _importFile() async {
    final before = ref.read(profilesProvider).length;
    await ref.read(profilesActionProvider.notifier).addProfileFormFile();
    if (!mounted) {
      return;
    }
    final profiles = ref.read(profilesProvider);
    if (profiles.length == before || profiles.isEmpty) {
      return;
    }
    final last = profiles.last;
    setState(() {
      _draft = null;
      _editing = false;
      _expanded = false;
      _focusedProfileId = last.id;
      _currentIndex = profiles.length - 1;
    });
  }

  int _circular(int distance, int count) {
    if (count < 3) {
      return distance;
    }
    var value = distance;
    while (value > count / 2) {
      value -= count;
    }
    while (value < -count / 2) {
      value += count;
    }
    return value;
  }

  void _goTo(int index) {
    final display = _displayProfiles;
    final count = display.length;
    if (count == 0) {
      return;
    }
    final target = count >= 3
        ? ((index % count) + count) % count
        : index.clamp(0, count - 1);
    if (target == _currentIndex) {
      return;
    }
    final snaps = <int>{};
    if (count >= 3) {
      for (var i = 0; i < count; i++) {
        final oldDistance = _circular(i - _currentIndex, count);
        final newDistance = _circular(i - target, count);
        if ((newDistance - oldDistance).abs() > count / 2) {
          snaps.add(display[i].id);
        }
      }
    }
    setState(() {
      _currentIndex = target;
      _focusedProfileId = display[target].id;
      _expanded = false;
      _editing = false;
      _snapIds = snaps;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _snapIds = const {});
      }
    });
  }

  void _toggleExpand() {
    setState(() {
      _expanded = !_expanded;
      if (!_expanded) {
        _editing = false;
      }
    });
  }

  void _startEdit() {
    setState(() {
      _expanded = true;
      _editing = true;
    });
  }

  void _endEdit() {
    if (_draft != null) {
      _cancelDraft();
      return;
    }
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_expanded || _draft != null) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -180) {
      _goTo(_currentIndex + 1);
    } else if (velocity > 180) {
      _goTo(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final display = _displayProfiles;
    if (display.isEmpty) {
      return Center(
        child: NullStatus(
          label: l10n.nullProfileDesc,
          illustration: const ProfileEmptyIllustration(),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _CarouselMetrics.of(constraints.maxWidth);
        final entries = <_CardEntry>[];
        for (var i = 0; i < display.length; i++) {
          entries.add(
            _CardEntry(
              index: i,
              distance: _circular(i - _currentIndex, display.length),
              profile: display[i],
            ),
          );
        }
        entries.sort(
          (a, b) => b.distance.abs().compareTo(a.distance.abs()),
        );
        final minHeight = constraints.hasBoundedHeight
            ? max(0.0, constraints.maxHeight)
            : 0.0;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _handleDragEnd,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  height: metrics.stackHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final entry in entries)
                        _buildPositionedCard(entry, metrics),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionedCard(_CardEntry entry, _CarouselMetrics metrics) {
    final profile = entry.profile;
    final distance = entry.distance;
    final abs = distance.abs();
    final isMain = distance == 0;
    final isDraft = _draft != null && profile.id == _draft!.id;
    final isExpanded = isMain && (isDraft || _expanded);
    final isEditing = isMain && (isDraft || _editing);
    final isSide = abs == 1;
    final visible = abs <= 2;
    final dimmed = _expanded && !isMain;
    final x = isMain
        ? 0.0
        : distance.sign *
              (isSide ? metrics.sideOffset : metrics.farOffset) *
              (dimmed ? 1.45 : 1.0);
    final scale = isMain ? 1.0 : (isSide ? 0.84 : 0.74);
    final opacity = isMain
        ? 1.0
        : (isSide ? 0.55 : 0.12) * (dimmed ? 0.22 : 1.0);
    final blur = isMain ? 0.0 : (isSide ? 1.1 : 2.4) + (dimmed ? 0.6 : 0.0);
    final width = isMain && isExpanded
        ? metrics.expandedWidth
        : metrics.cardWidth;
    final height = isMain && isExpanded
        ? metrics.expandedHeight
        : metrics.cardHeight;
    final left = metrics.viewportWidth / 2 + x - width / 2;
    final top = isMain
        ? (isExpanded ? metrics.topExpanded : metrics.topCollapsed)
        : metrics.topCollapsed;
    final duration = _snapIds.contains(profile.id)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    return AnimatedPositioned(
      key: ValueKey('profile-card-${profile.id}'),
      duration: duration,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: width,
      height: height,
      child: IgnorePointer(
        ignoring: !visible || abs > 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 350),
          opacity: visible ? opacity : 0,
          child: AnimatedScale(
            duration: duration,
            curve: Curves.easeOutCubic,
            scale: scale,
            child: _AnimatedBlur(
              sigma: blur,
              child: _ProfileCard(
                profile: profile,
                isMain: isMain,
                isDraft: isDraft,
                expanded: isExpanded,
                editing: isEditing,
                right: distance > 0,
                collapsedHeight: metrics.cardHeight,
                coverExpanded: metrics.coverExpanded,
                onTap: isMain
                    ? (isDraft ? () {} : _toggleExpand)
                    : () => _goTo(entry.index),
                onStartEdit: isMain && !isDraft ? _startEdit : null,
                onEndEdit: _endEdit,
                onCreateDraft: _saveDraft,
                onCancelDraft: _cancelDraft,
                onImportFile: _importFile,
              ),
            ),
          ),
        ),
      ),
    );
  }


}

class _CardEntry {
  final int index;
  final int distance;
  final Profile profile;

  const _CardEntry({
    required this.index,
    required this.distance,
    required this.profile,
  });
}

class _CarouselMetrics {
  final double viewportWidth;
  final double cardWidth;
  final double cardHeight;
  final double expandedWidth;
  final double expandedHeight;
  final double coverExpanded;
  final double sideOffset;
  final double farOffset;
  final double topCollapsed;
  final double topExpanded;
  final double stackHeight;

  const _CarouselMetrics({
    required this.viewportWidth,
    required this.cardWidth,
    required this.cardHeight,
    required this.expandedWidth,
    required this.expandedHeight,
    required this.coverExpanded,
    required this.sideOffset,
    required this.farOffset,
    required this.topCollapsed,
    required this.topExpanded,
    required this.stackHeight,
  });

  factory _CarouselMetrics.of(double maxWidth) {
    final compact = maxWidth < 760;
    final cardWidth = compact ? min(maxWidth - 40, 400.0) : 440.0;
    final cardHeight = compact ? 280.0 : 300.0;
    final expandedWidth = compact ? maxWidth - 24 : min(800.0, maxWidth - 48);
    final expandedHeight = compact ? 560.0 : 530.0;
    final coverExpanded = compact ? 230.0 : 250.0;
    final sideOffset = compact
        ? cardWidth * 0.58
        : min(340.0, maxWidth * 0.215);
    final farOffset = sideOffset * 1.7;
    final topCollapsed = compact ? 40.0 : 60.0;
    final topExpanded = compact ? 16.0 : 20.0;
    return _CarouselMetrics(
      viewportWidth: maxWidth,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      expandedWidth: expandedWidth,
      expandedHeight: expandedHeight,
      coverExpanded: coverExpanded,
      sideOffset: sideOffset,
      farOffset: farOffset,
      topCollapsed: topCollapsed,
      topExpanded: topExpanded,
      stackHeight: expandedHeight + topExpanded + 30,
    );
  }
}

class _ProfileCardData {
  final bool active;
  final bool isUrl;
  final bool hasTraffic;
  final int used;
  final int total;
  final double usedPercent;
  final double remainingPercent;
  final DateTime? expireDate;
  final int? daysLeft;
  final int? nodeCount;
  final Group? group;
  final String? currentNode;
  final String autoUpdateText;

  const _ProfileCardData({
    required this.active,
    required this.isUrl,
    required this.hasTraffic,
    required this.used,
    required this.total,
    required this.usedPercent,
    required this.remainingPercent,
    required this.expireDate,
    required this.daysLeft,
    required this.nodeCount,
    required this.group,
    required this.currentNode,
    required this.autoUpdateText,
  });

  factory _ProfileCardData.from({
    required Profile profile,
    required bool active,
    required List<Group> groups,
    required AppLocalizations l10n,
  }) {
    final isUrl = profile.type == ProfileType.url;
    final info = profile.subscriptionInfo;
    final total = info?.total ?? 0;
    final used = (info?.upload ?? 0) + (info?.download ?? 0);
    final hasTraffic = total > 0;
    final usedPercent = hasTraffic
        ? (used / total * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    final expire = info?.expire ?? 0;
    final expireDate = expire > 0
        ? DateTime.fromMillisecondsSinceEpoch(expire * 1000)
        : null;
    final daysLeft = expireDate == null
        ? null
        : max(0, expireDate.difference(DateTime.now()).inDays);
    final nodeCount = active ? _countNodes(groups) : null;
    final group = active
        ? _currentGroup(groups, profile.currentGroupName)
        : null;
    return _ProfileCardData(
      active: active,
      isUrl: isUrl,
      hasTraffic: hasTraffic,
      used: used,
      total: total,
      usedPercent: usedPercent,
      remainingPercent: hasTraffic ? 100 - usedPercent : 0,
      expireDate: expireDate,
      daysLeft: daysLeft,
      nodeCount: nodeCount,
      group: group,
      currentNode: group?.now,
      autoUpdateText: _autoUpdateText(profile, l10n),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  final Profile profile;
  final bool isMain;
  final bool isDraft;
  final bool expanded;
  final bool editing;
  final bool right;
  final double collapsedHeight;
  final double coverExpanded;
  final VoidCallback onTap;
  final VoidCallback? onStartEdit;
  final VoidCallback onEndEdit;
  final Future<void> Function(
    String name,
    String url,
    bool autoUpdate,
    Duration duration,
  )?
  onCreateDraft;
  final VoidCallback? onCancelDraft;
  final VoidCallback? onImportFile;

  const _ProfileCard({
    required this.profile,
    required this.isMain,
    required this.isDraft,
    required this.expanded,
    required this.editing,
    required this.right,
    required this.collapsedHeight,
    required this.coverExpanded,
    required this.onTap,
    required this.onStartEdit,
    required this.onEndEdit,
    this.onCreateDraft,
    this.onCancelDraft,
    this.onImportFile,
  });

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  bool _showUrl = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final active =
        !widget.isDraft &&
        ref.watch(currentProfileIdProvider) == widget.profile.id;
    final groups = active ? ref.watch(groupsProvider) : const <Group>[];
    final data = _ProfileCardData.from(
      profile: widget.profile,
      active: active,
      groups: groups,
      l10n: l10n,
    );
    final coverHeight = widget.expanded
        ? (widget.isDraft ? 170.0 : widget.coverExpanded)
        : widget.collapsedHeight;
    final radius = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark
                  ? 0.42
                  : widget.isMain
                  ? 0.16
                  : 0.10,
            ),
            blurRadius: widget.isMain ? 34 : 24,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: DashboardPalette.surface(context),
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: widget.collapsedHeight,
                    end: coverHeight,
                  ),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (_, height, child) {
                    return SizedBox(height: height, child: child);
                  },
                  child: _buildCover(context, l10n, data, quanX),
                ),
                if (widget.expanded)
                  Expanded(child: _buildDetails(context, l10n, data, quanX)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(
    BuildContext context,
    AppLocalizations l10n,
    _ProfileCardData data,
    QuanXColors quanX,
  ) {
    final profile = widget.profile;
    final right = widget.right;
    if (widget.isDraft) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                  label: l10n.profileNew,
                  color: DashboardPalette.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              profile.label.isEmpty ? l10n.addProfile : profile.realLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.profileDraftHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: quanX.textTertiary,
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }
    final isUrl = profile.type == ProfileType.url;
    final typeLabel = isUrl
        ? l10n.profileSubscription
        : l10n.profileLocalFile;
    return Padding(
      padding: EdgeInsets.fromLTRB(right ? 18 : 22, 18, right ? 22 : 18, 0),
      child: Column(
        crossAxisAlignment: right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  alignment: right ? WrapAlignment.end : WrapAlignment.start,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(
                      label: typeLabel,
                      color: isUrl
                          ? DashboardPalette.primary
                          : DashboardPalette.blue,
                    ),
                    _Badge(
                      label: data.active
                          ? l10n.profileActive
                          : l10n.profileInactive,
                      color: data.active
                          ? DashboardPalette.green
                          : quanX.textTertiary,
                      dot: data.active,
                    ),
                  ],
                ),
              ),
              if (widget.isMain && !widget.isDraft) ...[
                const SizedBox(width: 4),
                _IconAction(
                  icon: QuanXIcons.pencil,
                  tooltip: l10n.edit,
                  onPressed: widget.onStartEdit,
                ),
                const SizedBox(width: 2),
                _buildMoreMenu(context, l10n),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            profile.realLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: right ? WrapAlignment.end : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 3,
            children: [
              LastUpdateTimeText(
                lastUpdateDate: profile.lastUpdateDate,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
              _Dot(color: quanX.textTertiary),
              Text(
                isUrl ? l10n.profileRemote : l10n.profileLocalFile,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
              if (data.nodeCount != null) ...[
                _Dot(color: quanX.textTertiary),
                Text(
                  l10n.profileNodeCountValue(data.nodeCount!),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: quanX.textTertiary,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          _buildBody(context, l10n, data, quanX),
          if (widget.isMain && !widget.isDraft) _buildFoot(context, l10n, quanX),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    _ProfileCardData data,
    QuanXColors quanX,
  ) {
    final right = widget.right;
    if (!data.isUrl) {
      final tile = Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: DashboardPalette.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Icon(
          QuanXIcons.fileText,
          size: 24,
          color: DashboardPalette.primary,
        ),
      );
      final info = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileLocalYaml,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.profileNodeCountValue(data.nodeCount ?? 0)} · ${_lastUpdateText(context, l10n)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodySmall?.copyWith(
              color: quanX.textTertiary,
            ),
          ),
        ],
      );
      return Row(
        mainAxisAlignment: right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: right
            ? [Flexible(child: info), const SizedBox(width: 12), tile]
            : [tile, const SizedBox(width: 12), Flexible(child: info)],
      );
    }
    if (!data.hasTraffic) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: quanX.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: quanX.separator),
        ),
        child: Row(
          mainAxisAlignment: right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(QuanXIcons.info, size: 14, color: quanX.textTertiary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.profileNoTrafficInfo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final ring = _RemainingRing(
      percent: data.remainingPercent,
      label: l10n.profileRemainingTraffic,
      size: 86,
    );
    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileUsedPercent(data.usedPercent.toStringAsFixed(1)),
          style: context.textTheme.bodySmall?.copyWith(
            color: quanX.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${data.used.traffic.show} / ${data.total.traffic.show}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${l10n.profileExpire} ${data.expireDate == null ? l10n.infiniteTime : _formatDate(data.expireDate!)} · ${data.expireDate == null ? l10n.infiniteTime : l10n.profileDaysLeftShort(data.daysLeft ?? 0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: quanX.textTertiary,
          ),
        ),
      ],
    );
    return Row(
      mainAxisAlignment: right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: right
          ? [Flexible(child: info), const SizedBox(width: 14), ring]
          : [ring, const SizedBox(width: 14), Flexible(child: info)],
    );
  }

  Widget _buildFoot(
    BuildContext context,
    AppLocalizations l10n,
    QuanXColors quanX,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: quanX.separator)),
      ),
      child: Row(
        children: [
          Text(
            widget.expanded ? l10n.profileCollapse : l10n.profileTapToExpand,
            style: context.textTheme.labelSmall?.copyWith(
              color: quanX.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          AnimatedRotation(
            turns: widget.expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              QuanXIcons.chevronDown,
              size: 14,
              color: quanX.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, AppLocalizations l10n) {
    return CommonPopupBox(
      targetBuilder: (open) {
        return _IconAction(
          icon: QuanXIcons.ellipsisVertical,
          onPressed: () => open(offset: const Offset(0, 12)),
        );
      },
      popup: CommonPopupMenu(
        minWidth: 170,
        items: [
          PopupMenuItemData(
            icon: QuanXIcons.eye,
            label: l10n.preview,
            onPressed: _preview,
          ),
          if (widget.profile.type == ProfileType.url)
            PopupMenuItemData(
              icon: QuanXIcons.copy,
              label: l10n.copyLink,
              onPressed: _copyLink,
            ),
          PopupMenuItemData(
            icon: QuanXIcons.copy,
            label: l10n.exportFile,
            onPressed: _exportFile,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    AppLocalizations l10n,
    _ProfileCardData data,
    QuanXColors quanX,
  ) {
    if (widget.editing || widget.isDraft) {
      return _ProfileEditForm(
        key: ValueKey('profile-edit-${widget.profile.id}'),
        profile: widget.profile,
        isDraft: widget.isDraft,
        onSave: widget.isDraft ? widget.onCreateDraft! : _saveInline,
        onCancel: widget.isDraft ? widget.onCancelDraft! : widget.onEndEdit,
        onOpenEditor: widget.isDraft ? null : _openEditor,
        onImportFile: widget.isDraft ? widget.onImportFile : null,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.hasTraffic) ...[
            _UsageOverview(
              used: data.used,
              total: data.total,
              usedPercent: data.usedPercent,
              expireDate: data.expireDate,
              daysLeft: data.daysLeft,
              lastUpdateDate: widget.profile.lastUpdateDate,
              l10n: l10n,
            ),
            const SizedBox(height: 10),
          ],
          _buildStats(context, l10n, data, quanX),
          const SizedBox(height: 10),
          _buildSource(context, l10n, quanX),
          const SizedBox(height: 8),
          _buildActions(context, l10n, data, quanX),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    AppLocalizations l10n,
    _ProfileCardData data,
    QuanXColors quanX,
  ) {
    final tiles = <Widget>[
      _StatTile(
        icon: QuanXIcons.globe,
        color: DashboardPalette.primary,
        label: l10n.profileNodeCount,
        value: data.nodeCount?.toString() ?? '—',
      ),
      _StatTile(
        icon: QuanXIcons.locate,
        color: DashboardPalette.green,
        label: l10n.profileCurrentNode,
        value: data.currentNode ?? '—',
      ),
      _StatTile(
        icon: QuanXIcons.list,
        color: DashboardPalette.blue,
        label: l10n.profileStrategyGroup,
        value: data.group?.name ?? '—',
      ),
      _StatTile(
        icon: QuanXIcons.clock,
        color: DashboardPalette.orange,
        label: l10n.profileAutoUpdate,
        value: data.autoUpdateText,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 520) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i != 0) const SizedBox(width: 8),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  Widget _buildSource(
    BuildContext context,
    AppLocalizations l10n,
    QuanXColors quanX,
  ) {
    final isUrl = widget.profile.type == ProfileType.url;
    final masked = isUrl && !_showUrl;
    return _SourceStrip(
      icon: isUrl ? QuanXIcons.link : QuanXIcons.fileText,
      label: isUrl ? l10n.profileSubscriptionUrl : l10n.profileLocalFile,
      value: isUrl
          ? (masked ? _maskUrl(widget.profile.url) : widget.profile.url)
          : widget.profile.realLabel,
      actionLabel: isUrl ? l10n.copy : l10n.profileReplaceFile,
      onAction: isUrl ? _copyLink : _openEditor,
      mono: isUrl,
      quanX: quanX,
      masked: masked,
      onToggleMask: isUrl
          ? () => setState(() => _showUrl = !_showUrl)
          : null,
    );
  }

  Widget _buildActions(
    BuildContext context,
    AppLocalizations l10n,
    _ProfileCardData data,
    QuanXColors quanX,
  ) {
    final isUrl = widget.profile.type == ProfileType.url;
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (data.active)
          _ActionButton(
            icon: QuanXIcons.check,
            label: l10n.profileCurrentConfig,
            kind: _ActionKind.soft,
            onPressed: null,
          )
        else
          _ActionButton(
            icon: QuanXIcons.check,
            label: l10n.profileSetCurrent,
            kind: _ActionKind.primary,
            onPressed: _setCurrent,
          ),
        if (isUrl)
          Consumer(
            builder: (context, ref, _) {
              final updating = ref.watch(
                isUpdatingProvider(widget.profile.updatingKey),
              );
              return _ActionButton(
                icon: QuanXIcons.refreshCw,
                label: l10n.profileUpdateNow,
                kind: _ActionKind.ghost,
                loading: updating,
                onPressed: updating ? null : _updateProfile,
              );
            },
          )
        else
          _ActionButton(
            icon: QuanXIcons.fileText,
            label: l10n.profileReplaceFile,
            kind: _ActionKind.ghost,
            onPressed: _openEditor,
          ),
        _TextAction(
          icon: QuanXIcons.puzzle,
          label: l10n.override,
          onPressed: _openOverwrite,
          quanX: quanX,
        ),
        _TextAction(
          icon: QuanXIcons.trash2,
          label: l10n.delete,
          onPressed: _delete,
          danger: true,
          quanX: quanX,
        ),
      ],
    );
  }

  String _lastUpdateText(BuildContext context, AppLocalizations l10n) {
    return widget.profile.lastUpdateDate?.getLastUpdateTimeDesc(context) ??
        l10n.unknown;
  }

  void _setCurrent() {
    ref.read(currentProfileIdProvider.notifier).value = widget.profile.id;
  }

  Future<void> _updateProfile() async {
    await globalState.loadingRun(() async {
      await ref
          .read(profilesActionProvider.notifier)
          .updateProfile(widget.profile, showLoading: true);
    }, tag: LoadingTag.profiles);
  }

  Future<void> _saveInline(
    String name,
    String url,
    bool autoUpdate,
    Duration duration,
  ) async {
    final profile = widget.profile;
    final updated = profile.copyWith(
      label: name,
      url: url,
      autoUpdate: autoUpdate,
      autoUpdateDuration: duration,
    );
    if (profile.url != url) {
      final ok = await globalState.safeRun<bool>(() async {
        await ref
            .read(profilesActionProvider.notifier)
            .updateProfile(updated, showLoading: true);
        return true;
      });
      if (ok == true && mounted) {
        widget.onEndEdit();
      }
      return;
    }
    ref.read(profilesActionProvider.notifier).putProfile(updated);
    if (mounted) {
      widget.onEndEdit();
    }
  }

  void _openEditor() {
    final l10n = context.appLocalizations;
    showExtend(
      context,
      builder: (_) {
        return AdaptiveSheetScaffold(
          body: EditProfileView(profile: widget.profile, context: context),
          title: l10n.edit,
        );
      },
    );
  }

  void _preview() {
    BaseNavigator.push<String>(
      context,
      PreviewProfileView(profile: widget.profile),
    );
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.profile.url));
    if (mounted) {
      context.showNotifier(context.appLocalizations.copySuccess);
    }
  }

  Future<void> _exportFile() async {
    final l10n = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      final mFile = await widget.profile.file;
      final value = await picker.saveFile(
        widget.profile.realLabel,
        mFile.readAsBytesSync(),
      );
      return value != null;
    }, title: l10n.tip);
    if (res == true && mounted) {
      context.showNotifier(l10n.exportSuccess);
    }
  }

  void _openOverwrite() {
    BaseNavigator.push(context, OverwriteView(profileId: widget.profile.id));
  }

  Future<void> _delete() async {
    final l10n = context.appLocalizations;
    final res = await globalState.showMessage(
      title: l10n.tip,
      message: TextSpan(text: l10n.deleteTip(l10n.profile)),
    );
    if (res != true) {
      return;
    }
    await ref
        .read(profilesActionProvider.notifier)
        .deleteProfile(widget.profile.id);
  }
}

class _ProfileEditForm extends StatefulWidget {
  final Profile profile;
  final Future<void> Function(
    String name,
    String url,
    bool autoUpdate,
    Duration duration,
  )
  onSave;
  final VoidCallback onCancel;
  final VoidCallback? onOpenEditor;
  final bool isDraft;
  final VoidCallback? onImportFile;

  const _ProfileEditForm({
    super.key,
    required this.profile,
    required this.onSave,
    required this.onCancel,
    this.onOpenEditor,
    this.isDraft = false,
    this.onImportFile,
  });

  @override
  State<_ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends State<_ProfileEditForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late bool _autoUpdate;
  late Duration _duration;
  bool _saving = false;

  static const _intervalOptions = <Duration>[
    Duration(hours: 6),
    Duration(hours: 12),
    Duration(hours: 24),
    Duration(hours: 48),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.label);
    _urlController = TextEditingController(text: widget.profile.url);
    _autoUpdate = widget.profile.autoUpdate;
    _duration = widget.profile.autoUpdateDuration;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final l10n = context.appLocalizations;
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (_saving) {
      return;
    }
    if (widget.isDraft && url.isEmpty) {
      globalState.showNotifier(l10n.profileUrlRequired);
      return;
    }
    if (!widget.isDraft && name.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(name, url, _autoUpdate, _duration);
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final quanX = context.quanX;
    final isUrl = widget.isDraft || widget.profile.type == ProfileType.url;
    final options = <Duration>[
      ..._intervalOptions,
      if (!_intervalOptions.contains(_duration)) _duration,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.isDraft ? l10n.addProfile : l10n.profileEditTitle,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                isUrl ? l10n.profileRemote : l10n.profileLocalFile,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EditField(
            label: l10n.name,
            child: TextField(
              controller: _nameController,
              style: context.textTheme.bodySmall,
              decoration: _inputDecoration(context),
            ),
          ),
          const SizedBox(height: 8),
          if (isUrl)
            _EditField(
              label: l10n.profileSubscriptionUrl,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontFamily: 'JetBrainsMono',
                      ),
                      decoration: _inputDecoration(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _MiniButton(
                    label: l10n.copy,
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _urlController.text),
                      );
                      if (context.mounted) {
                        context.showNotifier(l10n.copySuccess);
                      }
                    },
                  ),
                ],
              ),
            )
          else
            _EditField(
              label: l10n.profileLocalFile,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.profile.realLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (widget.onOpenEditor != null)
                    _MiniButton(
                      label: l10n.profileOpenEditor,
                      onPressed: widget.onOpenEditor!,
                    ),
                ],
              ),
            ),
          if (widget.isDraft && widget.onImportFile != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _saving ? null : widget.onImportFile,
                icon: const Icon(QuanXIcons.fileText, size: 14),
                label: Text(l10n.profileImportFile),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _EditField(
            label: l10n.profileAutoUpdate,
            child: Row(
              children: [
                Switch.adaptive(
                  value: _autoUpdate,
                  onChanged: (value) {
                    setState(() => _autoUpdate = value);
                  },
                ),
                const SizedBox(width: 8),
                DropdownButton<Duration>(
                  value: _duration,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(10),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: quanX.textPrimary,
                  ),
                  items: [
                    for (final duration in options)
                      DropdownMenuItem(
                        value: duration,
                        child: Text(_intervalLabel(l10n, duration)),
                      ),
                  ],
                  onChanged: _autoUpdate
                      ? (value) {
                          if (value == null) return;
                          setState(() => _duration = value);
                        }
                      : null,
                ),
                const Spacer(),
                Text(
                  l10n.profileUpdateInterval,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: quanX.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : widget.onCancel,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _saving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardPalette.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isDraft
                            ? l10n.addProfile
                            : l10n.profileSaveChanges,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    final quanX = context.quanX;
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: quanX.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: quanX.separator),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: quanX.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: DashboardPalette.primary.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  String _intervalLabel(AppLocalizations l10n, Duration duration) {
    if (duration.inHours >= 1) {
      return l10n.profileEveryHours(duration.inHours);
    }
    return l10n.profileEveryMinutes(duration.inMinutes);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const _Badge({required this.label, required this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RemainingRing extends StatelessWidget {
  final double percent;
  final String label;
  final double size;

  const _RemainingRing({
    required this.percent,
    required this.label,
    this.size = 86,
  });

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 7,
              strokeCap: StrokeCap.round,
              backgroundColor: DashboardPalette.primary.withValues(alpha: 0.10),
              color: DashboardPalette.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: percent.toStringAsFixed(1),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '%',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.quanX.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 8.5,
                  color: context.quanX.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageOverview extends StatelessWidget {
  final int used;
  final int total;
  final double usedPercent;
  final DateTime? expireDate;
  final int? daysLeft;
  final DateTime? lastUpdateDate;
  final AppLocalizations l10n;

  const _UsageOverview({
    required this.used,
    required this.total,
    required this.usedPercent,
    required this.expireDate,
    required this.daysLeft,
    required this.lastUpdateDate,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: DashboardPalette.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DashboardPalette.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${used.traffic.show} / ${total.traffic.show}',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                l10n.profileUsedPercent(usedPercent.toStringAsFixed(1)),
                style: context.textTheme.labelSmall?.copyWith(
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w600,
                  color: DashboardPalette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (usedPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: DashboardPalette.primary.withValues(alpha: 0.10),
              color: DashboardPalette.primary,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _MetaItem(
                label: l10n.profileExpire,
                value: Text(
                  expireDate == null
                      ? l10n.infiniteTime
                      : _formatDate(expireDate!),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: quanX.textPrimary,
                  ),
                ),
                quanX: quanX,
              ),
              _MetaItem(
                label: l10n.profileRemainingDays,
                value: Text(
                  expireDate == null
                      ? l10n.infiniteTime
                      : l10n.profileDaysCount(daysLeft ?? 0),
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                    color: quanX.textPrimary,
                  ),
                ),
                quanX: quanX,
              ),
              _MetaItem(
                label: l10n.profileLastUpdate,
                value: LastUpdateTimeText(
                  lastUpdateDate: lastUpdateDate,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: quanX.textPrimary,
                  ),
                ),
                quanX: quanX,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final Widget value;
  final QuanXColors quanX;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.quanX,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: quanX.textTertiary,
          ),
        ),
        const SizedBox(width: 4),
        value,
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: quanX.separator),
      ),
      child: Row(
        children: [
          DashboardIconTile(icon: icon, color: color, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: quanX.textTertiary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceStrip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String actionLabel;
  final VoidCallback onAction;
  final bool mono;
  final QuanXColors quanX;
  final bool masked;
  final VoidCallback? onToggleMask;

  const _SourceStrip({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    required this.onAction,
    required this.mono,
    required this.quanX,
    this.masked = false,
    this.onToggleMask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: quanX.separator),
      ),
      child: Row(
        children: [
          DashboardIconTile(
            icon: icon,
            color: DashboardPalette.primary,
            size: 26,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    color: quanX.textTertiary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: mono ? 'JetBrainsMono' : null,
                    color: quanX.textSecondary,
                    fontSize: mono ? 10 : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (onToggleMask != null)
            _IconAction(
              icon: masked ? QuanXIcons.eyeOff : QuanXIcons.eye,
              tooltip: masked
                  ? context.appLocalizations.profileShowLink
                  : context.appLocalizations.profileHideLink,
              onPressed: onToggleMask,
            ),
          const SizedBox(width: 2),
          _MiniButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}

enum _ActionKind { primary, soft, ghost }

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final _ActionKind kind;
  final bool loading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.kind,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final (background, foreground) = switch (kind) {
      _ActionKind.primary => (DashboardPalette.primary, Colors.white),
      _ActionKind.soft => (
        DashboardPalette.primary.withValues(alpha: 0.10),
        DashboardPalette.primary,
      ),
      _ActionKind.ghost => (quanX.surfaceElevated, quanX.textSecondary),
    };
    return Opacity(
      opacity: onPressed == null ? 0.62 : 1,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final QuanXColors quanX;

  const _TextAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.quanX,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? quanX.danger : quanX.textTertiary;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MiniButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Material(
      color: DashboardPalette.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: quanX.separator),
          ),
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: quanX.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final Widget child;

  const _EditField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.quanX.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _IconAction({required this.icon, this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      iconSize: 15,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: context.quanX.textTertiary,
      ),
    );
  }
}

class _AnimatedBlur extends StatelessWidget {
  final double sigma;
  final Widget child;

  const _AnimatedBlur({required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: sigma, end: sigma),
      duration: const Duration(milliseconds: 350),
      builder: (context, value, child) {
        if (value < 0.05) {
          return child!;
        }
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: value, sigmaY: value),
          child: child,
        );
      },
      child: child,
    );
  }
}

class LastUpdateTimeText extends StatelessWidget {
  final DateTime? lastUpdateDate;
  final TextStyle? style;

  const LastUpdateTimeText({
    super.key,
    required this.lastUpdateDate,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (lastUpdateDate == null) {
      return Text('', style: style);
    }
    return TickBuilder(
      duration: const Duration(minutes: 1),
      builder: (context, _) {
        return Text(
          lastUpdateDate!.getLastUpdateTimeDesc(context),
          style: style,
        );
      },
    );
  }
}

String _maskUrl(String url) {
  final uri = Uri.tryParse(url);
  final scheme = (uri != null && uri.scheme.isNotEmpty)
      ? '${uri.scheme}://'
      : '';
  return '$scheme${'•' * 24}';
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String _autoUpdateText(Profile profile, AppLocalizations l10n) {
  if (!profile.autoUpdate) {
    return l10n.profileOff;
  }
  final duration = profile.autoUpdateDuration;
  if (duration.inHours >= 1) {
    return l10n.profileEveryHours(duration.inHours);
  }
  return l10n.profileEveryMinutes(duration.inMinutes);
}

const _pseudoNodeNames = {
  'DIRECT',
  'REJECT',
  'GLOBAL',
  'PASS',
  'COMPATIBLE',
};

int _countNodes(List<Group> groups) {
  final groupNames = groups.map((group) => group.name).toSet();
  final names = <String>{};
  for (final group in groups) {
    for (final proxy in group.all) {
      final name = proxy.name;
      if (name.isEmpty || groupNames.contains(name)) {
        continue;
      }
      if (_pseudoNodeNames.contains(name.toUpperCase())) {
        continue;
      }
      names.add(name);
    }
  }
  return names.length;
}

Group? _currentGroup(List<Group> groups, String? name) {
  if (name != null && name.isNotEmpty) {
    final group = groups.getGroup(name);
    if (group != null) {
      return group;
    }
  }
  for (final group in groups) {
    if (group.type == GroupType.Selector && (group.now?.isNotEmpty ?? false)) {
      return group;
    }
  }
  return null;
}
