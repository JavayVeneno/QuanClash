import 'package:quanclash/common/constant.dart';
import 'package:quanclash/common/context.dart';
import 'package:quanclash/common/glass.dart';
import 'package:quanclash/common/num.dart';
import 'package:quanclash/common/quanx.dart';
import 'package:quanclash/common/quanx_icons.dart';
import 'package:quanclash/common/utils.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/panel/panel_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 面板 UI 的动作集合。
///
/// 主窗口内嵌的面板直接调用 Riverpod;独立面板窗口则把这些动作转成命令发给
/// 主引擎,两边共用同一份 [PanelBody]。
class PanelActions {
  const PanelActions({
    required this.onToggleStart,
    required this.onModeChanged,
    required this.onSystemProxyChanged,
    required this.onTunChanged,
    required this.onOpenMain,
    required this.onHide,
    required this.onExit,
  });

  final VoidCallback onToggleStart;
  final ValueChanged<Mode> onModeChanged;
  final ValueChanged<bool> onSystemProxyChanged;
  final ValueChanged<bool> onTunChanged;
  final void Function(PageLabel? page) onOpenMain;
  final VoidCallback onHide;
  final VoidCallback onExit;
}

String _speedText(num value) {
  final traffic = value.traffic;
  return '${traffic.value}${traffic.unit}';
}

/// 托盘小面板的纯展示层:点托盘图标弹出,一屏完成启停、节点与常用开关。
///
/// 布局按 360x430 设计,纵向用弹性行吸收系统边框带来的 1-2px 误差。
class PanelBody extends StatelessWidget {
  final PanelState state;
  final PanelActions actions;

  const PanelBody({super.key, required this.state, required this.actions});

  CoreStatus get _coreStatus => CoreStatus.values.firstWhere(
    (status) => status.name == state.coreStatus,
    orElse: () => CoreStatus.disconnected,
  );

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final glass = context.glass;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): actions.onHide,
      },
      child: Focus(
        autofocus: true,
        child: GlassPanel(
          radius: 0,
          blur: false,
          shadow: false,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                quanX.accent.withValues(alpha: isDark ? 0.20 : 0.08),
                glass.tintStrong,
              ),
              glass.tint,
              Color.alphaBlend(
                quanX.info.withValues(alpha: isDark ? 0.06 : 0.03),
                glass.tint,
              ),
            ],
            stops: const [0, 0.45, 1],
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                  child: Column(
                    children: [
                      _buildHero(context),
                      const SizedBox(height: 9),
                      _buildNode(context),
                      const SizedBox(height: 9),
                      Expanded(child: _buildQuickControls(context)),
                      const SizedBox(height: 9),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      height: 42,
      padding: const EdgeInsets.only(left: 13, right: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: quanX.separator)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset('assets/images/icon.png', width: 20, height: 20),
          ),
          const SizedBox(width: 8),
          Text(
            appName,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _PanelIconButton(
            icon: QuanXIcons.settings,
            tooltip: context.appLocalizations.settings,
            onPressed: () => actions.onOpenMain(PageLabel.settings),
          ),
          _PanelIconButton(
            icon: QuanXIcons.x,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: actions.onHide,
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final coreStatus = _coreStatus;
    final (statusText, statusColor) = switch (coreStatus) {
      CoreStatus.connecting => (appLocalizations.connecting, quanX.warning),
      CoreStatus.connected => (appLocalizations.connected, quanX.success),
      _ => (appLocalizations.disconnected, quanX.textTertiary),
    };
    final connected = coreStatus == CoreStatus.connected;
    final modeName = Intl.message(state.outboundMode.name);
    final sub = state.isStart
        ? '${utils.getTimeText(state.runTime)} · $modeName'
        : '$modeName · ${appLocalizations.port} ${state.port}';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? null : quanX.surface,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  quanX.accent.withValues(alpha: 0.13),
                  quanX.surface.withValues(alpha: 0.92),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: quanX.separator),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatusOrb(color: statusColor, active: connected),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: quanX.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ToggleButton(
                isStart: state.isStart,
                label: state.isStart
                    ? appLocalizations.stop
                    : appLocalizations.start,
                onPressed: actions.onToggleStart,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TrafficChip(
                  icon: QuanXIcons.arrowUp,
                  color: quanX.info,
                  value: '${_speedText(state.up)}/s',
                  unit: appLocalizations.upload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrafficChip(
                  icon: QuanXIcons.arrowDown,
                  color: quanX.success,
                  value: '${_speedText(state.down)}/s',
                  unit: appLocalizations.download,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNode(BuildContext context) {
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final now = state.proxyName;
    final hasNode = now != null && now.isNotEmpty;
    return InkWell(
      onTap: () => actions.onOpenMain(PageLabel.proxies),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.035) : quanX.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: quanX.separator),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: quanX.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(QuanXIcons.globe, size: 16, color: quanX.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.groupName ?? context.appLocalizations.proxyGroup,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: quanX.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          hasNode ? now : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasNode
                                ? quanX.textPrimary
                                : quanX.textTertiary,
                          ),
                        ),
                      ),
                      if (hasNode && state.delay != null) ...[
                        const SizedBox(width: 6),
                        _DelayChip(delay: state.delay!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(QuanXIcons.chevronRight, size: 15, color: quanX.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickControls(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.035) : quanX.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: quanX.separator),
      ),
      child: Column(
        children: [
          Expanded(
            child: _QuickRow(
              label: appLocalizations.outboundMode,
              trailing: _ModeSegment(
                value: state.outboundMode,
                onChanged: actions.onModeChanged,
              ),
            ),
          ),
          Expanded(
            child: _QuickRow(
              label: appLocalizations.systemProxy,
              divider: true,
              trailing: _PanelSwitch(
                value: state.systemProxy,
                onChanged: actions.onSystemProxyChanged,
              ),
            ),
          ),
          Expanded(
            child: _QuickRow(
              label: appLocalizations.tun,
              divider: true,
              trailing: _PanelSwitch(
                value: state.tun,
                onChanged: actions.onTunChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    const shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => actions.onOpenMain(null),
              style: FilledButton.styleFrom(
                backgroundColor: quanX.accent,
                foregroundColor: quanX.onAccent,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: shape,
              ),
              icon: const Icon(QuanXIcons.externalLink, size: 15),
              label: const Text(
                '打开 $appName',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: OutlinedButton(
              onPressed: actions.onExit,
              style: OutlinedButton.styleFrom(
                foregroundColor: quanX.textSecondary,
                side: BorderSide(color: quanX.separator),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: shape,
              ),
              child: Text(
                appLocalizations.exit,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _PanelIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 15),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(foregroundColor: context.quanX.textSecondary),
    );
  }
}

class _StatusOrb extends StatelessWidget {
  final Color color;
  final bool active;

  const _StatusOrb({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.26)),
              ),
            ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.30)),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.65),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final bool isStart;
  final String label;
  final VoidCallback onPressed;

  const _ToggleButton({
    required this.isStart,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isStart ? quanX.surfaceElevated : quanX.accent,
        foregroundColor: isStart ? quanX.textPrimary : quanX.onAccent,
        minimumSize: const Size(78, 34),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: isStart ? BorderSide(color: quanX.separator) : BorderSide.none,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(9)),
        ),
      ),
      icon: Icon(isStart ? QuanXIcons.pause : QuanXIcons.play, size: 15),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TrafficChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;

  const _TrafficChip({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: quanX.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: quanX.separator),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 10.5, color: quanX.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _DelayChip extends StatelessWidget {
  final int delay;

  const _DelayChip({required this.delay});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    final color = switch (delay) {
      < 0 => quanX.danger,
      < 600 => quanX.success,
      _ => quanX.warning,
    };
    return Container(
      height: 17,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        '$delay ms',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _QuickRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final bool divider;

  const _QuickRow({
    required this.label,
    required this.trailing,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: divider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: quanX.separator)),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: quanX.textPrimary,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  final Mode value;
  final ValueChanged<Mode> onChanged;

  const _ModeSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: quanX.surfaceSunken,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: quanX.separator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: Mode.values.map((mode) {
          final selected = mode == value;
          return Semantics(
            selected: selected,
            button: true,
            child: InkWell(
              onTap: () => onChanged(mode),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: commonDuration,
                width: 48,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.brightnessOf(context) == Brightness.dark
                            ? quanX.surfaceElevated
                            : quanX.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  Intl.message(mode.name),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? quanX.textPrimary : quanX.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PanelSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PanelSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final quanX = context.quanX;
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 44,
          height: 32,
          child: Center(
            child: AnimatedContainer(
              duration: commonDuration,
              width: 36,
              height: 21,
              decoration: BoxDecoration(
                color: value ? quanX.accent : quanX.separator,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: commonDuration,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 17,
                  height: 17,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
