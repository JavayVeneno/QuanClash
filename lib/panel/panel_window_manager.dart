import 'dart:async';
import 'dart:ui';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/panel/panel_state.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';

/// 主引擎侧的托盘面板窗口。
///
/// 面板运行在独立 Flutter 引擎里(见 [runPanelWindow]),主窗口不会被缩放或
/// 隐藏;这里负责创建窗口、推送状态快照并执行面板发回来的命令。
class PanelWindowManager {
  static const String windowArgument = 'panel';
  static const Size windowSize = Size(360, 430);

  static const Duration _blurGuard = Duration(milliseconds: 700);
  static const Duration _stateInterval = Duration(milliseconds: 500);

  /// A hidden panel keeps a second Flutter engine alive. Release it once the
  /// panel has been closed for a while; the next open recreates it on demand.
  static const Duration _destroyAfterHide = Duration(seconds: 60);

  static final PanelWindowManager instance = PanelWindowManager._();

  PanelWindowManager._();

  WindowController? _controller;
  WindowController? _mainController;
  ProviderContainer? _container;
  Future<WindowController?>? _creating;
  Timer? _stateTimer;
  Timer? _destroyTimer;
  bool _visible = false;
  DateTime? _hiddenAt;
  bool _initialized = false;

  /// 独立面板窗口目前只在 Windows 上实现;其他平台继续使用单窗口面板。
  bool get isSupported => system.isWindows;

  bool get isVisible => _visible;

  bool get wasJustHidden {
    final hiddenAt = _hiddenAt;
    return hiddenAt != null && DateTime.now().difference(hiddenAt) < _blurGuard;
  }

  Future<void> init() async {
    if (!isSupported || _initialized) {
      return;
    }
    _initialized = true;
    _container = globalState.container;
    try {
      _mainController = await WindowController.fromCurrentEngine();
      await _mainController?.setWindowMethodHandler(_handlePanelCall);
      // 面板失焦时原生侧会直接隐藏窗口,并通过事件通道通知主引擎。
      WindowController.onWindowEvent.listen((call) {
        if (call.method == PanelEvent.blur) {
          _markHidden();
        }
      });
    } catch (e) {
      commonPrint.log('panel window init failed: $e');
      return;
    }
    // The panel engine is created on first use and released after it has been
    // closed for a while. Pre-creating it kept a second Flutter engine (and
    // its raster/UI threads) resident for the whole session.
  }

  Future<void> toggle() async {
    if (!isSupported) {
      return;
    }
    if (_visible) {
      await hide();
      return;
    }
    // 面板刚刚因失焦收起:这次托盘点击只当作「关闭」。
    if (wasJustHidden) {
      return;
    }
    await show();
  }

  Future<void> show() async {
    _destroyTimer?.cancel();
    _destroyTimer = null;
    final controller = await _ensureCreated();
    if (controller == null) {
      return;
    }
    await _pushState();
    try {
      await controller.show();
    } catch (e) {
      commonPrint.log('panel window show failed: $e');
      return;
    }
    _visible = true;
    _hiddenAt = null;
    _startStateTimer();
  }

  void _markHidden() {
    _visible = false;
    _hiddenAt = DateTime.now();
    _stopStateTimer();
    _destroyTimer?.cancel();
    _destroyTimer = Timer(_destroyAfterHide, () {
      unawaited(_destroy());
    });
  }

  Future<void> _destroy() async {
    _destroyTimer = null;
    if (_visible) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    // Clear the handle before awaiting so a concurrent show() creates a fresh
    // window instead of racing with the one being destroyed.
    _controller = null;
    try {
      await controller.close();
    } catch (e) {
      commonPrint.log('panel window close failed: $e');
    }
  }

  Future<void> hide() async {
    _markHidden();
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.hide();
    } catch (e) {
      commonPrint.log('panel window hide failed: $e');
    }
  }

  Future<WindowController?> _ensureCreated() async {
    final existing = _controller;
    if (existing != null) {
      return existing;
    }
    final pending = _creating;
    if (pending != null) {
      return pending;
    }
    final future = _create();
    _creating = future;
    try {
      return await future;
    } finally {
      _creating = null;
    }
  }

  Future<WindowController?> _create() async {
    try {
      final frame = panelBoundsFor(await _workArea(), windowSize);
      final controller = await WindowController.create(
        WindowConfiguration(
          arguments: windowArgument,
          hiddenAtLaunch: true,
          frame: frame,
          alwaysOnTop: true,
          skipTaskbar: true,
          frameless: true,
        ),
      );
      _controller = controller;
      return controller;
    } catch (e) {
      commonPrint.log('panel window create failed: $e');
      return null;
    }
  }

  /// 工作区的逻辑像素范围(与 [panelBoundsFor] 使用同一套坐标系)。
  Future<Rect> _workArea() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
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

  PanelState _readState() {
    final container = _container ?? globalState.container;
    final isStart = container.read(isStartProvider);
    final coreStatus = container.read(coreStatusProvider);
    final runTime = container.read(runTimeProvider);
    final traffics = container.read(trafficsProvider).list;
    final mode = container.read(patchClashConfigProvider).mode;
    final systemProxy = container.read(networkSettingProvider).systemProxy;
    final tunEnable = container.read(patchClashConfigProvider).tun.enable;
    final port = container.read(trayStateProvider).port;
    final groups = container.read(groupsProvider);
    final selectedMap = container.read(selectedMapProvider);
    // mihomo's GLOBAL selector defaults to DIRECT; without this the panel
    // always showed "GLOBAL / DIRECT" while rule mode used a real node.
    final group = computeCurrentGroup(
      groups,
      preferredName: container.read(currentProfileProvider)?.currentGroupName,
      selectedMap: selectedMap,
    );
    final proxyName = group == null
        ? null
        : computeRealSelectedProxyState(
            group.now ?? '',
            groups: groups,
            selectedMap: selectedMap,
          ).proxyName;
    final lastTraffic = traffics.isNotEmpty ? traffics.last : const Traffic();
    final delayMap = container.read(delayDataSourceProvider);
    final testUrl = group?.testUrl.takeFirstValid([
      container.read(appSettingProvider).testUrl,
    ]);
    final delay = proxyName == null || proxyName.isEmpty
        ? null
        : delayMap[testUrl]?[proxyName];
    final themeProps = container.read(themeSettingProvider);
    final locale = container.read(appSettingProvider).locale;
    return PanelState(
      isStart: isStart,
      coreStatus: coreStatus.name,
      runTime: runTime,
      mode: mode.index,
      port: port,
      up: lastTraffic.up,
      down: lastTraffic.down,
      groupName: group?.name,
      proxyName: proxyName,
      delay: delay,
      systemProxy: systemProxy,
      tun: tunEnable,
      locale: locale,
      themeMode: themeProps.themeMode.name,
      primaryColor: themeProps.primaryColor,
      schemeVariant: themeProps.schemeVariant.name,
      pureBlack: themeProps.pureBlack,
    );
  }

  Future<void> _pushState() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    try {
      await controller.invokeMethod(PanelEvent.state, _readState().toJson());
    } catch (e) {
      commonPrint.log('panel state push failed: $e');
    }
  }

  void _startStateTimer() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(_stateInterval, (_) {
      unawaited(_pushState());
    });
  }

  void _stopStateTimer() {
    _stateTimer?.cancel();
    _stateTimer = null;
  }

  Future<dynamic> _handlePanelCall(MethodCall call) async {
    final container = _container ?? globalState.container;
    switch (call.method) {
      case PanelEvent.blur:
        _markHidden();
        break;
      case PanelCommand.toggleStart:
        final isStart = container.read(isStartProvider);
        debouncer.call(FunctionTag.updateStatus, () {
          container
              .read(setupActionProvider.notifier)
              .updateStatus(!isStart, isInit: !container.read(initProvider));
        }, duration: commonDuration);
        _pushStateSoon();
        break;
      case PanelCommand.setMode:
        final index = call.arguments is int ? call.arguments as int : 0;
        if (index >= 0 && index < Mode.values.length) {
          container
              .read(setupActionProvider.notifier)
              .changeMode(Mode.values[index]);
        }
        _pushStateSoon();
        break;
      case PanelCommand.setSystemProxy:
        final value = call.arguments as bool? ?? false;
        container
            .read(networkSettingProvider.notifier)
            .update((state) => state.copyWith(systemProxy: value));
        _pushStateSoon();
        break;
      case PanelCommand.setTun:
        final value = call.arguments as bool? ?? false;
        container
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith.tun(enable: value));
        _pushStateSoon();
        break;
      case PanelCommand.openMain:
        final page = call.arguments is String ? call.arguments as String : null;
        await hide();
        await window?.show();
        if (page != null) {
          for (final label in PageLabel.values) {
            if (label.name == page) {
              container.read(currentPageLabelProvider.notifier).toPage(label);
              break;
            }
          }
        }
        break;
      case PanelCommand.hide:
        await hide();
        break;
      case PanelCommand.exit:
        await container.read(systemActionProvider.notifier).handleExit();
        break;
    }
    return null;
  }

  void _pushStateSoon() {
    Timer(const Duration(milliseconds: 120), () {
      unawaited(_pushState());
    });
  }
}

final panelWindow = PanelWindowManager.instance;
