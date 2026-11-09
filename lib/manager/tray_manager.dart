import 'package:quanclash/common/common.dart';
import 'package:quanclash/providers/action.dart';
import 'package:quanclash/providers/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayManager extends ConsumerStatefulWidget {
  final Widget child;

  const TrayManager({super.key, required this.child});

  @override
  ConsumerState<TrayManager> createState() => _TrayContainerState();
}

class _TrayContainerState extends ConsumerState<TrayManager> with TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    ref.listenManual(trayStateProvider, (prev, next) {
      if (prev != next) {
        ref.read(systemActionProvider.notifier).updateTray();
      }
    });
    if (system.isMacOS) {
      ref.listenManual(trayTitleStateProvider, (prev, next) {
        if (prev != next) {
          tray?.updateTrayTitle(
            showTrayTitle: next.showTrayTitle,
            traffic: next.traffic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onTrayIconRightMouseDown() {
    // ignore: deprecated_member_use
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    render?.active();
    super.onTrayMenuItemClick(menuItem);
  }

  @override
  void onTrayIconMouseDown() async {
    final currentWindow = window;
    if (currentWindow == null) {
      return;
    }
    final isVisible = await currentWindow.isVisible;
    // 托盘图标 = 面板入口:面板已弹出则收起,否则一律弹出面板
    if (isVisible && currentWindow.isPanelMode) {
      await currentWindow.hide();
      return;
    }
    await currentWindow.showPanel();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }
}
