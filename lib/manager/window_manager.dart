import 'dart:async';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_ext/window_ext.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 11 关闭按钮的悬停 / 按下底色。
const Color _captionCloseHover = Color(0xFFC42B1C);
const Color _captionClosePressed = Color(0xFFB02418);

class WindowManager extends ConsumerStatefulWidget {
  final Widget child;

  const WindowManager({super.key, required this.child});

  @override
  ConsumerState<WindowManager> createState() => _WindowContainerState();
}

class _WindowContainerState extends ConsumerState<WindowManager>
    with WindowListener, WindowExtListener {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    if (!uiPreviewMode) {
      ref.listenManual(appSettingProvider.select((state) => state.autoLaunch), (
        prev,
        next,
      ) {
        if (prev != next) {
          debouncer.call(FunctionTag.autoLaunch, () {
            autoLaunch?.updateStatus(next);
          });
        }
      });
    }
    windowExtManager.addListener(this);
    windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncMaximized();
    });
  }

  Future<void> _syncMaximized() async {
    if (!mounted) {
      return;
    }
    final isMaximized = await windowManager.isMaximized();
    if (!mounted) {
      return;
    }
    ref.read(isMaximizedProvider.notifier).value = isMaximized;
  }

  @override
  void onWindowClose() async {
    await ref.read(systemActionProvider.notifier).handleClose();
    super.onWindowClose();
  }

  @override
  void onWindowFocus() {
    super.onWindowFocus();
    commonPrint.log('focus');
    render?.resume();
  }

  @override
  void onWindowBlur() {
    super.onWindowBlur();
    final currentWindow = window;
    if (currentWindow == null || !currentWindow.isPanelMode) {
      return;
    }
    final shownAt = currentWindow.panelShownAt;
    if (shownAt != null &&
        DateTime.now().difference(shownAt) <
            const Duration(milliseconds: 600)) {
      return;
    }
    currentWindow.hidePanel();
  }

  @override
  Future<void> onShouldTerminate() async {
    await ref.read(systemActionProvider.notifier).handleExit();
    super.onShouldTerminate();
  }

  @override
  void onWindowMoved() {
    super.onWindowMoved();
    if (window?.isPanelMode ?? false) {
      return;
    }
    windowManager.getPosition().then((offset) {
      ref
          .read(windowSettingProvider.notifier)
          .update((state) => state.copyWith(top: offset.dy, left: offset.dx));
    });
  }

  @override
  Future<void> onWindowResized() async {
    super.onWindowResized();
    _syncMaximized();
    if (window?.isPanelMode ?? false) {
      return;
    }
    final size = await windowManager.getSize();
    ref
        .read(windowSettingProvider.notifier)
        .update(
          (state) => state.copyWith(width: size.width, height: size.height),
        );
  }

  @override
  void onWindowMinimize() async {
    ref.read(storeActionProvider.notifier).savePreferencesDebounce();
    commonPrint.log('minimize');
    render?.pause();
    super.onWindowMinimize();
  }

  @override
  void onWindowRestore() {
    commonPrint.log('restore');
    render?.resume();
    _syncMaximized();
    super.onWindowRestore();
  }

  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    if (mounted) {
      ref.read(isMaximizedProvider.notifier).value = true;
    }
  }

  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    if (mounted) {
      ref.read(isMaximizedProvider.notifier).value = false;
    }
  }

  @override
  Future<void> dispose() async {
    windowManager.removeListener(this);
    windowExtManager.removeListener(this);
    super.dispose();
  }
}

class WindowHeaderContainer extends StatelessWidget {
  final Widget child;

  const WindowHeaderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: panelModeNotifier,
      builder: (_, isPanel, child) {
        if (isPanel) {
          return child!;
        }
        return Consumer(
          builder: (_, ref, child) {
            final isMobileView = ref.watch(isMobileViewProvider);
            final version = ref.watch(versionProvider);
            if ((version <= 10 || !isMobileView) && system.isMacOS) {
              return child!;
            }
            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(height: kHeaderHeight),
                    Expanded(flex: 1, child: child!),
                  ],
                ),
                const WindowHeader(),
              ],
            );
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

class WindowHeader extends ConsumerStatefulWidget {
  const WindowHeader({super.key});

  @override
  ConsumerState<WindowHeader> createState() => _WindowHeaderState();
}

class _WindowHeaderState extends ConsumerState<WindowHeader> {
  final isPinNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initNotifier();
  }

  Future<void> _initNotifier() async {
    try {
      final maximized = await windowManager.isMaximized();
      final pinned = await windowManager.isAlwaysOnTop();
      if (!mounted) {
        return;
      }
      ref.read(isMaximizedProvider.notifier).value = maximized;
      isPinNotifier.value = pinned;
    } catch (_) {
      // Ignore platform channel errors in headless widget tests.
    }
  }

  @override
  void dispose() {
    isPinNotifier.dispose();
    super.dispose();
  }

  Future<void> _updateMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (isMaximized) {
      await windowManager.unmaximize();
      if (system.isWindows) {
        windowExtManager.setWindowCornerPreference(round: true);
      }
    } else {
      await windowManager.maximize();
      if (system.isWindows) {
        windowExtManager.setWindowCornerPreference(round: false);
      }
    }
    final res = await windowManager.isMaximized();
    if (mounted) {
      ref.read(isMaximizedProvider.notifier).value = res;
    }
  }

  Future<void> _updatePin() async {
    final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    await windowManager.setAlwaysOnTop(!isAlwaysOnTop);
    if (mounted) {
      isPinNotifier.value = await windowManager.isAlwaysOnTop();
    }
  }

  Widget _buildActions(bool isMaximized) {
    final isDark = context.isQuanXDark;
    final primary = context.colorScheme.primary;
    final separatorColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : const Color(0x160F172A);

    return Row(
      children: [
        // 置顶是应用内动作，与原生窗口按钮以极细竖线分隔。
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ValueListenableBuilder<bool>(
            valueListenable: isPinNotifier,
            builder: (context, pinned, _) {
              return _TitleBarButton(
                onPressed: _updatePin,
                width: 30,
                height: 26,
                iconSize: 13.5,
                borderRadius: BorderRadius.circular(6),
                cursor: SystemMouseCursors.click,
                color: pinned ? primary : context.quanX.textSecondary,
                backgroundColor: pinned
                    ? primary.withValues(alpha: isDark ? 0.18 : 0.10)
                    : Colors.transparent,
                hoverColor: primary.withValues(alpha: isDark ? 0.16 : 0.09),
                highlightColor: primary.withValues(alpha: isDark ? 0.22 : 0.15),
                icon: const Icon(QuanXIcons.pin),
              );
            },
          ),
        ),
        Container(
          width: 1,
          height: 14,
          margin: const EdgeInsets.only(right: 2),
          color: separatorColor,
        ),
        _TitleBarButton(
          onPressed: () {
            windowManager.minimize();
          },
          icon: const _WindowsCaptionGlyph(WindowsCaptionGlyphType.minimize),
        ),
        _TitleBarButton(
          onPressed: _updateMaximized,
          icon: _WindowsCaptionGlyph(
            isMaximized
                ? WindowsCaptionGlyphType.restore
                : WindowsCaptionGlyphType.maximize,
          ),
        ),
        _TitleBarButton(
          onPressed: () {
            globalState.container
                .read(systemActionProvider.notifier)
                .handleClose();
          },
          hoverForeground: Colors.white,
          hoverColor: _captionCloseHover,
          highlightColor: _captionClosePressed,
          icon: const _WindowsCaptionGlyph(WindowsCaptionGlyphType.close),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isQuanXDark;
    final isMaximized = ref.watch(isMaximizedProvider);
    final bgTop = isDark ? const Color(0xFF171920) : const Color(0xFFFCFCFE);
    final bgBottom = isDark ? const Color(0xFF13151B) : const Color(0xFFF6F7FA);
    final bottomLine = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0x120F172A);

    // 子树高度必须严格等于 kHeaderHeight，避免吞掉下方点击。
    return SizedBox(
      height: kHeaderHeight,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgTop, bgBottom],
            ),
            border: Border(bottom: BorderSide(color: bottomLine, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    windowManager.startDragging();
                  },
                  onDoubleTap: () {
                    _updateMaximized();
                  },
                  child: system.isMacOS
                      ? const Center(child: Text(appName))
                      : const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: _WindowHeaderBrand(),
                        ),
                ),
              ),
              if (!system.isMacOS) _buildActions(isMaximized),
            ],
          ),
        ),
      ),
    );
  }
}

/// Native Windows 11 Segoe Fluent caption glyph types.
enum WindowsCaptionGlyphType { minimize, maximize, restore, close }

/// Crisp 10×10 geometric hairline caption glyph matching native Windows 11
/// title bar controls (`─`, `□`, `❐`, `×`) with pixel-aligned 1px strokes.
class _WindowsCaptionGlyph extends StatelessWidget {
  const _WindowsCaptionGlyph(this.type);

  final WindowsCaptionGlyphType type;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF1C1C22);
    return CustomPaint(
      size: const Size(10, 10),
      painter: _WindowsCaptionGlyphPainter(type: type, color: color),
    );
  }
}

class _WindowsCaptionGlyphPainter extends CustomPainter {
  const _WindowsCaptionGlyphPainter({
    required this.type,
    required this.color,
  });

  final WindowsCaptionGlyphType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.05
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    switch (type) {
      case WindowsCaptionGlyphType.minimize:
        canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          paint,
        );
      case WindowsCaptionGlyphType.maximize:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.5, 0.5, 9, 9),
            const Radius.circular(0.8),
          ),
          paint,
        );
      case WindowsCaptionGlyphType.restore:
        // Front square (bottom-left 7.2×7.2) + crisp rear top-right L-frame,
        // matching the exact Windows 11 Fluent restore icon with no interior
        // crossing lines.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.5, 2.3, 7.2, 7.2),
            const Radius.circular(0.6),
          ),
          paint,
        );
        final back = Path()
          ..moveTo(2.3, 2.3)
          ..lineTo(2.3, 1.2)
          ..quadraticBezierTo(2.3, 0.5, 3.0, 0.5)
          ..lineTo(8.8, 0.5)
          ..quadraticBezierTo(9.5, 0.5, 9.5, 1.2)
          ..lineTo(9.5, 7.0)
          ..quadraticBezierTo(9.5, 7.7, 8.8, 7.7)
          ..lineTo(7.7, 7.7);
        canvas.drawPath(back, paint);
      case WindowsCaptionGlyphType.close:
        canvas.drawLine(const Offset(0.5, 0.5), const Offset(9.5, 9.5), paint);
        canvas.drawLine(const Offset(9.5, 0.5), const Offset(0.5, 9.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsCaptionGlyphPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}

/// 标题栏按钮:按 Windows 11 原生 Fluent 标题栏比例与微交互绘制。
class _TitleBarButton extends StatefulWidget {
  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.width = 46,
    this.height,
    this.iconSize = 13,
    this.color,
    this.backgroundColor = Colors.transparent,
    this.hoverForeground,
    this.hoverColor,
    this.highlightColor,
    this.borderRadius = BorderRadius.zero,
    this.cursor = SystemMouseCursors.basic,
  });

  final Widget icon;
  final VoidCallback onPressed;
  final double width;
  final double? height;
  final double iconSize;
  final Color? color;
  final Color backgroundColor;
  final Color? hoverForeground;
  final Color? hoverColor;
  final Color? highlightColor;
  final BorderRadius borderRadius;
  final MouseCursor cursor;

  @override
  State<_TitleBarButton> createState() => _TitleBarButtonState();
}

class _TitleBarButtonState extends State<_TitleBarButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isQuanXDark;
    final defaultColor =
        widget.color ??
        (isDark ? const Color(0xFFE6E8EE) : const Color(0xFF1F2329));
    final hoverColor =
        widget.hoverColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0x0B0F172A));
    final highlightColor =
        widget.highlightColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.14)
            : const Color(0x140F172A));
    final activeBg = _pressed
        ? highlightColor
        : (_hovered || _focused ? hoverColor : widget.backgroundColor);
    final foreground = _hovered || _pressed || _focused
        ? widget.hoverForeground ?? defaultColor
        : defaultColor;

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: Focus(
          onFocusChange: (value) => setState(() => _focused = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            width: widget.width,
            height: widget.height ?? double.infinity,
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: widget.borderRadius,
            ),
            child: IconTheme(
              data: IconThemeData(color: foreground, size: widget.iconSize),
              child: Center(child: widget.icon),
            ),
          ),
        ),
      ),
    );
  }
}

class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icon.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _WindowHeaderBrand extends StatelessWidget {
  const _WindowHeaderBrand();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isQuanXDark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(size: 17),
        const SizedBox(width: 8),
        Text(
          appName,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: isDark ? const Color(0xFFDDE0E8) : const Color(0xFF2B2F38),
          ),
        ),
      ],
    );
  }
}
