import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'utils.dart';

/// Draggable Obsidian-Amethyst QuanClash hub button with an iOS-26-inspired
/// **Liquid Glass L-Dock** on long press.
///
/// Interactions:
/// - **Tap**: cycles outbound mode (`规则 -> 全局 -> 直连`), or closes L-Dock if open.
/// - **Long press + slide horizontally** (left when docked right, right when docked left):
///   glides the liquid-glass highlight pill across `代理 / 配置 / 监控 / 设置`;
///   releasing opens the highlighted sheet directly.
/// - **Long press + slide vertically** (upward by default, downward if near top):
///   glides the warm-gold thumb across `全局 / 规则 / 直连` with live icon preview;
///   releasing applies the chosen mode directly.
/// - **Long press & release in place**: keeps the L-Dock open for direct tapping.
/// - **Drag**: repositions the hub and springs to the nearest horizontal edge.
class MobileV4RadialFab extends StatefulWidget {
  const MobileV4RadialFab({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onOpen,
    this.onMenuOpenChanged,
    this.activeNodeLabel,
    this.activeProfileLabel,
  });

  /// Current proxy outbound mode controlling the golden icon motif.
  final Mode mode;

  /// Called when the user switches proxy mode via tap or the vertical rail.
  final ValueChanged<Mode> onModeChanged;

  /// Called with `'proxy'`, `'config'`, `'monitor'`, or `'settings'`.
  final ValueChanged<String> onOpen;

  /// Notifies the parent when the L-Dock opens or closes so the underlying
  /// dashboard info can softly fade out.
  final ValueChanged<bool>? onMenuOpenChanged;

  /// Optional metadata retained for caller compatibility.
  final String? activeNodeLabel;
  final String? activeProfileLabel;

  @override
  State<MobileV4RadialFab> createState() => _MobileV4RadialFabState();
}

class _MobileV4RadialFabState extends State<MobileV4RadialFab>
    with TickerProviderStateMixin {
  static const double _hubSize = 62;
  static const double _margin = 20;
  static const double _dockHeight = 62;
  static const double _dockGap = 10;
  static const double _railWidth = 62;
  static const double _railHeight = 178;
  static const double _railGap = 10;
  static const _spring = SpringDescription(mass: 1, stiffness: 300, damping: 24);

  static const List<_DockNavItem> _dockItems = [
    _DockNavItem(type: 'proxy', label: '代理', icon: QuanXIcons.waypoints),
    _DockNavItem(type: 'config', label: '配置', icon: QuanXIcons.folderOpen),
    _DockNavItem(type: 'monitor', label: '监控', icon: QuanXIcons.activity),
    _DockNavItem(type: 'settings', label: '设置', icon: QuanXIcons.settings),
  ];

  static const List<Mode> _railModes = [
    Mode.global,
    Mode.rule,
    Mode.direct,
  ];

  late final AnimationController _menu =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _snap =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();
  late final AnimationController _tapBounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  Offset? _pos;
  Size _area = Size.zero;
  Size _lastSize = Size.zero;
  double _snapFrom = 0;
  double _snapTo = 0;
  bool _isOpen = false;
  int? _hoveredDockIndex;
  Mode? _hoveredMode;

  @override
  void initState() {
    super.initState();
    _menu.addListener(() => setState(() {}));
    _snap.addListener(() {
      final p = _pos;
      if (p == null) {
        return;
      }
      setState(() {
        _pos = Offset(
          _snapFrom + (_snapTo - _snapFrom) * _snap.value,
          p.dy,
        );
      });
    });
  }

  @override
  void dispose() {
    _menu.dispose();
    _snap.dispose();
    _breathe.dispose();
    _tapBounce.dispose();
    super.dispose();
  }

  void _setMenuOpen(bool open) {
    if (!open) {
      _hoveredDockIndex = null;
      _hoveredMode = null;
    }
    if (_isOpen != open) {
      _isOpen = open;
      widget.onMenuOpenChanged?.call(open);
    }
    _menu.animateWith(
      SpringSimulation(_spring, _menu.value, open ? 1 : 0, 0),
    );
  }

  void _handleHubTap() {
    if (_isOpen || _menu.value > .15) {
      HapticFeedback.selectionClick();
      _setMenuOpen(false);
      return;
    }
    _tapBounce.forward(from: 0);
    final modes = mobileV4Modes;
    final next = modes[(modes.indexOf(widget.mode) + 1) % modes.length];
    widget.onModeChanged(next);
  }

  void _handleLongPressStart(LongPressStartDetails _) {
    HapticFeedback.mediumImpact();
    setState(() {
      _hoveredDockIndex = null;
      _hoveredMode = null;
    });
    _setMenuOpen(true);
  }

  void _handleLongPressMoveUpdate(
    LongPressMoveUpdateDetails details, {
    required Offset pos,
    required Size size,
    required bool leftSide,
    required bool openAbove,
  }) {
    if (!_isOpen) {
      return;
    }
    final delta = details.localOffsetFromOrigin;
    final hDir = leftSide ? 1.0 : -1.0;
    final vDir = openAbove ? -1.0 : 1.0;
    final hDist = delta.dx * hDir;
    final vDist = delta.dy * vDir;

    // Deadzone right over the hub: clear hover so releasing keeps dock open.
    if (hDist < 26 && vDist < 26) {
      if (_hoveredDockIndex != null || _hoveredMode != null) {
        setState(() {
          _hoveredDockIndex = null;
          _hoveredMode = null;
        });
      }
      return;
    }

    final hubCenter = pos + const Offset(_hubSize / 2, _hubSize / 2);

    if (hDist >= vDist) {
      final (dockLeft, dockWidth) = _horizontalDockGeometry(
        pos: pos,
        size: size,
        leftSide: leftSide,
      );
      final touchX = hubCenter.dx + delta.dx;
      final t = ((touchX - dockLeft) / math.max(1.0, dockWidth))
          .clamp(0.0, 0.9999);
      final idx = (t * _dockItems.length).floor();
      if (_hoveredDockIndex != idx || _hoveredMode != null) {
        HapticFeedback.selectionClick();
        setState(() {
          _hoveredDockIndex = idx;
          _hoveredMode = null;
        });
      }
    } else {
      final railTop = _verticalRailTop(pos: pos, openAbove: openAbove);
      final touchY = hubCenter.dy + delta.dy;
      final t = ((touchY - railTop) / _railHeight).clamp(0.0, 0.9999);
      final modeIdx = (t * _railModes.length).floor();
      final nextMode = _railModes[modeIdx];
      if (_hoveredMode != nextMode || _hoveredDockIndex != null) {
        HapticFeedback.selectionClick();
        setState(() {
          _hoveredMode = nextMode;
          _hoveredDockIndex = null;
        });
      }
    }
  }

  void _handleLongPressEnd(LongPressEndDetails _) {
    final dockIdx = _hoveredDockIndex;
    final selectedMode = _hoveredMode;
    if (dockIdx != null) {
      HapticFeedback.lightImpact();
      _setMenuOpen(false);
      widget.onOpen(_dockItems[dockIdx].type);
      return;
    }
    if (selectedMode != null) {
      HapticFeedback.lightImpact();
      _setMenuOpen(false);
      if (selectedMode != widget.mode) {
        widget.onModeChanged(selectedMode);
      }
      return;
    }
    // Released directly on the hub without sliding: leave the L-Dock open so
    // the user can tap or slide on either capsule leisurely.
  }

  void _onPanStart(DragStartDetails _) {
    if (_menu.value > .01) {
      _setMenuOpen(false);
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final p = _pos;
    if (p == null) {
      return;
    }
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    setState(() {
      _pos = Offset(
        (p.dx + d.delta.dx)
            .clamp(12.0, math.max(12.0, _area.width - _hubSize - 12))
            .toDouble(),
        (p.dy + d.delta.dy)
            .clamp(
              70.0,
              math.max(70.0, _area.height - _hubSize - 12 - bottomInset),
            )
            .toDouble(),
      );
    });
  }

  void _onPanEnd() {
    final p = _pos;
    if (p == null) {
      return;
    }
    _snapFrom = p.dx;
    _snapTo = p.dx + _hubSize / 2 < _area.width / 2
        ? _margin
        : _area.width - _margin - _hubSize;
    _snap.value = 0;
    _snap.animateWith(SpringSimulation(_spring, 0, 1, 0));
  }

  (double left, double width) _horizontalDockGeometry({
    required Offset pos,
    required Size size,
    required bool leftSide,
  }) {
    if (leftSide) {
      final left = pos.dx + _hubSize + _dockGap;
      final available = math.max(180.0, size.width - left - 16.0);
      final width = math.min(available, 276.0);
      return (left, width);
    }
    final rightEdge = pos.dx - _dockGap;
    final available = math.max(180.0, rightEdge - 16.0);
    final width = math.min(available, 276.0);
    return (rightEdge - width, width);
  }

  double _verticalRailTop({required Offset pos, required bool openAbove}) {
    if (openAbove) {
      return pos.dy - _railGap - _railHeight;
    }
    return pos.dy + _hubSize + _railGap;
  }

  @override
  Widget build(BuildContext context) {
    final palette = MobileV4Palette.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _area = size;
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        if (_lastSize != size) {
          _lastSize = size;
          _pos = Offset(
            size.width - _margin - _hubSize,
            size.height - 28 - _hubSize - bottomInset,
          );
        }
        final raw = _pos ?? Offset.zero;
        final pos = Offset(
          raw.dx.clamp(12.0, math.max(12.0, size.width - _hubSize - 12)),
          raw.dy.clamp(
            70.0,
            math.max(70.0, size.height - _hubSize - 12 - bottomInset),
          ),
        );
        _pos = pos;
        final leftSide = pos.dx + _hubSize / 2 < size.width / 2;
        final openAbove = pos.dy > _railHeight + _railGap + 64;
        final progress = _menu.value;
        final open = progress > .01;
        final previewMode = _hoveredMode ?? widget.mode;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _setMenuOpen(false);
                  },
                  child: ColoredBox(
                    color: palette.menuScrimBase.withValues(
                      alpha:
                          palette.menuScrimMaxAlpha * progress.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            if (open)
              _buildHorizontalDock(
                pos: pos,
                size: size,
                leftSide: leftSide,
                progress: progress,
                palette: palette,
              ),
            if (open)
              _buildVerticalModeRail(
                pos: pos,
                openAbove: openAbove,
                progress: progress,
                palette: palette,
                activeMode: previewMode,
              ),
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: _buildHub(
                palette: palette,
                pos: pos,
                size: size,
                leftSide: leftSide,
                openAbove: openAbove,
                displayMode: previewMode,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalDock({
    required Offset pos,
    required Size size,
    required bool leftSide,
    required double progress,
    required MobileV4Palette palette,
  }) {
    final (dockLeft, dockWidth) = _horizontalDockGeometry(
      pos: pos,
      size: size,
      leftSide: leftSide,
    );
    final clamped = progress.clamp(0.0, 1.0);
    final slideX = (1.0 - clamped) * (leftSide ? -26.0 : 26.0);
    final subdued = _hoveredMode != null;

    return Positioned(
      left: dockLeft,
      top: pos.dy + (_hubSize - _dockHeight) / 2,
      width: dockWidth,
      height: _dockHeight,
      child: IgnorePointer(
        ignoring: progress < .08,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: clamped * (subdued ? 0.50 : 1.0),
          child: Transform.translate(
            offset: Offset(slideX, 0),
            child: Transform.scale(
              scale: 0.86 + 0.14 * clamped,
              alignment:
                  leftSide ? Alignment.centerLeft : Alignment.centerRight,
              child: _LiquidGlassHorizontalDock(
                palette: palette,
                items: _dockItems,
                width: dockWidth,
                hoveredIndex: _hoveredDockIndex,
                onHoverIndexChanged: (idx) {
                  if (_hoveredDockIndex != idx) {
                    if (idx != null) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() => _hoveredDockIndex = idx);
                  }
                },
                onSelect: (index) {
                  HapticFeedback.selectionClick();
                  _setMenuOpen(false);
                  widget.onOpen(_dockItems[index].type);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalModeRail({
    required Offset pos,
    required bool openAbove,
    required double progress,
    required MobileV4Palette palette,
    required Mode activeMode,
  }) {
    final railTop = _verticalRailTop(pos: pos, openAbove: openAbove);
    final clamped = progress.clamp(0.0, 1.0);
    final slideY = (1.0 - clamped) * (openAbove ? 22.0 : -22.0);
    final subdued = _hoveredDockIndex != null;

    return Positioned(
      left: pos.dx + (_hubSize - _railWidth) / 2,
      top: railTop,
      width: _railWidth,
      height: _railHeight,
      child: IgnorePointer(
        ignoring: progress < .08,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: clamped * (subdued ? 0.50 : 1.0),
          child: Transform.translate(
            offset: Offset(0, slideY),
            child: Transform.scale(
              scale: 0.86 + 0.14 * clamped,
              alignment:
                  openAbove ? Alignment.bottomCenter : Alignment.topCenter,
              child: _LiquidGlassModeRail(
                palette: palette,
                modes: _railModes,
                activeMode: activeMode,
                onHoverModeChanged: (m) {
                  if (_hoveredMode != m) {
                    if (m != null) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() => _hoveredMode = m);
                  }
                },
                onSelectMode: (m) {
                  HapticFeedback.selectionClick();
                  _setMenuOpen(false);
                  if (m != widget.mode) {
                    widget.onModeChanged(m);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHub({
    required MobileV4Palette palette,
    required Offset pos,
    required Size size,
    required bool leftSide,
    required bool openAbove,
    required Mode displayMode,
  }) {
    final (Color auraColor, double auraScale) = switch (displayMode) {
      Mode.global => (const Color(0xFFFBB946), 1.06),
      Mode.rule => (palette.accent, 0.96),
      Mode.direct => (palette.accent, 0.88),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleHubTap,
      onLongPressStart: _handleLongPressStart,
      onLongPressMoveUpdate: (details) => _handleLongPressMoveUpdate(
        details,
        pos: pos,
        size: size,
        leftSide: leftSide,
        openAbove: openAbove,
      ),
      onLongPressEnd: _handleLongPressEnd,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _onPanEnd(),
      child: AnimatedBuilder(
        animation: _tapBounce,
        builder: (context, child) {
          final bounce = math.sin(_tapBounce.value * math.pi);
          final pressScale = _isOpen ? 0.94 : (1.0 - 0.08 * bounce);
          return Transform.scale(scale: pressScale, child: child);
        },
        child: SizedBox(
          width: _hubSize,
          height: _hubSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -24,
                top: -24,
                width: _hubSize + 48,
                height: _hubSize + 48,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _breathe,
                    builder: (context, _) {
                      final t =
                          .5 + .5 * math.sin(_breathe.value * math.pi * 2);
                      final modeBoost = displayMode == Mode.global
                          ? 0.08
                          : displayMode == Mode.rule
                              ? 0.02
                              : -0.05;
                      final baseAlpha =
                          ((palette.isDark ? .18 : .13) + modeBoost)
                              .clamp(0.04, 0.34);
                      final ampAlpha = palette.isDark ? .10 : .08;
                      return Transform.scale(
                        scale: auraScale,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                auraColor.withValues(
                                  alpha: baseAlpha + ampAlpha * t,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0, .68],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: palette.fabHubShadow,
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: _ObsidianQuanClashIcon(
                  size: _hubSize,
                  mode: displayMode,
                  isDark: palette.isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockNavItem {
  const _DockNavItem({
    required this.type,
    required this.label,
    required this.icon,
  });

  final String type;
  final String label;
  final IconData icon;
}

/// iOS-26-inspired horizontal Liquid Glass capsule dock (`代理 / 配置 / 监控 / 设置`).
///
/// Supports both direct tap on any item AND horizontal drag-to-slide across
/// items with a smoothly gliding liquid-glass highlight capsule.
class _LiquidGlassHorizontalDock extends StatelessWidget {
  const _LiquidGlassHorizontalDock({
    required this.palette,
    required this.items,
    required this.width,
    required this.hoveredIndex,
    required this.onHoverIndexChanged,
    required this.onSelect,
  });

  final MobileV4Palette palette;
  final List<_DockNavItem> items;
  final double width;
  final int? hoveredIndex;
  final ValueChanged<int?> onHoverIndexChanged;
  final ValueChanged<int> onSelect;

  int _indexAtX(double localX) {
    const pad = 5.0;
    final innerW = math.max(1.0, width - pad * 2);
    final t = ((localX - pad) / innerW).clamp(0.0, 0.9999);
    return (t * items.length).floor();
  }

  @override
  Widget build(BuildContext context) {
    const pad = 5.0;
    final innerW = math.max(1.0, width - pad * 2);
    final slotW = innerW / items.length;
    final activeIdx = hoveredIndex;

    final shadowColor = palette.isDark
        ? const Color(0xBD000000)
        : const Color(0x2E564A80);
    final borderColor = palette.isDark
        ? const Color(0x29FFFFFF)
        : const Color(0xF2FFFFFF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (d) =>
          onHoverIndexChanged(_indexAtX(d.localPosition.dx)),
      onHorizontalDragUpdate: (d) =>
          onHoverIndexChanged(_indexAtX(d.localPosition.dx)),
      onHorizontalDragEnd: (_) {
        final idx = hoveredIndex;
        if (idx != null) {
          onSelect(idx);
        }
      },
      onHorizontalDragCancel: () => onHoverIndexChanged(null),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.isDark
                      ? const [Color(0xE0201E2C), Color(0xE6100F16)]
                      : const [Color(0xEBFFFFFF), Color(0xE0F6F5FC)],
                ),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(pad),
                child: Stack(
                  children: [
                    if (activeIdx != null)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        left: activeIdx * slotW,
                        top: 0,
                        bottom: 0,
                        width: slotW,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: palette.isDark
                                  ? const [
                                      Color(0x3DB9A2FF),
                                      Color(0x1FB9A2FF),
                                    ]
                                  : const [
                                      Color(0x266C5CE7),
                                      Color(0x146C5CE7),
                                    ],
                            ),
                            border: Border.all(
                              color: palette.isDark
                                  ? const Color(0x6BB9A2FF)
                                  : const Color(0x426C5CE7),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: palette.accent.withValues(
                                  alpha: palette.isDark ? 0.24 : 0.14,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (_) => onHoverIndexChanged(i),
                              onTapCancel: () => onHoverIndexChanged(null),
                              onTap: () => onSelect(i),
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 150),
                                  scale: activeIdx == i ? 1.06 : 1.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        items[i].icon,
                                        size: 17,
                                        color: activeIdx == i
                                            ? (palette.isDark
                                                  ? const Color(0xFFE4DAFF)
                                                  : palette.accent)
                                            : palette.text2,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        items[i].label,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                          height: 1,
                                          color: activeIdx == i
                                              ? (palette.isDark
                                                    ? const Color(0xFFE4DAFF)
                                                    : palette.accent)
                                              : palette.text2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
  }
}

/// Vertical Liquid Glass Mode Slider Rail (`全局 / 规则 / 直连`) rising directly
/// above the hub. Supports both vertical slide-to-select and direct taps.
class _LiquidGlassModeRail extends StatelessWidget {
  const _LiquidGlassModeRail({
    required this.palette,
    required this.modes,
    required this.activeMode,
    required this.onHoverModeChanged,
    required this.onSelectMode,
  });

  final MobileV4Palette palette;
  final List<Mode> modes;
  final Mode activeMode;
  final ValueChanged<Mode?> onHoverModeChanged;
  final ValueChanged<Mode> onSelectMode;

  Mode _modeAtY(double localY, double height) {
    const pad = 5.0;
    final innerH = math.max(1.0, height - pad * 2);
    final t = ((localY - pad) / innerH).clamp(0.0, 0.9999);
    return modes[(t * modes.length).floor()];
  }

  @override
  Widget build(BuildContext context) {
    const pad = 5.0;
    const totalH = _MobileV4RadialFabState._railHeight;
    const innerH = totalH - pad * 2;
    final slotH = innerH / modes.length;
    final activeIdx = math.max(0, modes.indexOf(activeMode));

    final shadowColor = palette.isDark
        ? const Color(0xBD000000)
        : const Color(0x2E564A80);
    final borderColor = palette.isDark
        ? const Color(0x26FFFFFF)
        : const Color(0xF2FFFFFF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) =>
          onHoverModeChanged(_modeAtY(d.localPosition.dy, totalH)),
      onVerticalDragUpdate: (d) =>
          onHoverModeChanged(_modeAtY(d.localPosition.dy, totalH)),
      onVerticalDragEnd: (_) => onSelectMode(activeMode),
      onVerticalDragCancel: () => onHoverModeChanged(null),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.isDark
                      ? const [Color(0xE61E1C28), Color(0xE6100F16)]
                      : const [Color(0xEDFFFFFF), Color(0xE3F6F5FC)],
                ),
                border: Border.all(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(pad),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 170),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      top: activeIdx * slotH,
                      height: slotH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: palette.isDark
                                ? const [Color(0x42FBB946), Color(0x1FFBB946)]
                                : const [Color(0x38F5B030), Color(0x1AF5B030)],
                          ),
                          border: Border.all(
                            color: palette.isDark
                                ? const Color(0x85FBB946)
                                : const Color(0x6BE5A01D),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBB946).withValues(
                                alpha: palette.isDark ? 0.24 : 0.16,
                              ),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        for (final m in modes)
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelectMode(m),
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 150),
                                  scale: m == activeMode ? 1.06 : 1.0,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(15, 15),
                                        painter: _ModeMiniGlyphPainter(
                                          mode: m,
                                          active: m == activeMode,
                                          isDark: palette.isDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mobileV4ModeShortLabel(m),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1,
                                          color: m == activeMode
                                              ? (palette.isDark
                                                    ? const Color(0xFFFFE19A)
                                                    : const Color(0xFFB45309))
                                              : palette.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
  }
}

/// Miniature golden mode ring/crescent/spark glyph inside the vertical rail.
class _ModeMiniGlyphPainter extends CustomPainter {
  const _ModeMiniGlyphPainter({
    required this.mode,
    required this.active,
    required this.isDark,
  });

  final Mode mode;
  final bool active;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.38;
    final color = active
        ? (isDark ? const Color(0xFFFFD875) : const Color(0xFFD97706))
        : (isDark ? const Color(0xFF8E8E9E) : const Color(0xFF808092));

    switch (mode) {
      case Mode.global:
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9
            ..color = color,
        );
      case Mode.rule:
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = color.withValues(alpha: 0.25),
        );
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          math.pi / 2,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      case Mode.direct:
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1
            ..color = color.withValues(alpha: 0.28),
        );
        canvas.drawCircle(
          Offset(
            c.dx + math.cos(-math.pi / 4) * r,
            c.dy + math.sin(-math.pi / 4) * r,
          ),
          2.0,
          Paint()..color = color,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ModeMiniGlyphPainter oldDelegate) =>
      oldDelegate.mode != mode ||
      oldDelegate.active != active ||
      oldDelegate.isDark != isDark;
}

/// Scheme I-1: **Obsidian Amethyst Glass** QuanClash icon.
///
/// Extracts the authentic cloud silhouette directly from `assets/images/icon.png`
/// via a green-channel alpha matrix inside an `0.80` inner clip (hiding the
/// static baked gold rim), then renders it on:
/// - Dark mode: low-saturation obsidian-amethyst glass orb (`#2A2146 -> #0C0A13`)
///   + moonlight white cloud (`#F3F1FA`)
/// - Light mode: porcelain-lavender glass orb (`#FFFFFF -> #E5DFFB`)
///   + brand violet cloud (`#6C5CE7`)
///
/// Topped by a smoothly morphing mode-specific golden accent:
/// - [Mode.rule]: classic top-right tapered golden crescent
/// - [Mode.global]: full 360° luminous golden halo ring
/// - [Mode.direct]: minimal restrained champagne-gold spark point
class _ObsidianQuanClashIcon extends StatelessWidget {
  const _ObsidianQuanClashIcon({
    required this.size,
    required this.mode,
    required this.isDark,
  });

  final double size;
  final Mode mode;
  final bool isDark;

  double _targetSweep(Mode m) => switch (m) {
    Mode.direct => 0.0,
    Mode.rule => 1.15,
    Mode.global => math.pi * 2,
  };

  double _targetDotAlpha(Mode m) => m == Mode.direct ? 1.0 : 0.0;

  ColorFilter _cloudExtractFilter(Color cloudColor) {
    final r = cloudColor.r * 255.0;
    final g = cloudColor.g * 255.0;
    final b = cloudColor.b * 255.0;
    // In `assets/images/icon.png`, purple bg has G=22 while the white cloud has
    // G=255. Mapping alpha = clamp(1.8 * G - 120) isolates the exact cloud mask
    // with smooth anti-aliasing at zero extra asset cost.
    return ColorFilter.matrix(<double>[
      0, 0, 0, 0, r,
      0, 0, 0, 0, g,
      0, 0, 0, 0, b,
      0, 1.8, 0, 0, -120,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final innerClipSize = size * 0.80;
    final cloudColor = isDark
        ? const Color(0xFFF3F1FA)
        : const Color(0xFF6C5CE7);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _targetSweep(mode)),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, sweep, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(end: _targetDotAlpha(mode)),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          builder: (context, dotAlpha, _) {
            return ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.42),
                          radius: 1.05,
                          colors: isDark
                              ? const [
                                  Color(0xFF2A2146),
                                  Color(0xFF161224),
                                  Color(0xFF0C0A13),
                                ]
                              : const [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFF1EEFD),
                                  Color(0xFFE5DFFB),
                                ],
                          stops: const [0.0, 0.58, 1.0],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: innerClipSize,
                    height: innerClipSize,
                    child: ClipOval(
                      child: OverflowBox(
                        maxWidth: size,
                        maxHeight: size,
                        child: ColorFiltered(
                          colorFilter: _cloudExtractFilter(cloudColor),
                          child: Image.asset(
                            'assets/images/icon.png',
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, _, _) => Icon(
                              QuanXIcons.globe,
                              size: 24,
                              color: cloudColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ModeGoldRimPainter(
                          sweep: sweep,
                          dotAlpha: dotAlpha,
                          mode: mode,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ModeGoldRimPainter extends CustomPainter {
  const _ModeGoldRimPainter({
    required this.sweep,
    required this.dotAlpha,
    required this.mode,
    required this.isDark,
  });

  final double sweep;
  final double dotAlpha;
  final Mode mode;
  final bool isDark;

  static const _goldBright = Color(0xFFFFE699);
  static const _goldCore = Color(0xFFFBB946);
  static const _goldDeep = Color(0xFFE59819);
  static const _goldMuted = Color(0xFFD8B86A);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    canvas.drawCircle(
      c,
      r - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = isDark
            ? const Color(0x28B9A2FF)
            : const Color(0x366C5CE7),
    );

    const centerAngle = -math.pi / 4;

    if (sweep >= math.pi * 1.98) {
      final ringRect = Rect.fromCircle(center: c, radius: r - 1.8);
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.8
        ..color = _goldCore.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(c, r - 1.8, glowPaint);

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..shader = const SweepGradient(
          colors: [_goldBright, _goldCore, _goldDeep, _goldBright],
          stops: [0.0, 0.32, 0.72, 1.0],
        ).createShader(ringRect);
      canvas.drawCircle(c, r - 1.8, ringPaint);
    } else if (sweep > 0.08) {
      final startAngle = centerAngle - sweep / 2;
      final outerR = r - 0.4;
      final ringBlend = ((sweep - 1.35) / (math.pi * 1.98 - 1.35))
          .clamp(0.0, 1.0);
      final maxThickness = 3.5 - 0.9 * ringBlend;

      final path = Path();
      const steps = 48;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final a = startAngle + sweep * t;
        final x = c.dx + math.cos(a) * outerR;
        final y = c.dy + math.sin(a) * outerR;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      for (var i = steps; i >= 0; i--) {
        final t = i / steps;
        final a = startAngle + sweep * t;
        final taper = math.sin(math.pi * t);
        final profile = taper + (1.0 - taper) * ringBlend;
        final thickness = maxThickness * profile;
        final innerR = outerR - thickness;
        final x = c.dx + math.cos(a) * innerR;
        final y = c.dy + math.sin(a) * innerR;
        path.lineTo(x, y);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = _goldCore.withValues(alpha: 0.34 + 0.06 * ringBlend)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(c.dx, c.dy - r),
            Offset(c.dx + r, c.dy),
            const [_goldBright, _goldCore, _goldDeep],
            const [0.0, 0.52, 1.0],
          ),
      );
    }

    if (dotAlpha > 0.01) {
      canvas.drawCircle(
        c,
        r - 1.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = _goldMuted.withValues(alpha: 0.24 * dotAlpha),
      );

      final dotPos = Offset(
        c.dx + math.cos(centerAngle) * (r - 4.2),
        c.dy + math.sin(centerAngle) * (r - 4.2),
      );
      canvas.drawCircle(
        dotPos,
        5.2,
        Paint()
          ..color = _goldMuted.withValues(alpha: 0.32 * dotAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.8),
      );
      canvas.drawCircle(
        dotPos,
        2.7,
        Paint()..color = _goldMuted.withValues(alpha: 0.92 * dotAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ModeGoldRimPainter oldDelegate) =>
      oldDelegate.sweep != sweep ||
      oldDelegate.dotAlpha != dotAlpha ||
      oldDelegate.mode != mode ||
      oldDelegate.isDark != isDark;
}
