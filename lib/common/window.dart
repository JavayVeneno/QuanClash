import 'dart:io';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/config.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

/// 托盘面板模式:true 时窗口以小面板形式展示
final panelModeNotifier = ValueNotifier<bool>(false);

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
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
  }

  Rect? _panelEnteredBounds;
  DateTime? _panelShownAt;

  bool get isPanelMode => panelModeNotifier.value;

  DateTime? get panelShownAt => _panelShownAt;

  Future<void> showPanel() async {
    _panelEnteredBounds ??= await windowManager.getBounds();
    panelModeNotifier.value = true;
    _panelShownAt = DateTime.now();
    final display = await screenRetriever.getPrimaryDisplay();
    const panelSize = Size(340, 332);
    final visiblePosition = display.visiblePosition ?? Offset.zero;
    final visibleSize = display.visibleSize ?? display.size;
    final left = visiblePosition.dx + visibleSize.width - panelSize.width - 12;
    final top = visiblePosition.dy + visibleSize.height - panelSize.height - 12;
    render?.resume();
    await windowManager.setResizable(false);
    await windowManager.setBounds(
      Rect.fromLTWH(left, top, panelSize.width, panelSize.height),
    );
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(true);
  }

  Future<void> showMain() async {
    panelModeNotifier.value = false;
    render?.resume();
    await windowManager.setResizable(true);
    final bounds = _panelEnteredBounds;
    _panelEnteredBounds = null;
    if (bounds != null) {
      await windowManager.setBounds(bounds);
    }
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setSkipTaskbar(false);
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
}

final window = system.isDesktop ? Window() : null;
