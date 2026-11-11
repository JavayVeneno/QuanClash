import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:quanclash/common/quanx.dart';
import 'package:quanclash/common/utils.dart';
import 'package:quanclash/l10n/l10n.dart';
import 'package:quanclash/panel/panel_state.dart';
import 'package:quanclash/views/panel/panel_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

const _defaultPrimaryColor = Color(0xFF6C5CE7);

/// 面板独立窗口的入口:建立与主引擎的命令通道,然后渲染面板。
///
/// 这个函数由 `main.dart` 在第二个 Flutter 引擎里调用,不能触碰主引擎的
/// Riverpod 容器、托盘或 mihomo。
Future<void> runPanelWindow() async {
  final controller = await _waitForController();

  WindowController? mainController;
  try {
    for (final item in await WindowController.getAll()) {
      if (item.windowId != controller.windowId) {
        mainController = item;
        break;
      }
    }
  } catch (_) {}

  final state = ValueNotifier<PanelState>(const PanelState());

  await controller.setWindowMethodHandler((call) async {
    if (call.method == PanelEvent.state) {
      final arguments = call.arguments;
      if (arguments is Map) {
        state.value = PanelState.fromJson(Map<String, dynamic>.from(arguments));
      }
    }
    return null;
  });

  runApp(
    PanelWindowApp(
      state: state,
      controller: controller,
      mainController: mainController,
    ),
  );
}

/// 等待原生侧注册好窗口通道。
///
/// 子引擎的原生通道是在 `MultiWindowManager::Create` 里、引擎启动之后才注册的,
/// release(AOT)下 Dart 的 `main` 会抢在前面执行,直接调用会拿到
/// `MissingPluginException`;debug 因为启动慢恰好不会触发。这里做有限重试。
Future<WindowController> _waitForController() async {
  Object? lastError;
  for (var i = 0; i < 100; i++) {
    try {
      return await WindowController.fromCurrentEngine();
    } catch (error) {
      lastError = error;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }
  throw StateError('panel window channel is unavailable: $lastError');
}

class PanelWindowApp extends StatelessWidget {
  final ValueNotifier<PanelState> state;
  final WindowController controller;
  final WindowController? mainController;

  const PanelWindowApp({
    super.key,
    required this.state,
    required this.controller,
    required this.mainController,
  });

  void _send(String method, [dynamic arguments]) {
    mainController?.invokeMethod(method, arguments).catchError((_) => null);
  }

  PanelActions _actions() {
    return PanelActions(
      onToggleStart: () => _send(PanelCommand.toggleStart),
      onModeChanged: (mode) => _send(PanelCommand.setMode, mode.index),
      onSystemProxyChanged: (value) =>
          _send(PanelCommand.setSystemProxy, value),
      onTunChanged: (value) => _send(PanelCommand.setTun, value),
      onOpenMain: (page) => _send(PanelCommand.openMain, page?.name),
      onHide: () {
        // 立即收起,同时让主引擎知道面板已关闭。
        controller.hide().catchError((_) => null);
        _send(PanelCommand.hide);
      },
      onExit: () => _send(PanelCommand.exit),
    );
  }

  ThemeData _theme(PanelState state, Brightness brightness) {
    final variant = DynamicSchemeVariant.values.firstWhere(
      (item) => item.name == state.schemeVariant,
      orElse: () => DynamicSchemeVariant.content,
    );
    final seed = state.primaryColor == null
        ? _defaultPrimaryColor
        : Color(state.primaryColor!);
    final scheme = quanXColorScheme(
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        dynamicSchemeVariant: variant,
      ),
      pureBlack: state.pureBlack,
    );
    return quanXThemeData(
      colorScheme: scheme,
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PanelState>(
      valueListenable: state,
      builder: (context, value, _) {
        final themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == value.themeMode,
          orElse: () => ThemeMode.system,
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.delegate.supportedLocales,
          locale: utils.getLocaleForString(value.locale),
          themeMode: themeMode,
          theme: _theme(value, Brightness.light),
          darkTheme: _theme(value, Brightness.dark),
          builder: (context, child) {
            final locale = Intl.canonicalizedLocale(
              Localizations.localeOf(context).toString(),
            );
            if (Intl.defaultLocale != locale) {
              Intl.defaultLocale = locale;
            }
            return child ?? const SizedBox.shrink();
          },
          home: Material(
            type: MaterialType.transparency,
            child: PanelBody(state: value, actions: _actions()),
          ),
        );
      },
    );
  }
}
