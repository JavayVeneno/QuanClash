import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Draggable frosted hub with a 90 degree spring radial menu.
///
/// Adapts seamlessly to both Dark and Light v4 palettes.
class MobileV4RadialFab extends StatefulWidget {
  const MobileV4RadialFab({
    super.key,
    required this.onOpen,
    this.onMenuOpenChanged,
  });

  /// Called with `proxy`, `config` or `settings`.
  final ValueChanged<String> onOpen;

  /// Notifies the parent when the radial menu opens or closes so the
  /// underlying dashboard info can softly fade out.
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  State<MobileV4RadialFab> createState() => _MobileV4RadialFabState();
}

class _MobileV4RadialFabState extends State<MobileV4RadialFab>
    with TickerProviderStateMixin {
  static const double _hubSize = 64;
  static const double _itemSize = 48;
  static const double _margin = 26;
  static const double _distance = 96;
  static const _spring = SpringDescription(mass: 1, stiffness: 260, damping: 20);

  static const List<String> _types = ['proxy', 'config', 'settings'];
  static const List<IconData> _icons = [
    QuanXIcons.waypoints,
    QuanXIcons.squareStack,
    QuanXIcons.settings,
  ];

  late final AnimationController _menu =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _snap =
      AnimationController.unbounded(vsync: this);
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5500),
  )..repeat();

  Offset? _pos;
  Size _area = Size.zero;
  Size _lastSize = Size.zero;
  double _snapFrom = 0;
  double _snapTo = 0;
  bool _isOpen = false;

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
    super.dispose();
  }

  void _setMenuOpen(bool open) {
    if (_isOpen != open) {
      _isOpen = open;
      widget.onMenuOpenChanged?.call(open);
    }
    HapticFeedback.selectionClick();
    _menu.animateWith(
      SpringSimulation(_spring, _menu.value, open ? 1 : 0, 0),
    );
  }

  void _toggleMenu() {
    _setMenuOpen(_menu.value < .5);
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
            .clamp(10.0, math.max(10.0, _area.width - _hubSize - 10))
            .toDouble(),
        (p.dy + d.delta.dy)
            .clamp(
              70.0,
              math.max(70.0, _area.height - _hubSize - 10 - bottomInset),
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

  Offset _offsetFor(int i, bool leftSide) {
    final s = leftSide ? 1.0 : -1.0;
    const d = _distance;
    const m = d * .7071;
    return switch (i) {
      0 => Offset(s * d, 0),
      1 => Offset(s * m, -m),
      _ => const Offset(0, -d),
    };
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
          raw.dx.clamp(10.0, math.max(10.0, size.width - _hubSize - 10)),
          raw.dy.clamp(
            70.0,
            math.max(70.0, size.height - _hubSize - 10 - bottomInset),
          ),
        );
        _pos = pos;
        final leftSide = pos.dx + _hubSize / 2 < size.width / 2;
        final progress = _menu.value;
        final open = progress > .01;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (open)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _setMenuOpen(false),
                  child: ColoredBox(
                    color: palette.menuScrimBase.withValues(
                      alpha:
                          palette.menuScrimMaxAlpha * progress.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < 3; i++)
              _buildItem(i, pos, progress, leftSide, palette),
            Positioned(left: pos.dx, top: pos.dy, child: _buildHub(palette)),
          ],
        );
      },
    );
  }

  Widget _buildItem(
    int i,
    Offset pos,
    double progress,
    bool leftSide,
    MobileV4Palette palette,
  ) {
    final t = (progress * 1.1 - i * .07).clamp(0.0, 1.0);
    final eased = Curves.easeOutBack.transform(t);
    final off = _offsetFor(i, leftSide);
    final left = pos.dx + (_hubSize - _itemSize) / 2 + off.dx * eased;
    final top = pos.dy + (_hubSize - _itemSize) / 2 + off.dy * eased;

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        ignoring: progress < .02,
        child: Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: .35 + .65 * progress.clamp(0.0, 1.0),
            child: _MobileV4FabItem(
              icon: _icons[i],
              palette: palette,
              onTap: () {
                _setMenuOpen(false);
                widget.onOpen(_types[i]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHub(MobileV4Palette palette) {
    return GestureDetector(
      onTap: _toggleMenu,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _onPanEnd(),
      child: SizedBox(
        width: _hubSize,
        height: _hubSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -30,
              top: -30,
              width: 124,
              height: 124,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _breathe,
                  builder: (context, _) {
                    final t = .5 + .5 * math.sin(_breathe.value * math.pi * 2);
                    final baseAlpha = palette.isDark ? .17 : .11;
                    final ampAlpha = palette.isDark ? .15 : .13;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            palette.accent
                                .withValues(alpha: baseAlpha + ampAlpha * t),
                            Colors.transparent,
                          ],
                          stops: const [0, .68],
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
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
              ),
            ),
            ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: palette.fabHubGradient,
                    ),
                    border: Border.all(color: palette.fabHubBorder),
                  ),
                  child: Center(
                    child: _MonogramPainter(
                      ringColor: palette.fabMonogramRing,
                      textColor: palette.fabMonogramText,
                    ),
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

class _MobileV4FabItem extends StatelessWidget {
  const _MobileV4FabItem({
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final MobileV4Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -10,
              top: -10,
              right: -10,
              bottom: -10,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        palette.accent.withValues(
                          alpha: palette.isDark ? .16 : .12,
                        ),
                        Colors.transparent,
                      ],
                      stops: const [0, .66],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.fabItemShadow,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.fabItemFill,
                    border: Border.all(color: palette.fabItemBorder),
                  ),
                  child: Center(
                    child: Icon(icon, size: 19, color: palette.fabItemIcon),
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

class _MonogramPainter extends StatelessWidget {
  const _MonogramPainter({
    required this.ringColor,
    required this.textColor,
  });

  final Color ringColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(27, 27),
      painter: _MonogramCanvasPainter(
        ringColor: ringColor,
        textColor: textColor,
      ),
    );
  }
}

/// "Q inside a C" single-color monogram matching the v4 spec.
class _MonogramCanvasPainter extends CustomPainter {
  const _MonogramCanvasPainter({
    required this.ringColor,
    required this.textColor,
  });

  final Color ringColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = ringColor;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: size.width / 2 - 1.6),
      math.pi * .25,
      math.pi * 1.5,
      false,
      ring,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'Q',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MonogramCanvasPainter oldDelegate) =>
      oldDelegate.ringColor != ringColor || oldDelegate.textColor != textColor;
}
