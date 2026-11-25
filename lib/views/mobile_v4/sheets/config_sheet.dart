import 'dart:math' as math;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/pages/scan.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/profiles/edit.dart';
import 'package:quanclash/views/profiles/overwrite/overwrite.dart';
import 'package:quanclash/views/profiles/preview.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../utils.dart';
import 'sheet_primitives.dart';

class MobileV4ConfigSheet extends ConsumerWidget {
  const MobileV4ConfigSheet({super.key, required this.controller});

  final ScrollController controller;

  static const _autoUpdateIntervals = <int>[0, 6, 12, 24, 72];

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

  Future<void> _confirmDeleteProfile(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final l10n = context.appLocalizations;
    final confirmed = await globalState.showMessage(
      title: l10n.tip,
      message: TextSpan(
        text: '确定要删除订阅「${profile.realLabel}」吗？',
      ),
      confirmText: l10n.delete,
    );
    if (confirmed == true) {
      await ref.read(profilesActionProvider.notifier).deleteProfile(profile.id);
    }
  }

  Future<void> _showProfileActions(
    BuildContext context,
    WidgetRef ref,
    Profile profile, {
    required bool isActive,
  }) {
    final isUrl = profile.type == ProfileType.url;
    final subtitleParts = <String>[
      if (isActive) '当前生效中',
      isUrl ? '远程订阅' : '本地配置',
      if (profile.lastUpdateDate != null)
        '${profile.lastUpdateDate!.getLastUpdateTimeDesc(context)}更新',
    ];
    return showMobileV4ActionSheet(
      context: context,
      title: profile.realLabel,
      subtitle: subtitleParts.join(' · '),
      items: [
        if (!isActive)
          MobileV4ActionItem(
            icon: QuanXIcons.circleCheck,
            title: '设为当前配置',
            sub: '切换并立即应用此订阅',
            onTap: () => _selectProfile(ref, profile.id),
          ),
        if (isUrl)
          MobileV4ActionItem(
            icon: QuanXIcons.refreshCw,
            title: '更新订阅',
            sub: '从远程地址拉取最新配置与节点',
            onTap: () => ref
                .read(profilesActionProvider.notifier)
                .updateProfile(profile, showLoading: true),
          ),
        MobileV4ActionItem(
          icon: QuanXIcons.pencil,
          title: '编辑配置',
          sub: '修改名称、订阅链接、自动更新与 User-Agent',
          onTap: () => pushMobileV4Subpage(
            context,
            BaseScaffold(
              title: '编辑配置',
              body: Builder(
                builder: (pageContext) => EditProfileView(
                  context: pageContext,
                  profile: profile,
                ),
              ),
            ),
          ),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.eye,
          title: '预览 YAML',
          sub: '查看最终合并生效的完整配置文件',
          onTap: () => pushMobileV4Subpage(
            context,
            PreviewProfileView(profile: profile),
          ),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.slidersHorizontal,
          title: '覆写配置',
          sub: '自定义规则、策略组或覆写脚本',
          onTap: () => pushMobileV4Subpage(
            context,
            OverwriteView(profileId: profile.id),
          ),
        ),
        MobileV4ActionItem(
          icon: QuanXIcons.trash2,
          title: '删除订阅',
          sub: '移除此配置及本地缓存文件',
          isDestructive: true,
          onTap: () => _confirmDeleteProfile(context, ref, profile),
        ),
      ],
    );
  }

  Future<void> _showAutoUpdatePicker(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) {
    final currentHours =
        profile.realAutoUpdate ? profile.autoUpdateDuration.inHours : 0;
    return showMobileV4ActionSheet(
      context: context,
      title: '自动更新周期',
      subtitle: profile.realLabel,
      items: [
        for (final hours in _autoUpdateIntervals)
          MobileV4ActionItem(
            icon: hours == 0 ? QuanXIcons.ban : QuanXIcons.clock,
            title: hours == 0 ? '关闭' : '每 $hours 小时',
            sub: hours == 0 ? '仅手动刷新订阅' : '到期后自动在后台更新',
            showRadio: true,
            selected: hours == 0
                ? !profile.realAutoUpdate
                : profile.realAutoUpdate && currentHours == hours,
            onTap: () {
              ref.read(profilesProvider.notifier).updateProfile(
                profile.id,
                (p) => p.copyWith(
                  autoUpdate: hours > 0,
                  autoUpdateDuration: hours > 0
                      ? Duration(hours: hours)
                      : p.autoUpdateDuration,
                ),
              );
            },
          ),
      ],
    );
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
    final activeNodeCount = mobileV4UniqueNodeCount(groups);

    final autoUpdateLabel = activeProfile == null
        ? '未配置'
        : activeProfile.type != ProfileType.url
            ? '仅远程订阅支持'
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
                    .updateProfile(activeProfile, showLoading: true)
                : null,
            onMore: () => _showProfileActions(
              context,
              ref,
              activeProfile,
              isActive: true,
            ),
          ),
        MobileV4GroupLabel('订阅列表', trailing: '${profiles.length} 个'),
        if (otherProfiles.isNotEmpty)
          MobileV4Card(
            children: [
              for (final profile in otherProfiles)
                _SubscriptionRow(
                  profile: profile,
                  summaryValue: _profileSummaryValue(context, profile),
                  onTap: () => _selectProfile(ref, profile.id),
                  onMore: () => _showProfileActions(
                    context,
                    ref,
                    profile,
                    isActive: false,
                  ),
                ),
            ],
          )
        else if (activeProfile == null)
          const MobileV4Card(
            children: [
              MobileV4EmptyRow(text: '暂无订阅配置，请从下方导入'),
            ],
          )
        else
          const MobileV4Card(
            children: [
              MobileV4EmptyRow(text: '暂无其他备用订阅'),
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
        const MobileV4GroupLabel('订阅设置'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.refreshCw,
              title: '自动更新',
              sub: autoUpdateLabel,
              onTap: activeProfile == null ||
                      activeProfile.type != ProfileType.url
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _showAutoUpdatePicker(context, ref, activeProfile);
                    },
            ),
            MobileV4SettingsRow(
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

class _SubscriptionRow extends ConsumerWidget {
  const _SubscriptionRow({
    required this.profile,
    required this.summaryValue,
    required this.onTap,
    required this.onMore,
  });

  final Profile profile;
  final String summaryValue;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final updating = ref.watch(isUpdatingProvider(profile.updatingKey));
    return MobileV4SettingsRow(
      icon: profile.type == ProfileType.url
          ? QuanXIcons.squareStack
          : QuanXIcons.fileText,
      title: profile.realLabel,
      sub: updating
          ? '正在更新订阅...'
          : (profile.type == ProfileType.url ? '远程订阅' : '本地导入'),
      onTap: onTap,
      onLongPress: onMore,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (updating)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: p.accent,
                ),
              ),
            )
          else if (summaryValue.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: Text(
                  summaryValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: p.muted),
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMore,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                QuanXIcons.ellipsisVertical,
                size: 14,
                color: p.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveProfileHeroCard extends ConsumerWidget {
  const _ActiveProfileHeroCard({
    required this.profile,
    required this.nodeCount,
    required this.onMore,
    this.onRefresh,
  });

  final Profile profile;
  final int nodeCount;
  final VoidCallback? onRefresh;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final updating = ref.watch(isUpdatingProvider(profile.updatingKey));
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
      if (updating)
        '正在更新...'
      else if (updatedDesc != null)
        '$updatedDesc更新',
    ];

    return MobileV4Card(
      topTint: p.heroTopTint,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: updating ? null : (onRefresh ?? onMore),
          onLongPress: onMore,
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
                    const SizedBox(width: 8),
                    if (updating)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, right: 6),
                        child: SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: p.accent,
                          ),
                        ),
                      )
                    else
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
                    const SizedBox(width: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onMore,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.fill,
                          border: Border.all(color: p.lineSoft),
                        ),
                        child: Center(
                          child: Icon(
                            QuanXIcons.ellipsisVertical,
                            size: 13,
                            color: p.text2,
                          ),
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
                  MobileV4ProgressBar(value: usedPercent / 100),
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
                        updating ? '正在拉取最新订阅...' : '轻触卡片更新订阅 · 点击右上角管理配置',
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
