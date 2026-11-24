import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/pages/scan.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/access.dart';
import 'package:quanclash/views/config/config.dart';
import 'package:quanclash/views/config/rules.dart';
import 'package:quanclash/views/config/scripts.dart';
import 'package:quanclash/views/proxies/card.dart';
import 'package:quanclash/views/proxies/common.dart';
import 'package:quanclash/views/settings/settings_modals.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'theme.dart';
import 'utils.dart';

/// Opens one of the three v4 80% frosted modal bottom sheets:
/// `'proxy'`, `'config'`, or `'settings'`.
Future<void> showMobileV4Sheet(BuildContext context, String type) {
  final barrier = MobileV4Palette.of(context).sheetBarrier;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrier,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: .8,
        minChildSize: .5,
        maxChildSize: .94,
        expand: false,
        builder: (ctx, controller) {
          final p = MobileV4Palette.of(ctx);
          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MobileV4Theme.radiusSheet),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.sheetShadow,
                  blurRadius: 60,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MobileV4Theme.radiusSheet),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.sheet,
                    border: Border(
                      top: BorderSide(color: p.sheetTopBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      _SheetHead(type: type),
                      Expanded(child: _SheetBody(type, controller)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

List<Group> _visibleGroups(List<Group> groups, Mode mode) {
  return switch (mode) {
    Mode.direct => const [],
    Mode.global => groups,
    Mode.rule => groups
        .where((item) => item.hidden != true)
        .where((item) => item.name != GroupName.GLOBAL.name)
        .toList(),
  };
}

int _uniqueNodeCount(List<Group> groups) {
  final names = <String>{};
  for (final group in groups) {
    for (final proxy in group.all) {
      names.add(proxy.name);
    }
  }
  return names.length;
}

String _groupTypeDescription(GroupType type) {
  return switch (type) {
    GroupType.URLTest => '自动选择 · 延迟优先',
    GroupType.Fallback => '自动选择 · 故障转移',
    GroupType.LoadBalance => '负载均衡',
    GroupType.Relay => '链式代理',
    GroupType.Selector => '手动选择',
  };
}

String _themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '浅色',
    ThemeMode.dark => '深色',
  };
}

class _SheetHead extends ConsumerWidget {
  const _SheetHead({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final (String title, String sub) = switch (type) {
      'proxy' => () {
        final mode = ref.watch(
          patchClashConfigProvider.select((state) => state.mode),
        );
        final groups = _visibleGroups(ref.watch(groupsProvider), mode);
        final nodeCount = _uniqueNodeCount(groups);
        return ('代理', '${groups.length} 个策略组 · $nodeCount 个节点');
      }(),
      'config' => () {
        final profiles = ref.watch(profilesProvider);
        final currentId = ref.watch(currentProfileIdProvider);
        final activeCount =
            profiles.any((item) => item.id == currentId) ? 1 : 0;
        return ('配置', '${profiles.length} 个订阅 · $activeCount 个生效中');
      }(),
      _ => ('设置', 'QuanClash $appVersion'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: p.sheetHandle,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.9,
                        height: 1,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.closeBg,
                    border: Border.all(color: p.closeBorder),
                    boxShadow: p.isDark
                        ? null
                        : const [
                            BoxShadow(
                              color: Color(0x14564A80),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Icon(
                      QuanXIcons.x,
                      size: 13,
                      color: p.text2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody(this.type, this.controller);

  final String type;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      'proxy' => _ProxySheet(controller: controller),
      'config' => _ConfigSheet(controller: controller),
      _ => _SettingsSheet(controller: controller),
    };
  }
}

// ---------------------------------------------------------------------------
// Proxy Sheet
// ---------------------------------------------------------------------------

class _ProxySheet extends ConsumerWidget {
  const _ProxySheet({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final groups = _visibleGroups(ref.watch(groupsProvider), mode);
    final selectedMap = ref.watch(selectedMapProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (groups.isEmpty) {
      return ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
        children: [
          const _GroupLabel('PROXY', trailing: '0 个节点'),
          _Card(
            children: [
              _EmptyRow(
                text: mode == Mode.direct
                    ? '当前为直连模式，点击地球可切换模式'
                    : context.appLocalizations.proxiesEmpty,
              ),
            ],
          ),
        ],
      );
    }

    final children = <Widget>[];
    for (final group in groups) {
      final selectedName = group.getCurrentSelectedName(
        selectedMap[group.name] ?? '',
      );
      children.add(
        _GroupLabel(
          group.name,
          trailing: _groupTypeDescription(group.type),
          trailingIcon: QuanXIcons.zap,
          onTrailingTap: () {
            HapticFeedback.selectionClick();
            delayTest(group.all, group.testUrl);
          },
        ),
      );
      children.add(
        _Card(
          children: [
            for (final proxy in group.all)
              _ProxyRow(
                group: group,
                proxy: proxy,
                selected: selectedName == proxy.name,
                onTap: () {
                  HapticFeedback.selectionClick();
                  changeProxyForNode(ref, group.name, proxy, group.type);
                },
              ),
          ],
        ),
      );
    }

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: children,
    );
  }
}

class _ProxyRow extends ConsumerWidget {
  const _ProxyRow({
    required this.group,
    required this.proxy,
    required this.selected,
    required this.onTap,
  });

  final Group group;
  final Proxy proxy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final delay = ref.watch(
      delayProvider(proxyName: proxy.name, testUrl: group.testUrl),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.accent : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (p.isDark ? p.faint : const Color(0xFFD0D0DC)),
                    width: 1.4,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: p.accent.withValues(alpha: .35),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Center(
                        child: Icon(
                          QuanXIcons.check,
                          size: 10,
                          color: p.onAccent,
                        ),
                      )
                    : null,
              ),
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
                    if (proxy.type.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        proxy.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => proxyDelayTest(proxy, group.testUrl),
                child: _LatencyLabel(delay: delay),
              ),
            ],
          ),
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

// ---------------------------------------------------------------------------
// Config Sheet
// ---------------------------------------------------------------------------

class _ConfigSheet extends ConsumerWidget {
  const _ConfigSheet({required this.controller});

  final ScrollController controller;

  Future<void> _importFromUrl(BuildContext context) async {
    final l10n = context.appLocalizations;
    final url = await globalState.showCommonDialog<String>(
      child: InputDialog(
        autovalidateMode: AutovalidateMode.onUnfocus,
        title: l10n.importFromURL,
        labelText: l10n.url,
        value: '',
        inputFormatters: TextInputLimits.limit(TextInputLimits.url),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return l10n.emptyTip('').trim();
          }
          if (!value.isUrl) {
            return l10n.urlTip('').trim();
          }
          return null;
        },
      ),
    );
    if (url != null && url.isNotEmpty) {
      await globalState.container
          .read(profilesActionProvider.notifier)
          .addProfileFormURL(url);
    }
  }

  Future<void> _scanQrCode(BuildContext context) async {
    final url = await BaseNavigator.push<String>(context, const ScanPage());
    if (url != null && url.isNotEmpty) {
      await globalState.container
          .read(profilesActionProvider.notifier)
          .addProfileFormURL(url);
    }
  }

  Future<void> _importFromFile() async {
    await globalState.container
        .read(profilesActionProvider.notifier)
        .addProfileFormFile();
  }

  void _selectProfile(WidgetRef ref, int profileId) {
    HapticFeedback.selectionClick();
    ref.read(currentProfileIdProvider.notifier).value = profileId;
    ref
        .read(setupActionProvider.notifier)
        .applyProfileDebounce(silence: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider);
    final currentId = ref.watch(currentProfileIdProvider);
    final groups = ref.watch(groupsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final activeProfile = profiles.getProfile(currentId);
    final otherProfiles = activeProfile == null
        ? profiles
        : profiles.where((p) => p.id != activeProfile.id).toList();
    final activeNodeCount = _uniqueNodeCount(groups);

    final autoUpdateLabel = activeProfile == null
        ? '未配置'
        : !activeProfile.realAutoUpdate
            ? '已关闭'
            : '每 ${math.max(1, activeProfile.autoUpdateDuration.inHours)} 小时';

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: [
        if (activeProfile != null)
          _ActiveProfileHeroCard(
            profile: activeProfile,
            nodeCount: activeNodeCount,
            onRefresh: activeProfile.type == ProfileType.url
                ? () => ref
                    .read(profilesActionProvider.notifier)
                    .updateProfile(activeProfile)
                : null,
          ),
        _GroupLabel('订阅列表', trailing: '${profiles.length} 个'),
        if (otherProfiles.isNotEmpty)
          _Card(
            children: [
              for (final profile in otherProfiles)
                _MobileV4SettingsRow(
                  icon: profile.type == ProfileType.url
                      ? QuanXIcons.squareStack
                      : QuanXIcons.fileText,
                  title: profile.realLabel,
                  sub: profile.type == ProfileType.url ? '远程订阅' : '本地导入',
                  value: _profileSummaryValue(context, profile),
                  onTap: () => _selectProfile(ref, profile.id),
                ),
            ],
          )
        else if (activeProfile == null)
          const _Card(
            children: [
              _EmptyRow(text: '暂无订阅配置，请从下方导入'),
            ],
          )
        else
          const _Card(
            children: [
              _EmptyRow(text: '暂无其他备用订阅'),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ImportButton(
                icon: QuanXIcons.link,
                label: '从 URL 导入',
                onTap: () => _importFromUrl(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ImportButton(
                icon: QuanXIcons.qrCode,
                label: '扫描二维码',
                onTap: () => _scanQrCode(context),
              ),
            ),
          ],
        ),
        const _GroupLabel('订阅设置'),
        _Card(
          children: [
            _MobileV4SettingsRow(
              icon: QuanXIcons.refreshCw,
              title: '自动更新',
              sub: autoUpdateLabel,
              onTap: activeProfile == null ||
                      activeProfile.type != ProfileType.url
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ref.read(profilesProvider.notifier).updateProfile(
                            activeProfile.id,
                            (p) => p.copyWith(autoUpdate: !p.autoUpdate),
                          );
                    },
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.upload,
              title: '从本地文件导入',
              sub: '选择本地 YAML 配置文件',
              onTap: _importFromFile,
            ),
          ],
        ),
      ],
    );
  }

  String _profileSummaryValue(BuildContext context, Profile profile) {
    final info = profile.subscriptionInfo;
    if (info != null && info.total > 0) {
      final used = info.upload + info.download;
      final usedFmt = mobileV4FormatBytes(used);
      final totalFmt = mobileV4FormatBytes(info.total);
      return '${usedFmt.$1} / ${totalFmt.$1} ${totalFmt.$2}';
    }
    if (profile.lastUpdateDate != null) {
      return profile.lastUpdateDate!.getLastUpdateTimeDesc(context);
    }
    return '';
  }
}

class _ActiveProfileHeroCard extends StatelessWidget {
  const _ActiveProfileHeroCard({
    required this.profile,
    required this.nodeCount,
    this.onRefresh,
  });

  final Profile profile;
  final int nodeCount;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final isUrl = profile.type == ProfileType.url;
    final info = profile.subscriptionInfo;
    final total = info?.total ?? 0;
    final used = (info?.upload ?? 0) + (info?.download ?? 0);
    final hasTraffic = total > 0;
    final usedPercent = hasTraffic
        ? (used / total * 100).clamp(0.0, 100.0).toDouble()
        : 0.0;
    final usedFmt = mobileV4FormatBytes(used);
    final totalFmt = mobileV4FormatBytes(total);
    final expire = info?.expire ?? 0;
    final expireDate = expire > 0
        ? DateTime.fromMillisecondsSinceEpoch(expire * 1000)
        : null;
    final daysLeft = expireDate == null
        ? null
        : math.max(0, expireDate.difference(DateTime.now()).inDays);
    final updatedDesc = profile.lastUpdateDate?.getLastUpdateTimeDesc(context);
    final metaParts = <String>[
      isUrl ? '远程订阅' : '本地配置',
      if (nodeCount > 0) '$nodeCount 个节点',
      if (updatedDesc != null) '$updatedDesc更新',
    ];

    return _Card(
      topTint: p.heroTopTint,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRefresh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.realLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.4,
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metaParts.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p.accentSoft,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: p.accent.withValues(alpha: .18),
                        ),
                      ),
                      child: Text(
                        '生效中',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .5,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasTraffic) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        usedFmt.$1,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -.6,
                          color: p.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${usedFmt.$2} / ${totalFmt.$1} ${totalFmt.$2}',
                        style: TextStyle(
                          fontSize: 9.5,
                          color: p.muted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${usedPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: p.accent.withValues(alpha: .95),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ProgressBar(value: usedPercent / 100),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      if (expireDate != null)
                        Text(
                          '到期 ${expireDate.show} · 剩 $daysLeft 天',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: p.faint,
                          ),
                        )
                      else
                        Text(
                          '长期有效',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: p.faint,
                          ),
                        ),
                      const Spacer(),
                      if (updatedDesc != null)
                        Text(
                          '$updatedDesc更新',
                          style: TextStyle(
                            fontSize: 8.5,
                            color: p.faint,
                          ),
                        ),
                    ],
                  ),
                ] else if (onRefresh != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        QuanXIcons.refreshCw,
                        size: 11,
                        color: p.faint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '轻触卡片更新订阅',
                        style: TextStyle(
                          fontSize: 9,
                          color: p.faint,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportButton extends StatelessWidget {
  const _ImportButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: p.importBorder,
          radius: 12,
        ),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: p.importFill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: p.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: p.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dashLength = 4.5;
    const gapLength = 3.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ---------------------------------------------------------------------------
// Settings Sheet
// ---------------------------------------------------------------------------

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({required this.controller});

  final ScrollController controller;

  String _dnsSafetyLabel(BuildContext context, DnsSafetyMode mode) {
    final l10n = context.appLocalizations;
    return switch (mode) {
      DnsSafetyMode.compatible => l10n.dnsSafetyModeCompatible,
      DnsSafetyMode.proxyOnly => l10n.dnsSafetyModeProxyOnly,
      DnsSafetyMode.custom => l10n.dnsSafetyModeCustom,
    };
  }

  Future<void> _showAppearancePicker(BuildContext context) {
    final barrier = MobileV4Palette.of(context).sheetBarrier;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: barrier,
      builder: (_) => const _AppearancePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final l10n = context.appLocalizations;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final vpnProps = ref.watch(vpnSettingProvider);
    final accessControl = vpnProps.accessControlProps;
    final patch = ref.watch(patchClashConfigProvider);
    final dnsSafetyMode = ref.watch(
      networkSettingProvider.select((state) => state.dnsSafetyMode),
    );
    final appSetting = ref.watch(appSettingProvider);
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final rulesCount = ref.watch(globalRulesProvider).value?.length ?? 0;
    final scriptsCount = ref.watch(scriptsProvider).value?.length ?? 0;
    final languageLabel = appSetting.locale == null
        ? l10n.defaultText
        : Intl.message(appSetting.locale!);

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: [
        const _GroupLabel('连接'),
        _Card(
          children: [
            _MobileV4SettingsRow(
              icon: QuanXIcons.shield,
              title: '虚拟网卡',
              sub: vpnProps.enable ? 'VPN 已开启' : 'VPN 已关闭',
              trailing: _MiniSwitch(
                value: vpnProps.enable,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(vpnSettingProvider.notifier)
                      .update((state) => state.copyWith(enable: value));
                },
              ),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.layoutDashboard,
              title: '分应用代理',
              sub: accessControl.enable
                  ? '${accessControl.currentList.length} 个应用'
                  : '未启用',
              onTap: () => BaseNavigator.push(context, const AccessView()),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.zap,
              title: '出站模式',
              sub: mobileV4ModeShortLabel(patch.mode),
              onTap: () {
                HapticFeedback.selectionClick();
                final next = mobileV4Modes[
                    (mobileV4Modes.indexOf(patch.mode) + 1) %
                        mobileV4Modes.length];
                ref
                    .read(patchClashConfigProvider.notifier)
                    .update((state) => state.copyWith(mode: next));
              },
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.lock,
              title: 'DNS 安全模式',
              sub: _dnsSafetyLabel(context, dnsSafetyMode),
              onTap: () {
                HapticFeedback.selectionClick();
                const modes = DnsSafetyMode.values;
                final next =
                    modes[(modes.indexOf(dnsSafetyMode) + 1) % modes.length];
                ref
                    .read(networkSettingProvider.notifier)
                    .update((state) => state.copyWith(dnsSafetyMode: next));
              },
            ),
          ],
        ),
        const _GroupLabel('规则与脚本'),
        _Card(
          children: [
            _MobileV4SettingsRow(
              icon: QuanXIcons.waypoints,
              title: '分流规则',
              sub: '$rulesCount 条',
              onTap: () => BaseNavigator.push(context, const AddedRulesView()),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.slidersHorizontal,
              title: '基础配置',
              sub: '端口 ${patch.mixedPort}',
              onTap: () => BaseNavigator.push(context, const ConfigView()),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.braces,
              title: '脚本',
              sub: '$scriptsCount 个',
              onTap: () => BaseNavigator.push(context, const ScriptsView()),
            ),
          ],
        ),
        const _GroupLabel('通用'),
        _Card(
          children: [
            _MobileV4SettingsRow(
              icon: p.isDark ? QuanXIcons.moon : QuanXIcons.sun,
              title: '外观',
              sub: _themeModeLabel(themeMode),
              onTap: () => _showAppearancePicker(context),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.globe,
              title: '语言',
              sub: languageLabel,
              onTap: () => showLanguageSettingsModal(context),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.circlePlay,
              title: '启动时连接',
              trailing: _MiniSwitch(
                value: appSetting.autoRun,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(autoRun: value));
                },
              ),
            ),
            _MobileV4SettingsRow(
              icon: QuanXIcons.scrollText,
              title: '日志记录',
              trailing: _MiniSwitch(
                value: appSetting.openLogs,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(openLogs: value));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Center(
          child: Text(
            'QUANCLASH $appVersion',
            style: TextStyle(
              fontSize: 8.5,
              letterSpacing: 1.6,
              color: p.faint,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppearancePickerSheet extends ConsumerWidget {
  const _AppearancePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final current = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const options = [
      (ThemeMode.system, QuanXIcons.sunMoon, '跟随系统', '自动同步设备浅色或深色外观'),
      (ThemeMode.light, QuanXIcons.sun, '浅色', '白瓷玻璃质感，参考桌面浅色体系'),
      (ThemeMode.dark, QuanXIcons.moon, '深色', '纯黑画布与星阵玻璃质感'),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MobileV4Theme.radiusSheet),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.sheet,
            border: Border(top: BorderSide(color: p.sheetTopBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.sheetHandle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '外观',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.6,
                            color: p.text,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.closeBg,
                            border: Border.all(color: p.closeBorder),
                          ),
                          child: Center(
                            child: Icon(QuanXIcons.x, size: 13, color: p.text2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    children: [
                      for (final (mode, icon, title, sub) in options)
                        _MobileV4SettingsRow(
                          icon: icon,
                          title: title,
                          sub: sub,
                          trailing: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: current == mode
                                  ? p.accent
                                  : Colors.transparent,
                              border: Border.all(
                                color: current == mode
                                    ? Colors.transparent
                                    : (p.isDark
                                        ? p.faint
                                        : const Color(0xFFD0D0DC)),
                                width: 1.4,
                              ),
                              boxShadow: current == mode
                                  ? [
                                      BoxShadow(
                                        color: p.accent.withValues(alpha: .35),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: current == mode
                                ? Center(
                                    child: Icon(
                                      QuanXIcons.check,
                                      size: 10,
                                      color: p.onAccent,
                                    ),
                                  )
                                : null,
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(themeSettingProvider.notifier)
                                .update((state) => state.copyWith(themeMode: mode));
                            Navigator.of(context).pop();
                          },
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
  }
}

// ---------------------------------------------------------------------------
// Shared Primitives
// ---------------------------------------------------------------------------

class _MobileV4SettingsRow extends StatelessWidget {
  const _MobileV4SettingsRow({
    required this.icon,
    required this.title,
    this.sub,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return GestureDetector(
      behavior:
          onTap == null ? HitTestBehavior.translucent : HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: p.iconBoxFill,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: p.iconBoxBorder),
                  boxShadow: p.isDark
                      ? const [
                          BoxShadow(
                            color: Color(0x07FFFFFF),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: p.iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.2,
                        color: p.text,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value != null && value!.isNotEmpty)
                        Text(
                          value!,
                          style: TextStyle(
                            fontSize: 10,
                            color: p.muted,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Icon(
                        QuanXIcons.chevronRight,
                        size: 13,
                        color: p.faint,
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 40,
        height: 25,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? p.switchOnTrack : p.switchOffTrack,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: value ? Colors.transparent : p.lineSoft,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? p.switchOnKnob : p.switchOffKnob,
              boxShadow: !p.isDark && !value
                  ? const [
                      BoxShadow(
                        color: Color(0x2E181622),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 2,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: p.barTrack),
            ),
            if (clamped > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clamped,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: p.accent,
                      boxShadow: [
                        BoxShadow(
                          color: p.accent.withValues(
                            alpha: p.isDark ? .5 : .35,
                          ),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return SizedBox(
      height: 64,
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: p.muted),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(
    this.label, {
    this.trailing,
    this.trailingIcon,
    this.onTrailingTap,
  });

  final String label;
  final String? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final trailingWidget = trailing == null && trailingIcon == null
        ? null
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTrailingTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  Text(
                    trailing!,
                    style: TextStyle(
                      fontSize: 9,
                      color: p.faint,
                    ),
                  ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 5),
                  Icon(
                    trailingIcon,
                    size: 11,
                    color: p.muted,
                  ),
                ],
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                color: p.muted,
              ),
            ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children, this.topTint = Colors.transparent});

  final List<Widget> children;
  final Color topTint;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(height: 1, thickness: 1, color: p.lineSoft),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: topTint == Colors.transparent ? p.cardFill : null,
        gradient: topTint == Colors.transparent
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topTint, p.cardFill],
                stops: const [0.0, 0.58],
              ),
        borderRadius: BorderRadius.circular(MobileV4Theme.radiusCard),
        border: Border.all(color: p.lineSoft),
        boxShadow: p.isDark
            ? null
            : [
                BoxShadow(
                  color: p.cardShadow,
                  blurRadius: 20,
                  spreadRadius: -6,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}
