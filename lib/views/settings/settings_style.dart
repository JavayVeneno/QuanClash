import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:flutter/material.dart';

/// 设置页设计令牌：品牌紫、浅紫底座与浅灰紫背景。
class SettingsPalette {
  const SettingsPalette._();

  static const primary = Color(0xFF7B61FF);
  static const primarySoft = Color(0xFFF5F3FF);
  static const background = Color(0xFFF9FAFB);
  static const backgroundTop = Color(0xFFF4F1FF);
  static const border = Color(0xFFF1F1F5);
  static const field = Color(0xFFF3F4F6);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6B6B70);
  static const textTertiary = Color(0xFF8E8E93);
  static const textQuaternary = Color(0xFFA0A0A8);
  static const darkBackground = Color(0xFF0F0F12);
  static const darkSurface = Color(0xFF1E1E24);
  static const darkBorder = Color(0xFF2A2A32);
  static const darkField = Color(0xFF26262E);

  static bool isDark(BuildContext context) =>
      Theme.brightnessOf(context) == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : Colors.white;

  static Color pageBackground(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color pageGradientTop(BuildContext context) =>
      isDark(context) ? const Color(0xFF17131F) : backgroundTop;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : border;

  static Color soft(BuildContext context) =>
      isDark(context) ? primary.withValues(alpha: 0.18) : primarySoft;

  static Color fieldColor(BuildContext context) =>
      isDark(context) ? darkField : field;

  static Color text1(BuildContext context) =>
      isDark(context) ? const Color(0xFFF2F3F5) : textPrimary;

  static Color text2(BuildContext context) =>
      isDark(context) ? const Color(0xFFB4B4BC) : textSecondary;

  static Color text3(BuildContext context) =>
      isDark(context) ? const Color(0xFF8A8A94) : textTertiary;

  static Color text4(BuildContext context) =>
      isDark(context) ? const Color(0xFF6E6E78) : textQuaternary;

  static Color hover(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.04)
      : const Color(0xFFFAFAFC);

  static const radiusCard = 20.0;
  static const radiusControl = 8.0;
  static const rowHeight = 64.0;
}

class SettingsIconTile extends StatelessWidget {
  final IconData icon;
  final double size;

  const SettingsIconTile({super.key, required this.icon, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SettingsPalette.soft(context),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: SettingsPalette.primary,
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  final String label;

  const SettingsSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: SettingsPalette.text4(context),
        ),
      ),
    );
  }
}

/// 64px 设置行：浅紫图标底座 + 标题/说明 + 右侧控件。
class SettingsRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: const BoxConstraints(
              minHeight: SettingsPalette.rowHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: _hovered
                  ? SettingsPalette.hover(context)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: SettingsPalette.borderColor(context)),
              ),
            ),
            child: Row(
              children: [
                SettingsIconTile(icon: widget.icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          color: SettingsPalette.text1(context),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: SettingsPalette.text3(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 12),
                  widget.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsChevron extends StatelessWidget {
  const SettingsChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      QuanXIcons.chevronRight,
      size: 16,
      color: SettingsPalette.text4(context),
    );
  }
}

class SettingsValue extends StatelessWidget {
  final String value;

  const SettingsValue({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: SettingsPalette.text3(context)),
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value
              ? SettingsPalette.primary
              : (SettingsPalette.isDark(context)
                    ? const Color(0xFF3A3A42)
                    : const Color(0xFFE5E5EA)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsSelectOption<T> {
  final T value;
  final String label;

  const SettingsSelectOption(this.value, this.label);
}

/// 浅灰底 + 8px 圆角的极简下拉框。
class SettingsSelect<T> extends StatelessWidget {
  final T value;
  final List<SettingsSelectOption<T>> options;
  final ValueChanged<T>? onChanged;
  final double minWidth;

  const SettingsSelect({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
    this.minWidth = 124,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          SettingsPalette.surface(context),
        ),
        elevation: const WidgetStatePropertyAll(12),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(5)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: SettingsPalette.borderColor(context)),
          ),
        ),
        minimumSize: WidgetStatePropertyAll(Size(minWidth, 0)),
      ),
      menuChildren: [
        for (final option in options)
          MenuItemButton(
            onPressed: onChanged == null
                ? null
                : () => onChanged!(option.value),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                option.value == value
                    ? SettingsPalette.soft(context)
                    : Colors.transparent,
              ),
              minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: option.value == value
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: option.value == value
                          ? SettingsPalette.primary
                          : SettingsPalette.text2(context),
                    ),
                  ),
                ),
                if (option.value == value)
                  const Icon(
                    QuanXIcons.check,
                    size: 13,
                    color: SettingsPalette.primary,
                  ),
              ],
            ),
          ),
      ],
      builder: (context, controller, _) {
        return InkWell(
          onTap: onChanged == null
              ? null
              : () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
          borderRadius: BorderRadius.circular(SettingsPalette.radiusControl),
          child: Container(
            height: 34,
            constraints: BoxConstraints(minWidth: minWidth),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: SettingsPalette.fieldColor(context),
              borderRadius: BorderRadius.circular(
                SettingsPalette.radiusControl,
              ),
              border: Border.all(color: SettingsPalette.borderColor(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    current.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: SettingsPalette.text1(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  QuanXIcons.chevronDown,
                  size: 12,
                  color: SettingsPalette.text3(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool soft;

  const SettingsGhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: soft ? SettingsPalette.soft(context) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SettingsPalette.radiusControl),
          side: BorderSide(
            color: soft
                ? Colors.transparent
                : const Color(0xFFE4DCFF),
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(SettingsPalette.radiusControl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: SettingsPalette.primary),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: SettingsPalette.primary,
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

class SettingsOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const SettingsOptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SettingsPalette.soft(context)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: SettingsPalette.hover(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              SettingsIconTile(icon: icon, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SettingsPalette.text1(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: SettingsPalette.text3(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  QuanXIcons.check,
                  size: 18,
                  color: SettingsPalette.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const SettingsPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            color: SettingsPalette.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: SettingsPalette.text1(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: SettingsPalette.text3(context),
          ),
        ),
      ],
    );
  }
}

class SettingsSubpageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  const SettingsSubpageHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: SettingsPalette.borderColor(context)),
        ),
      ),
      child: Row(
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: SettingsPalette.text1(context),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: SettingsPalette.text3(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            QuanXIcons.arrowLeft,
            size: 17,
            color: SettingsPalette.text2(context),
          ),
        ),
      ),
    );
  }
}

class SettingsSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  const SettingsSlider({
    super.key,
    required this.value,
    this.min = 0.8,
    this.max = 1.3,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: SettingsPalette.primary,
        inactiveTrackColor: SettingsPalette.isDark(context)
            ? const Color(0xFF33333C)
            : const Color(0xFFF1F1F5),
        thumbColor: Colors.white,
        overlayColor: SettingsPalette.primary.withValues(alpha: 0.10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        thumbShape: const _RingThumbShape(),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}

class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(18, 18);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas.drawCircle(
      center,
      9,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = SettingsPalette.primary,
    );
  }
}

/// 居中毛玻璃设置弹窗。
Future<T?> showSettingsModal<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  double width = 460,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, _) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: SettingsPalette.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: SettingsPalette.isDark(context)
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: SettingsPalette.isDark(context) ? 0.45 : 0.14,
                      ),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: SettingsPalette.text1(context),
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: SettingsPalette.text3(context),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(QuanXIcons.x),
                            iconSize: 18,
                            color: SettingsPalette.text3(context),
                          ),
                        ],
                      ),
                    ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
