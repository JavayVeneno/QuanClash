import 'dart:async';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_ext/window_ext.dart';
import 'package:window_manager/window_manager.dart';

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
    currentWindow.hide();
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

class WindowHeader extends StatefulWidget {
  const WindowHeader({super.key});

  @override
  State<WindowHeader> createState() => _WindowHeaderState();
}

class _WindowHeaderState extends State<WindowHeader> {
  final isMaximizedNotifier = ValueNotifier<bool>(false);
  final isPinNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initNotifier();
  }

  Future<void> _initNotifier() async {
    isMaximizedNotifier.value = await windowManager.isMaximized();
    isPinNotifier.value = await windowManager.isAlwaysOnTop();
  }

  @override
  void dispose() {
    isMaximizedNotifier.dispose();
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
    globalState.container.read(isMaximizedProvider.notifier).value = res;
    if (mounted) {
      isMaximizedNotifier.value = res;
    }
  }

  Future<void> _updatePin() async {
    final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    await windowManager.setAlwaysOnTop(!isAlwaysOnTop);
    isPinNotifier.value = await windowManager.isAlwaysOnTop();
  }

  Widget _buildActions() {
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            _updatePin();
          },
          icon: ValueListenableBuilder(
            valueListenable: isPinNotifier,
            builder: (_, value, _) {
              return value
                  ? const Icon(QuanXIcons.pin)
                  : const Icon(QuanXIcons.pin);
            },
          ),
        ),
        IconButton(
          onPressed: () {
            windowManager.minimize();
          },
          icon: const Icon(QuanXIcons.minus),
        ),
        IconButton(
          onPressed: () async {
            _updateMaximized();
          },
          icon: ValueListenableBuilder(
            valueListenable: isMaximizedNotifier,
            builder: (_, value, _) {
              return value
                  ? const Icon(QuanXIcons.squareStack, size: 20)
                  : const Icon(QuanXIcons.square);
            },
          ),
        ),
        IconButton(
          onPressed: () {
            globalState.container
                .read(systemActionProvider.notifier)
                .handleClose();
          },
          icon: const Icon(QuanXIcons.x),
        ),
        // const SizedBox(
        //   width: 8,
        // ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    // 子树高度必须严格等于 kHeaderHeight。
    //
    // 之前是 Material > Align > Container(height: kHeaderHeight) 的结构:Align 在
    // Stack 的松散约束下会撑满整个窗口,导致里层的 Material(PhysicalModel)一并
    // 覆盖全屏,吞掉标题栏以外的所有点击 —— 表现为「鼠标点不动,只有 Tab 能用」。
    return SizedBox(
      height: kHeaderHeight,
      width: double.infinity,
      child: Material(
        color: glass.tintStrong,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: glass.divider),
            ),
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
              if (!system.isMacOS) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class AppIcon extends StatelessWidget {
  final double size;

  const AppIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final scale = size / 34;
    return Container(
      decoration: ShapeDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(14 * scale),
        ),
      ),
      padding: EdgeInsets.all(8 * scale),
      child: Transform.translate(
        offset: Offset(0, -1 * scale),
        child: Image.asset('assets/images/icon.png', width: size, height: size),
      ),
    );
  }
}

class _WindowHeaderBrand extends StatelessWidget {
  const _WindowHeaderBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIcon(),
        const SizedBox(width: 7),
        Text(
          appName,
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.quanX.textPrimary,
          ),
        ),
      ],
    );
  }
}
