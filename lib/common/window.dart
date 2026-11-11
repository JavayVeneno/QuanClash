import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/config.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// 托盘面板模式:true 时窗口以小面板形式展示
final panelModeNotifier = ValueNotifier<bool>(false);

/// 托盘面板的窗口尺寸(逻辑像素),与 `PanelView` 的布局一一对应。
const Size panelWindowSize = Size(360, 430);

/// 面板与工作区边缘的留白。
const double _panelWindowMargin = 12;

/// 主窗口的最小尺寸;进入面板模式时必须放开,否则 360x430 会被钳到
/// 380x400,窗口右/下边缘被推出屏幕。
const Size _mainWindowMinimumSize = Size(380, 400);

/// 面板因失焦收起后,短时间内把托盘点击视为「关闭」,避免收起后立刻重开。
const Duration _panelBlurGuard = Duration(milliseconds: 700);

/// 计算面板窗口的位置:贴工作区右下角,并保证整个窗口落在工作区内。
///
/// [size] 必须传窗口的**真实**尺寸——系统可能按最小尺寸钳制窗口,用设计
/// 尺寸算出来的位置会让底栏(「打开 QuanClash」)落到工作区外。
Rect panelBoundsFor(
  Rect workArea,
  Size size, {
  double margin = _panelWindowMargin,
}) {
  final left = math.max(
    workArea.left + margin,
    workArea.right - size.width - margin,
  );
  final top = math.max(
    workArea.top + margin,
    workArea.bottom - size.height - margin,
  );
  return Rect.fromLTWH(left, top, size.width, size.height);
}

class Window {
  static Window? _instance;

  Window._internal();

  factory Window() {
    _instance ??= Window._internal();
    return _instance!;
  }

  Future<void> init(int version, WindowProps props) async {
    final acquire = await singleInstanceLock.acquire();
    if (!acquire) {
      exit(0);
    }
    if (system.isWindows) {
      protocol.register('clash');
      protocol.register('clashmeta');
      protocol.register('quanclash');
    }
    await windowManager.ensureInitialized();
    // kDebugMode ? Size(680, 580) :
    final WindowOptions windowOptions = WindowOptions(
      size: props.size,
      minimumSize: const Size(380, 400),
    );
    if (!system.isMacOS || version > 10) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    }
    await windowManager.setMaximizable(true);
    await _windowPosition(props);
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPreventClose(true);
    });
  }

  Future<void> _windowPosition(WindowProps props) async {
    if (!system.isMacOS) {
      final left = props.left ?? 0;
      final top = props.top ?? 0;
      final right = left + props.width;
      final bottom = top + props.height;
      if (left == 0 && top == 0) {
        await windowManager.setAlignment(Alignment.center);
      } else {
        final displays = await screenRetriever.getAllDisplays();
        final isPositionValid = displays.any((display) {
          final displayBounds = Rect.fromLTWH(
            display.visiblePosition!.dx,
            display.visiblePosition!.dy,
            display.size.width,
            display.size.height,
          );
          return displayBounds.contains(Offset(left, top)) ||
              displayBounds.contains(Offset(right, bottom));
        });
        if (isPositionValid) {
          await windowManager.setPosition(Offset(left, top));
        }
      }
    }
  }

  Future<void> show() async {
    render?.resume();
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
  }

  Rect? _panelEnteredBounds;
  bool _panelEnteredMaximized = false;
  DateTime? _panelShownAt;
  DateTime? _panelHiddenAt;

  bool get isPanelMode => panelModeNotifier.value;

  DateTime? get panelShownAt => _panelShownAt;

  /// 面板是否刚刚因为失焦而收起。
  bool get wasPanelJustHidden {
    final hiddenAt = _panelHiddenAt;
    return hiddenAt != null &&
        DateTime.now().difference(hiddenAt) < _panelBlurGuard;
  }

  Future<void> showPanel() async {
    if (!panelModeNotifier.value) {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      _panelEnteredMaximized = await windowManager.isMaximized();
      _panelEnteredBounds = await windowManager.getBounds();
      panelModeNotifier.value = true;
    }
    _panelShownAt = DateTime.now();
    _panelHiddenAt = null;
    render?.resume();
    // 面板比主窗口最小尺寸更小:先放开最小尺寸,否则 Windows 会把
    // 360x430 钳制到 380x400,窗口右下角超出屏幕。
    await windowManager.setMinimumSize(Size.zero);
    await windowManager.setResizable(false);
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    }
    final workArea = await _workArea();
    final target = panelBoundsFor(workArea, panelWindowSize);
    await windowManager.setBounds(target);
    await windowManager.show();
    await windowManager.setSkipTaskbar(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.focus();
    // 系统仍可能按最小/最大尺寸钳制窗口;用真实尺寸重新贴一次边。
    final actual = await windowManager.getBounds();
    if (actual.size != panelWindowSize) {
      final corrected = panelBoundsFor(workArea, actual.size).topLeft;
      if (corrected != actual.topLeft) {
        await windowManager.setPosition(corrected);
      }
    }
  }

  Future<void> showMain() async {
    panelModeNotifier.value = false;
    _panelHiddenAt = null;
    render?.resume();
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(_mainWindowMinimumSize);
    final bounds = _panelEnteredBounds;
    final wasMaximized = _panelEnteredMaximized;
    _panelEnteredBounds = null;
    _panelEnteredMaximized = false;
    // 先恢复尺寸再显示,避免主界面在面板尺寸下闪一帧。
    if (wasMaximized) {
      await windowManager.maximize();
    } else if (bounds != null) {
      await windowManager.setBounds(bounds);
    } else {
      await windowManager.setAlignment(Alignment.center);
    }
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
    await windowManager.focus();
  }

  /// 工作区的逻辑像素范围。
  ///
  /// `screen_retriever` 返回的是已经除过它自己 `scaleFactor` 的值,而
  /// `windowManager.setBounds` 把入参当逻辑像素再乘一次 DPR。Windows 上
  /// 两者偶尔不一致(例如 125% 缩放时 `screen_retriever` 仍报告 1.0),
  /// 直接相减会把面板推到屏幕外,所以按两者比例换算。
  Future<Rect> _workArea() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final reportedScale = display.scaleFactor ?? dpr;
    final factor = reportedScale > 0 && dpr > 0 ? reportedScale / dpr : 1.0;
    final position = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return Rect.fromLTWH(
      position.dx * factor,
      position.dy * factor,
      size.width * factor,
      size.height * factor,
    );
  }

  Future<bool> get isVisible async {
    final value = await windowManager.isVisible();
    commonPrint.log('window visible check: $value');
    return value;
  }

  Future<void> close() async {
    await windowManager.close();
  }

  void forceExit() {
    exit(0);
  }

  Future<void> hide() async {
    render?.pause();
    await windowManager.hide();
    await windowManager.setSkipTaskbar(true);
  }

  /// 面板因失焦自动收起。记录时间,让随后的托盘点击不会把面板立刻重开。
  Future<void> hidePanel() async {
    if (!isPanelMode) {
      await hide();
      return;
    }
    _panelHiddenAt = DateTime.now();
    await hide();
  }
}

final window = system.isDesktop ? Window() : null;
