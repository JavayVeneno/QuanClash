import 'dart:io';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/access.dart';
import 'package:quanclash/views/config/advanced.dart';
import 'package:quanclash/views/config/config.dart';
import 'package:quanclash/views/resources.dart';
import 'package:quanclash/views/settings/settings_modals.dart';
import 'package:quanclash/views/settings/settings_style.dart';
import 'package:quanclash/views/settings/settings_subpages.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' show dirname, join;

typedef SettingsSubpageOpener = SubpagePush;

const _settingsCardRadius = 28.0;

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  static const _pageCount = 4;
  static const _cardMaxWidth = 680.0;
  static const _accents = [
    SettingsPalette.primary,
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFF9333EA),
  ];

  late final AnimationController _pageController;
  final _navigatorKey = GlobalKey<NavigatorState>();
  final ValueNotifier<int> _subpageDepth = ValueNotifier(0);
  final ValueNotifier<Offset> _pointer = ValueNotifier(Offset.zero);
  late final NavigatorObserver _navigatorObserver;
  // 卡片内容在首次打开时才挂载，避免后台卡片触发副作用。
  final Set<int> _visitedTabs = {0};
  int _current = 0;
  // 环形牌堆的规范位置，始终落在整数上，避免动画被打断后累计偏移。
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController.unbounded(vsync: this, value: 0);
    _navigatorObserver = _SettingsNavigatorObserver(_subpageDepth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _subpageDepth.dispose();
    _pointer.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _current) {
      return;
    }
    // 在环形牌堆里走最短路径，避免上一页从末尾绕一整圈。
    var delta = (index - _current + _pageCount) % _pageCount;
    if (delta > _pageCount / 2) {
      delta -= _pageCount;
    }
    _visitedTabs.add(index);
    _target += delta;
    setState(() => _current = index);
    _pageController.animateTo(
      _target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _step(int direction) =>
      _selectTab((_current + direction + _pageCount) % _pageCount);

  /// 每张卡片相对当前视角的横向偏移：0 为正中，负数在左，正数在右。
  double _offsetOf(int index) {
    var offset = (index - _pageController.value) % _pageCount;
    if (offset < 0) {
      offset += _pageCount;
    }
    if (offset > _pageCount / 2) {
      offset -= _pageCount;
    }
    return offset;
  }

  Future<Object?> _openSubpage(String title, String? subtitle, Widget child) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return Future<Object?>.value();
    }
    return navigator.push<Object?>(_buildSubpageRoute(title, subtitle, child));
  }

  Route<Object?> _buildSubpageRoute(
    String title,
    String? subtitle,
    Widget child,
  ) {
    return PageRouteBuilder<Object?>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _SettingsCardSurface(
                child: _SettingsSubpage(
                  title: title,
                  subtitle: subtitle,
                  push: _openSubpage,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.appLocalizations;
    final labels = [l10n.settingsGeneral, l10n.network, l10n.core, l10n.about];
    final isDark = SettingsPalette.isDark(context);
    return CommonScaffold(
      hideAppBar: true,
      title: l10n.settings,
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              SettingsPalette.pageGradientTop(context),
              SettingsPalette.pageBackground(context),
            ],
            stops: const [0, 0.45],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _SettingsAmbientPainter(isDark: isDark),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const barHeight = 64.0;
                  const gap = 22.0;
                  final cardHeight = min(
                    700.0,
                    max(0.0, constraints.maxHeight - 48 - gap - barHeight),
                  );
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1100),
                              child: SizedBox(
                                width: double.infinity,
                                height: cardHeight,
                                child: _buildCard(context),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: gap),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: ValueListenableBuilder<int>(
                              valueListenable: _subpageDepth,
                              builder: (context, depth, _) {
                                return AnimatedOpacity(
                                  opacity: depth == 0 ? 1 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: IgnorePointer(
                                    ignoring: depth > 0,
                                    child: _SettingsPageBar(
                                      labels: labels,
                                      current: _current,
                                      onPrev: () => _step(-1),
                                      onNext: () => _step(1),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _subpageDepth,
      builder: (context, depth, _) {
        return PopScope(
          canPop: depth == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              return;
            }
            final navigator = _navigatorKey.currentState;
            if (navigator != null && navigator.canPop()) {
              navigator.maybePop();
            }
          },
          child: Navigator(
            key: _navigatorKey,
            observers: [_navigatorObserver],
            onGenerateRoute: (settings) {
              return PageRouteBuilder(
                settings: settings,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return _buildMain(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMain(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = min(_cardMaxWidth, constraints.maxWidth);
        return MouseRegion(
          onHover: (event) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            if (width <= 0 || height <= 0) {
              return;
            }
            _pointer.value = Offset(
              (event.localPosition.dx / width - 0.5) * 2,
              (event.localPosition.dy / height - 0.5) * 2,
            );
          },
          onExit: (_) => _pointer.value = Offset.zero,
          child: ValueListenableBuilder<Offset>(
            valueListenable: _pointer,
            // 顶部留一点余量，避免侧边卡片旋转后上沿被裁掉。
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) => _buildCarousel(cardWidth),
              ),
            ),
            builder: (context, pointer, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(pointer.dx * 0.03)
                  ..rotateX(-pointer.dy * 0.02),
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCarousel(double cardWidth) {
    final cards = [
      for (var index = 0; index < _pageCount; index++)
        (index, _offsetOf(index)),
    ]..sort((a, b) => b.$2.abs().compareTo(a.$2.abs()));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (index, offset) in cards)
          _buildCarouselCard(
            index: index,
            offset: offset,
            cardWidth: cardWidth,
          ),
      ],
    );
  }

  Widget _buildCarouselCard({
    required int index,
    required double offset,
    required double cardWidth,
  }) {
    final active = index == _current;
    final distance = offset.abs();
    final hidden = distance > 1.7;
    final opacity = hidden
        ? 0.0
        : distance <= 1
        ? 1.0
        : (1 - (distance - 1) * 1.5).clamp(0.0, 1.0);
    final veil = hidden ? 0.0 : (distance * 0.10).clamp(0.0, 0.20);
    final scale = 1 - distance * 0.18;
    final dx = offset * cardWidth * 0.40;
    final dy = distance * 16;
    // 不使用透视矩阵：卡片内容里含 ListView，透视变换会让视口的
    // 滚动偏移变成非有限值；用正交旋转同样能得到侧边卡片的立体感。
    final transform = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..rotateY(-offset * 0.55);
    return Positioned.fill(
      key: ValueKey('settings-card-$index'),
      child: IgnorePointer(
        ignoring: !active || hidden,
        child: Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Transform.scale(
              scale: scale,
              child: Center(
                child: SizedBox(
                  width: cardWidth,
                  height: double.infinity,
                  child: _SettingsCard(
                    accent: _accents[index],
                    active: active,
                    veil: veil,
                    child: _tabContent(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabContent(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    return switch (index) {
      0 => _GeneralSettingsTab(onOpenSubpage: _openSubpage),
      1 => _NetworkSettingsTab(onOpenSubpage: _openSubpage),
      2 => _CoreSettingsTab(onOpenSubpage: _openSubpage),
      _ => const _AboutSettingsTab(),
    };
  }
}

/// 悬浮在空间中的设置卡片：大圆角、顶部玻璃高光与强调色细边。
class _SettingsCard extends StatelessWidget {
  final Color accent;
  final bool active;
  final double veil;
  final Widget child;

  const _SettingsCard({
    required this.accent,
    required this.active,
    required this.veil,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SettingsPalette.isDark(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.05);
    final surface = SettingsPalette.surface(context);
    final cardColor = veil > 0
        ? Color.alphaBlend(accent.withValues(alpha: 0.05), surface)
        : surface;
    final barAlpha = active ? 1.0 : 0.5;
    return CustomPaint(
      painter: _SettingsCardShadowPainter(
        accent: accent,
        active: active,
        isDark: isDark,
      ),
      child: Material(
        color: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_settingsCardRadius),
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 110,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child,
            if (veil > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: (isDark ? Colors.black : Colors.white).withValues(
                      alpha: isDark ? veil * 0.45 : veil,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 3,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.72 * barAlpha),
                        accent.withValues(alpha: barAlpha),
                      ],
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 14,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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

/// 柔和的空间投影：最前方的卡片带一层强调色光晕。
class _SettingsCardShadowPainter extends CustomPainter {
  final Color accent;
  final bool active;
  final bool isDark;

  const _SettingsCardShadowPainter({
    required this.accent,
    required this.active,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(_settingsCardRadius),
        ),
      );
    if (active) {
      _draw(
        canvas,
        path,
        accent.withValues(alpha: isDark ? 0.26 : 0.20),
        56,
        const Offset(0, 28),
      );
    }
    _draw(
      canvas,
      path,
      Colors.black.withValues(alpha: isDark ? 0.45 : (active ? 0.18 : 0.10)),
      active ? 42 : 28,
      const Offset(0, 20),
    );
    _draw(
      canvas,
      path,
      Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
      12,
      const Offset(0, 5),
    );
  }

  void _draw(
    Canvas canvas,
    Path path,
    Color color,
    double blurRadius,
    Offset offset,
  ) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        blurRadius * 0.57735 + 0.5,
      );
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  // 投影只是绘制层，不应拦截卡片的点击。
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_SettingsCardShadowPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.active != active ||
        oldDelegate.isDark != isDark;
  }
}

/// 背景中缓慢散开的环境光，让卡片像悬浮在空间里。
class _SettingsAmbientPainter extends CustomPainter {
  final bool isDark;

  const _SettingsAmbientPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    _glow(
      canvas,
      Offset(size.width * 0.16, size.height * 0.06),
      size.width * 0.48,
      SettingsPalette.primary.withValues(alpha: isDark ? 0.24 : 0.16),
    );
    _glow(
      canvas,
      Offset(size.width * 0.88, size.height * 0.30),
      size.width * 0.42,
      const Color(0xFF4C8DFF).withValues(alpha: isDark ? 0.16 : 0.10),
    );
    _glow(
      canvas,
      Offset(size.width * 0.52, size.height * 1.04),
      size.width * 0.62,
      const Color(0xFF34C759).withValues(alpha: isDark ? 0.08 : 0.05),
    );
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SettingsAmbientPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// 底部翻页条：上一页 / 下一页各自带目标标签，中间是页码圆点。
class _SettingsPageBar extends StatelessWidget {
  final List<String> labels;
  final int current;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _SettingsPageBar({
    required this.labels,
    required this.current,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = SettingsPalette.isDark(context);
    final count = labels.length;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? SettingsPalette.darkSurface.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _PageStepButton(
              key: const ValueKey('settings-page-prev'),
              icon: QuanXIcons.chevronLeft,
              label: labels[(current - 1 + count) % count],
              alignEnd: false,
              onTap: onPrev,
            ),
          ),
          _PageDots(count: count, current: current),
          Expanded(
            child: _PageStepButton(
              key: const ValueKey('settings-page-next'),
              icon: QuanXIcons.chevronRight,
              label: labels[(current + 1) % count],
              alignEnd: true,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageStepButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool alignEnd;
  final VoidCallback onTap;

  const _PageStepButton({
    super.key,
    required this.icon,
    required this.label,
    required this.alignEnd,
    required this.onTap,
  });

  @override
  State<_PageStepButton> createState() => _PageStepButtonState();
}

class _PageStepButtonState extends State<_PageStepButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.icon,
      size: 18,
      color: SettingsPalette.text2(context),
    );
    final text = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: SettingsPalette.text1(context),
      ),
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? SettingsPalette.hover(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisAlignment: widget.alignEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!widget.alignEnd) ...[icon, const SizedBox(width: 8)],
              Flexible(child: text),
              if (widget.alignEnd) ...[const SizedBox(width: 8), icon],
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == current
                  ? SettingsPalette.primary
                  : SettingsPalette.text4(context).withValues(alpha: 0.35),
            ),
          ),
      ],
    );
  }
}

/// 二级设置页使用的外层卡片。
class _SettingsCardSurface extends StatelessWidget {
  final Widget child;

  const _SettingsCardSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = SettingsPalette.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: SettingsPalette.surface(context),
        borderRadius: BorderRadius.circular(_settingsCardRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.045),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _SettingsNavigatorObserver extends NavigatorObserver {
  final ValueNotifier<int> depth;

  _SettingsNavigatorObserver(this.depth);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      depth.value++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && depth.value > 0) {
      depth.value--;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null && depth.value > 0) {
      depth.value--;
    }
  }
}

class _SettingsSubpage extends StatefulWidget {
  final String title;
  final String? subtitle;
  final SubpagePush push;
  final Widget child;

  const _SettingsSubpage({
    required this.title,
    this.subtitle,
    required this.push,
    required this.child,
  });

  @override
  State<_SettingsSubpage> createState() => _SettingsSubpageState();
}

class _SettingsSubpageState extends State<_SettingsSubpage> {
  final ValueNotifier<List<Widget>> _actions = ValueNotifier(const []);

  @override
  void dispose() {
    _actions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SubpageScope(
      push: widget.push,
      setActions: (actions) {
        if (!mounted) {
          return;
        }
        _actions.value = List<Widget>.unmodifiable(actions);
      },
      child: Column(
        children: [
          SettingsSubpageHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            actions: _actions,
            onBack: () {
              Navigator.of(context).maybePop();
            },
          ),
          Expanded(child: SettingsSubpageTheme(child: widget.child)),
        ],
      ),
    );
  }
}

class _GeneralSettingsTab extends ConsumerWidget {
  final SettingsSubpageOpener onOpenSubpage;

  const _GeneralSettingsTab({required this.onOpenSubpage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final setting = ref.watch(appSettingProvider);
    final themeLabel = switch (themeMode) {
      ThemeMode.system => l10n.auto,
      ThemeMode.light => l10n.light,
      ThemeMode.dark => l10n.dark,
    };
    final languageLabel = locale == null
        ? l10n.defaultText
        : Intl.message(locale);
    void update(AppSettingProps Function(AppSettingProps) builder) {
      ref.read(appSettingProvider.notifier).update(builder);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.appearance),
        SettingsRow(
          icon: QuanXIcons.palette,
          title: l10n.theme,
          subtitle: l10n.themeDesc,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsValue(value: themeLabel),
              const SizedBox(width: 6),
              const SettingsChevron(),
            ],
          ),
          onTap: () => showThemeSettingsModal(context),
        ),
        SettingsRow(
          icon: QuanXIcons.languages,
          title: l10n.language,
          subtitle: l10n.language,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsValue(value: languageLabel),
              const SizedBox(width: 6),
              const SettingsChevron(),
            ],
          ),
          onTap: () => showLanguageSettingsModal(context),
        ),
        SettingsSectionLabel(label: l10n.application),
        SettingsRow(
          icon: QuanXIcons.slidersHorizontal,
          title: l10n.application,
          subtitle: l10n.applicationDesc,
          trailing: const SettingsChevron(),
          onTap: () => onOpenSubpage(
            l10n.application,
            l10n.applicationDesc,
            const ApplicationSettingsPage(),
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cloudSync,
          title: l10n.backupAndRestore,
          subtitle: l10n.backupAndRestoreDesc,
          trailing: const SettingsChevron(),
          onTap: () => onOpenSubpage(
            l10n.backupAndRestore,
            l10n.backupAndRestoreDesc,
            const BackupSettingsPage(),
          ),
        ),
        if (system.isDesktop)
          SettingsRow(
            icon: QuanXIcons.keyboard,
            title: l10n.hotkeyManagement,
            subtitle: l10n.hotkeyManagementDesc,
            trailing: const SettingsChevron(),
            onTap: () => onOpenSubpage(
              l10n.hotkeyManagement,
              l10n.hotkeyManagementDesc,
              const HotkeySettingsPage(),
            ),
          ),
        SettingsSectionLabel(label: l10n.startup),
        SettingsRow(
          icon: QuanXIcons.circlePlay,
          title: l10n.autoLaunch,
          subtitle: l10n.autoLaunchDesc,
          trailing: SettingsSwitch(
            value: setting.autoLaunch,
            onChanged: (value) {
              update((state) => state.copyWith(autoLaunch: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cloudDownload,
          title: l10n.autoCheckUpdate,
          subtitle: l10n.autoCheckUpdateDesc,
          trailing: SettingsSwitch(
            value: setting.autoCheckUpdate,
            onChanged: (value) {
              update((state) => state.copyWith(autoCheckUpdate: value));
            },
          ),
        ),
      ],
    );
  }
}

class _NetworkSettingsTab extends ConsumerWidget {
  final SettingsSubpageOpener onOpenSubpage;

  const _NetworkSettingsTab({required this.onOpenSubpage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final patch = ref.watch(patchClashConfigProvider);
    final port = patch.mixedPort;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.network),
        SettingsRow(
          icon: QuanXIcons.shuffle,
          title: l10n.systemProxy,
          subtitle: '${l10n.port} $port',
          trailing: SettingsSwitch(
            value: systemProxy,
            onChanged: (value) {
              ref
                  .read(networkSettingProvider.notifier)
                  .update((state) => state.copyWith(systemProxy: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.cable,
          title: l10n.tun,
          subtitle: patch.tun.stack.name,
          trailing: SettingsSwitch(
            value: patch.tun.enable,
            onChanged: (value) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .update((state) => state.copyWith.tun(enable: value));
            },
          ),
        ),
        SettingsRow(
          icon: QuanXIcons.arrowRightLeft,
          title: l10n.outboundMode,
          subtitle: l10n.mode,
          trailing: SettingsSelect<Mode>(
            value: patch.mode,
            options: [
              for (final mode in Mode.values)
                SettingsSelectOption(mode, Intl.message(mode.name)),
            ],
            onChanged: (value) {
              ref
                  .read(patchClashConfigProvider.notifier)
                  .update((state) => state.copyWith(mode: value));
            },
          ),
        ),
        SettingsSectionLabel(label: l10n.advanced),
        SettingsRow(
          icon: QuanXIcons.slidersHorizontal,
          title: l10n.basicConfig,
          subtitle: l10n.basicConfigDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            onOpenSubpage(
              l10n.basicConfig,
              l10n.basicConfigDesc,
              const ConfigView(),
            );
          },
        ),
        SettingsRow(
          icon: QuanXIcons.wrench,
          title: l10n.advancedConfig,
          subtitle: l10n.advancedConfigDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            onOpenSubpage(
              l10n.advancedConfig,
              l10n.advancedConfigDesc,
              const AdvancedConfigView(),
            );
          },
        ),
        if (system.isWindows)
          SettingsRow(
            icon: QuanXIcons.lock,
            title: l10n.loopback,
            subtitle: l10n.loopbackDesc,
            trailing: const SettingsChevron(),
            onTap: () {
              windows?.runas(
                '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
                '',
              );
            },
          ),
        if (system.isAndroid)
          SettingsRow(
            icon: QuanXIcons.list,
            title: l10n.accessControl,
            subtitle: l10n.accessControlDesc,
            trailing: const SettingsChevron(),
            onTap: () {
              onOpenSubpage(
                l10n.accessControl,
                l10n.accessControlDesc,
                const AccessView(),
              );
            },
          ),
      ],
    );
  }
}

class _CoreSettingsTab extends ConsumerWidget {
  final SettingsSubpageOpener onOpenSubpage;

  const _CoreSettingsTab({required this.onOpenSubpage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final coreStatus = ref.watch(coreStatusProvider);
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    final statusLabel = switch (coreStatus) {
      CoreStatus.connected => l10n.connected,
      CoreStatus.connecting => l10n.connecting,
      _ => l10n.disconnected,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.core),
        SettingsRow(
          icon: QuanXIcons.cpu,
          title: l10n.settingsCurrentCore,
          subtitle: statusLabel,
          trailing: SettingsValue(value: globalState.packageInfo.version),
        ),
        SettingsRow(
          icon: QuanXIcons.database,
          title: l10n.resources,
          subtitle: l10n.resourcesDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            onOpenSubpage(
              l10n.resources,
              l10n.resourcesDesc,
              const ResourcesView(),
            );
          },
        ),
        SettingsRow(
          icon: QuanXIcons.scrollText,
          title: l10n.settingsOpenLogs,
          subtitle: l10n.logsDesc,
          trailing: const SettingsChevron(),
          onTap: () {
            ref.read(currentPageLabelProvider.notifier).toPage(PageLabel.logs);
          },
        ),
        SettingsSectionLabel(label: l10n.diagnostics),
        SettingsRow(
          icon: QuanXIcons.cpu,
          title: l10n.developerMode,
          subtitle: l10n.settingsDesc,
          trailing: SettingsSwitch(
            value: developerMode,
            onChanged: (value) {
              ref
                  .read(appSettingProvider.notifier)
                  .update((state) => state.copyWith(developerMode: value));
            },
          ),
        ),
      ],
    );
  }
}

class _AboutSettingsTab extends ConsumerWidget {
  const _AboutSettingsTab();

  Future<void> _checkUpdate(BuildContext context) async {
    final data = await globalState.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: context.appLocalizations.checkUpdate,
    );
    globalState.container
        .read(commonActionProvider.notifier)
        .checkUpdateResultHandle(data: data, isUser: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.appLocalizations;
    final version = globalState.packageInfo.version;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        SettingsSectionLabel(label: l10n.version),
        SettingsRow(
          icon: QuanXIcons.info,
          title: appName,
          subtitle: version,
          trailing: SettingsGhostButton(
            label: l10n.checkUpdate,
            onPressed: () => _checkUpdate(context),
          ),
        ),
        SettingsSectionLabel(label: l10n.links),
        SettingsRow(
          icon: QuanXIcons.externalLink,
          title: l10n.project,
          subtitle: 'github.com/$repository',
          trailing: const SettingsChevron(),
          onTap: () {
            globalState.openUrl('https://github.com/$repository');
          },
        ),
        SettingsRow(
          icon: QuanXIcons.library,
          title: l10n.licenses,
          subtitle: l10n.settingsAboutApp,
          trailing: const SettingsChevron(),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: appName,
              applicationVersion: version,
            );
          },
        ),
        SettingsRow(
          icon: QuanXIcons.scale,
          title: l10n.disclaimer,
          subtitle: l10n.settingsAboutApp,
          trailing: const SettingsChevron(),
          onTap: () async {
            final accepted = await globalState.showDisclaimer();
            if (!accepted) {
              await ref.read(systemActionProvider.notifier).handleExit();
            }
          },
        ),
      ],
    );
  }
}
