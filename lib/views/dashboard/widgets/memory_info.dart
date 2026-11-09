import 'dart:async';
import 'dart:io';

import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/controller.dart';
import 'package:flutter/material.dart';

import 'dashboard_style.dart';

final _memoryStateNotifier = ValueNotifier<num>(0);

class MemoryInfo extends StatefulWidget {
  const MemoryInfo({super.key});

  @override
  State<MemoryInfo> createState() => _MemoryInfoState();
}

class _MemoryInfoState extends State<MemoryInfo> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _updateMemory();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _updateMemory() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final rss = ProcessInfo.currentRss;
      if (coreController.isCompleted) {
        _memoryStateNotifier.value = await coreController.getMemory() + rss;
      } else {
        _memoryStateNotifier.value = rss;
      }
      timer = Timer(const Duration(seconds: 2), () async {
        _updateMemory();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    return SizedBox(
      height: 96.ap,
      child: DashboardCard(
        onPressed: () {
          coreController.requestGc();
        },
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.memoryStick,
              color: DashboardPalette.orange,
              title: appLocalizations.memoryInfo,
            ),
            const Spacer(),
            ValueListenableBuilder(
              valueListenable: _memoryStateNotifier,
              builder: (_, memory, _) {
                final traffic = memory.traffic;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      traffic.value,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontFamily: 'JetBrainsMono',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      traffic.unit,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: quanX.textSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
