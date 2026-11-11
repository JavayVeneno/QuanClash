import 'dart:async';
import 'dart:io';

import 'package:quanclash/pages/error.dart';
import 'package:quanclash/panel/panel_window_app.dart';
import 'package:quanclash/panel/panel_window_manager.dart';
import 'package:quanclash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart';

import 'application.dart';
import 'common/common.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // 第二个 Flutter 引擎(托盘面板窗口):只渲染面板,不初始化主应用。
  if (args.length > 2 &&
      args[0] == 'multi_window' &&
      args[2] == PanelWindowManager.windowArgument) {
    await runPanelWindow();
    return;
  }
  try {
    if (system.isDesktop) {
      await RustLib.init();
    }
    final version = await system.version;
    final container = await globalState.init(version);
    HttpOverrides.global = QuanClashHttpOverrides();
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const Application(),
      ),
    );
  } catch (e, s) {
    runApp(
      MaterialApp(
        home: InitErrorScreen(error: e, stack: s),
      ),
    );
  }
}
