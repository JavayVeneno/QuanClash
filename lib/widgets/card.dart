import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';

import 'fade_box.dart';
import 'text.dart';

class Info {
  final String label;
  final IconData? iconData;

  const Info({required this.label, this.iconData});
}

class InfoHeader extends StatelessWidget {
  final Info info;
  final List<Widget> actions;
  final EdgeInsets? padding;

  const InfoHeader({
    super.key,
    required this.info,
    this.padding,
    List<Widget>? actions,
  }) : actions = actions ?? const [];

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry nextPadding = (padding ?? baseInfoEdgeInsets);
    if (actions.isNotEmpty) {
      nextPadding = nextPadding.subtract(EdgeInsets.symmetric(vertical: 8.mAp));
    }
    return Padding(
      padding: nextPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (info.iconData != null) ...[
                  Icon(
                    info.iconData,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                ],
                Flexible(
                  flex: 1,
                  child: TooltipText(
                    text: Text(
                      info.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.quanX.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (actions.isNotEmpty)
            SizedBox(
              height: globalState.measure.titleSmallHeight + 16.ap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [...actions],
              ),
            ),
        ],
      ),
    );
  }
}

/// 玻璃卡片。
///
/// 与 FlClash 原版「平面填充 + 硬描边 + hover 变色」不同,这里改为
/// 半透明玻璃 + 背景模糊 + 高光描边 + 柔和阴影;交互反馈由 ink 微光承担。
class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    bool? isSelected,
    this.type = CommonCardType.plain,
    this.onPressed,
    this.selectWidget,
    this.radius,
    required this.child,
    this.padding,
    this.enterAnimated = false,
    this.info,
    this.onLongPress,
    this.shape,
    this.isError = false,
  }) : isSelected = isSelected ?? false;

  final bool enterAnimated;
  final bool isSelected;
  final bool isError;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final Widget? selectWidget;
  final Widget child;
  final EdgeInsets? padding;
  final Info? info;
  final CommonCardType type;
  final double? radius;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    var childWidget = child;

    if (info != null) {
      childWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InfoHeader(
            padding: baseInfoEdgeInsets.copyWith(bottom: 0),
            info: info!,
          ),
          Flexible(flex: 1, child: child),
        ],
      );
    }

    if (selectWidget != null && isSelected) {
      final List<Widget> children = [];
      children.add(childWidget);
      children.add(Positioned.fill(child: selectWidget!));
      childWidget = Stack(children: children);
    }

    final colorScheme = context.colorScheme;
    final glass = context.glass;

    // 选中 / 错误态:在原玻璃底色上叠一层语义色,而不是整块换成实色。
    final Color? overlay = isError
        ? colorScheme.error.opacity12
        : isSelected
        ? colorScheme.primary.opacity15
        : type == CommonCardType.filled
        ? Colors.white.withValues(alpha: glass == GlassColors.dark ? 0.08 : 0.24)
        : null;

    final Color tint = overlay == null
        ? glass.tint
        : Color.alphaBlend(overlay, glass.tint);

    final card = GlassPanel(
      radius: radius ?? GlassRadius.panel,
      blurSigma: type == CommonCardType.filled ? 18 : 14,
      tint: tint,
      stroke: isError
          ? colorScheme.error.opacity38
          : isSelected
          ? colorScheme.primary.opacity38
          : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: colorScheme.onSurface.opacity10,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: childWidget,
          ),
        ),
      ),
    );

    return switch (enterAnimated) {
      true => FadeScaleEnterBox(child: card),
      false => card,
    };
  }
}

class SelectIcon extends StatelessWidget {
  const SelectIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.inversePrimary,
      shape: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(QuanXIcons.check, size: 16),
      ),
    );
  }
}

/// 设置分组:标题 + 玻璃分组容器。
class SettingsBlock extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  const SettingsBlock({super.key, required this.title, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          InfoHeader(info: Info(label: title)),
          GlassPanel(
            radius: GlassRadius.panel,
            child: Column(children: settings),
          ),
        ],
      ),
    );
  }
}
