import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../liquid_switch.dart';
import '../theme.dart';

List<Group> mobileV4VisibleGroups(List<Group> groups, Mode mode) {
  return switch (mode) {
    Mode.direct => const [],
    Mode.global => groups,
    Mode.rule => groups
        .where((item) => item.hidden != true)
        .where((item) => item.name != GroupName.GLOBAL.name)
        .toList(),
  };
}

int mobileV4UniqueNodeCount(List<Group> groups) {
  final names = <String>{};
  for (final group in groups) {
    for (final proxy in group.all) {
      names.add(proxy.name);
    }
  }
  return names.length;
}

String mobileV4GroupTypeDescription(GroupType type) {
  return switch (type) {
    GroupType.URLTest => '自动选择 · 延迟优先',
    GroupType.Fallback => '自动选择 · 故障转移',
    GroupType.LoadBalance => '负载均衡',
    GroupType.Relay => '链式代理',
    GroupType.Selector => '手动选择',
  };
}

String mobileV4ThemeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => '跟随系统',
    ThemeMode.light => '浅色',
    ThemeMode.dark => '深色',
  };
}

/// Lightweight visual wrapper applied when Mobile v4 pushes an existing
/// full-screen subpage (such as Connections, Logs, DNS Diagnostic, Edit
/// Profile, or Backup & Restore) so its surface, AppBar, and dividers harmonize
/// with the active Mobile v4 Dark or Light palette without touching desktop.
class MobileV4SubpageScope extends StatelessWidget {
  const MobileV4SubpageScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final base = Theme.of(context);
    final surface = p.isDark ? const Color(0xFF101014) : p.cardFill;
    final adapted = base.copyWith(
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      cardColor: surface,
      dividerColor: p.lineSoft,
      colorScheme: base.colorScheme.copyWith(
        primary: p.accent,
        surface: p.bg,
        surfaceContainerLowest: p.bg,
        surfaceContainerLow: surface,
        surfaceContainer: surface,
        surfaceContainerHigh: p.isDark
            ? const Color(0xFF18181F)
            : const Color(0xFFF0EEF8),
        outlineVariant: p.lineSoft,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
    return Theme(data: adapted, child: child);
  }
}

/// Pushes an existing view inside [MobileV4SubpageScope].
Future<T?> pushMobileV4Subpage<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    CommonRoute<T>(
      builder: (_) => MobileV4SubpageScope(child: page),
    ),
  );
}

class MobileV4SheetHead extends ConsumerWidget {
  const MobileV4SheetHead({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final (String title, String sub) = switch (type) {
      'proxy' => () {
        final mode = ref.watch(
          patchClashConfigProvider.select((state) => state.mode),
        );
        final groups = mobileV4VisibleGroups(ref.watch(groupsProvider), mode);
        final nodeCount = mobileV4UniqueNodeCount(groups);
        return ('代理', '${groups.length} 个策略组 · $nodeCount 个节点');
      }(),
      'chains' => () {
        final profile = ref.watch(currentProfileProvider);
        final chains = profile == null
            ? const <ProxyChain>[]
            : ref.watch(profileProxyChainsProvider(profile.id));
        final enabled = profile?.chainsEnabled ?? true;
        return (
          context.appLocalizations.proxyChainTitle,
          enabled
              ? '${chains.length} · ${profile?.realLabel ?? ''}'
              : context.appLocalizations.proxyChainDisabledTitle,
        );
      }(),
      'config' => () {
        final profiles = ref.watch(profilesProvider);
        final currentId = ref.watch(currentProfileIdProvider);
        final activeCount =
            profiles.any((item) => item.id == currentId) ? 1 : 0;
        return ('配置', '${profiles.length} 个订阅 · $activeCount 个生效中');
      }(),
      'monitor' => () {
        final reqs = ref.watch(requestsProvider.select((s) => s.length));
        final logs = ref.watch(logsProvider.select((s) => s.length));
        return ('监控', '$reqs 条请求 · $logs 条日志');
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
              MobileV4CloseCircle(onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ],
      ),
    );
  }
}

class MobileV4CloseCircle extends StatelessWidget {
  const MobileV4CloseCircle({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class MobileV4SettingsRow extends StatelessWidget {
  const MobileV4SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.sub,
    this.value,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final titleColor = isDestructive ? p.danger : p.text;
    final iconColor = isDestructive ? p.danger : p.iconColor;

    return GestureDetector(
      behavior: (onTap == null && onLongPress == null)
          ? HitTestBehavior.translucent
          : HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
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
                  color: isDestructive
                      ? p.danger.withValues(alpha: .10)
                      : p.iconBoxFill,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDestructive
                        ? p.danger.withValues(alpha: .22)
                        : p.iconBoxBorder,
                  ),
                  boxShadow: p.isDark && !isDestructive
                      ? const [
                          BoxShadow(
                            color: Color(0x07FFFFFF),
                            blurRadius: 16,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: iconColor),
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
                        color: titleColor,
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 112),
                          child: Text(
                            value!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: p.muted,
                            ),
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

class MobileV4RadioCircle extends StatelessWidget {
  const MobileV4RadioCircle({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return Container(
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
                  blurRadius: 12,
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
    );
  }
}

class MobileV4MiniSwitch extends StatelessWidget {
  const MobileV4MiniSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MobileV4LiquidSwitch(value: value, onChanged: onChanged);
  }
}

class MobileV4ProgressBar extends StatelessWidget {
  const MobileV4ProgressBar({super.key, required this.value});

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

class MobileV4EmptyRow extends StatelessWidget {
  const MobileV4EmptyRow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    return SizedBox(
      height: 64,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: p.muted),
          ),
        ),
      ),
    );
  }
}

class MobileV4GroupLabel extends StatelessWidget {
  const MobileV4GroupLabel(
    this.label, {
    super.key,
    this.trailing,
    this.trailingIcon,
    this.onTrailingTap,
    this.leadingIcon,
    this.onTap,
    this.topPadding = 22,
  });

  final String label;
  final String? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final trailingWidget = trailing == null && trailingIcon == null
        ? null
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTrailingTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
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
            ),
          );

    final titleRow = Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 11, color: p.muted),
          const SizedBox(width: 5),
        ],
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
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(4, topPadding, 4, 9),
      child: Row(
        children: [
          Expanded(
            child: onTap == null
                ? titleRow
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: titleRow,
                  ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}

class MobileV4Card extends StatelessWidget {
  const MobileV4Card({
    super.key,
    required this.children,
    this.topTint = Colors.transparent,
  });

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
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MobileV4Theme.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }
}

/// Compact frosted capsule pill button used in Proxy Sheet toolbars and chips.
class MobileV4PillButton extends StatelessWidget {
  const MobileV4PillButton({
    super.key,
    required this.label,
    this.icon,
    this.active = false,
    this.loading = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool active;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = MobileV4Palette.of(context);
    final bg = active ? p.accentSoft : p.cardFill;
    final borderColor = active
        ? p.accent.withValues(alpha: p.isDark ? .38 : .32)
        : p.lineSoft;
    final fg = active ? p.accent : p.text2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.4,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -.1,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An option item rendered inside [showMobileV4ActionSheet].
class MobileV4ActionItem {
  const MobileV4ActionItem({
    required this.icon,
    required this.title,
    this.sub,
    this.selected = false,
    this.showRadio = false,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final bool selected;
  final bool showRadio;
  final bool isDestructive;
  final VoidCallback? onTap;
}

/// Presents a compact frosted v4 bottom action/picker sheet matching the
/// appearance picker language.
Future<void> showMobileV4ActionSheet({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<MobileV4ActionItem> items,
  Widget? headerWidget,
}) {
  final barrier = MobileV4Palette.of(context).sheetBarrier;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrier,
    builder: (ctx) {
      final p = MobileV4Palette.of(ctx);
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
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
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: SingleChildScrollView(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.5,
                                    color: p.text,
                                  ),
                                ),
                                if (subtitle != null && subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          MobileV4CloseCircle(
                            onTap: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      if (headerWidget != null) ...[
                        const SizedBox(height: 14),
                        headerWidget,
                      ],
                      const SizedBox(height: 16),
                      MobileV4Card(
                        children: [
                          for (final item in items)
                            MobileV4SettingsRow(
                              icon: item.icon,
                              title: item.title,
                              sub: item.sub,
                              isDestructive: item.isDestructive,
                              trailing: item.showRadio
                                  ? MobileV4RadioCircle(selected: item.selected)
                                  : null,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(ctx).pop();
                                item.onTap?.call();
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
        ),
      );
    },
  );
}
