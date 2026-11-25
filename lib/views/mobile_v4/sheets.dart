import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'sheets/config_sheet.dart';
import 'sheets/monitor_sheet.dart';
import 'sheets/proxy_sheet.dart';
import 'sheets/settings_sheet.dart';
import 'sheets/sheet_primitives.dart';
import 'theme.dart';

export 'sheets/sheet_primitives.dart' show MobileV4SubpageScope;

/// Opens one of the v4 80% frosted modal bottom sheets:
/// `'proxy'`, `'config'`, `'monitor'`, or `'settings'`.
Future<void> showMobileV4Sheet(BuildContext context, String type) {
  final barrier = MobileV4Palette.of(context).sheetBarrier;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: barrier,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: .8,
        minChildSize: .5,
        maxChildSize: .94,
        expand: false,
        builder: (ctx, controller) {
          final p = MobileV4Palette.of(ctx);
          return Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MobileV4Theme.radiusSheet),
              ),
              boxShadow: [
                BoxShadow(
                  color: p.sheetShadow,
                  blurRadius: 60,
                  offset: const Offset(0, -18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(MobileV4Theme.radiusSheet),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.sheet,
                    border: Border(
                      top: BorderSide(color: p.sheetTopBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      MobileV4SheetHead(type: type),
                      Expanded(child: _SheetBody(type, controller)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody(this.type, this.controller);

  final String type;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      'proxy' => MobileV4ProxySheet(controller: controller),
      'config' => MobileV4ConfigSheet(controller: controller),
      'monitor' => MobileV4MonitorSheet(controller: controller),
      _ => MobileV4SettingsSheet(controller: controller),
    };
  }
}
