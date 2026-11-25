import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/common.dart' as common_models;
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/views/config/dns_diagnostic.dart';
import 'package:quanclash/views/connection/connections.dart';
import 'package:quanclash/views/connection/requests.dart';
import 'package:quanclash/views/logs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';
import '../utils.dart';
import 'sheet_primitives.dart';

/// Frosted monitoring & telemetry sheet opened from the Liquid Glass L-Dock's
/// `监控` slot.
class MobileV4MonitorSheet extends ConsumerWidget {
  const MobileV4MonitorSheet({super.key, required this.controller});

  final ScrollController controller;

  String _formatRunTime(int? ms) {
    if (ms == null || ms <= 0) {
      return '未运行';
    }
    final totalSeconds = ms ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = MobileV4Palette.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isStart = ref.watch(isStartProvider);
    final runTime = ref.watch(runTimeProvider);
    final totalTraffic = ref.watch(totalTrafficProvider);
    final liveTraffic = ref.watch(
      trafficsProvider.select(
        (state) => state.list.isEmpty
            ? const common_models.Traffic()
            : state.list.last,
      ),
    );
    final ipInfo = ref.watch(
      networkDetectionProvider.select((state) => state.ipInfo),
    );
    final requestsCount = ref.watch(
      requestsProvider.select((state) => state.length),
    );
    final logsCount = ref.watch(logsProvider.select((state) => state.length));
    final openLogs = ref.watch(
      appSettingProvider.select((state) => state.openLogs),
    );

    final totalDown = mobileV4FormatBytes(totalTraffic.down);
    final totalUp = mobileV4FormatBytes(totalTraffic.up);
    final speedDown = mobileV4FormatSpeed(isStart ? liveTraffic.down : 0);
    final speedUp = mobileV4FormatSpeed(isStart ? liveTraffic.up : 0);

    return ListView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(20, 2, 20, 46 + bottomInset),
      children: [
        MobileV4Card(
          topTint: p.heroTopTint,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isStart ? p.signal : p.faint,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isStart ? '运行中 · ${_formatRunTime(runTime)}' : 'VPN 未连接',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isStart ? p.text : p.muted,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Spacer(),
                      if (ipInfo != null)
                        Text(
                          '${ipInfo.countryCode} · ${ipInfo.ip}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: p.muted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TelemetryMetric(
                          palette: p,
                          label: '累计下载',
                          value: totalDown.$1,
                          unit: totalDown.$2,
                          sub: '↓ ${speedDown.$1} ${speedDown.$2}',
                        ),
                      ),
                      Container(width: 1, height: 42, color: p.lineSoft),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TelemetryMetric(
                          palette: p,
                          label: '累计上传',
                          value: totalUp.$1,
                          unit: totalUp.$2,
                          sub: '↑ ${speedUp.$1} ${speedUp.$2}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const MobileV4GroupLabel('实时监控与诊断'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.activity,
              title: '实时连接',
              sub: '查看活跃会话、规则命中与一键断流',
              onTap: () =>
                  pushMobileV4Subpage(context, const ConnectionsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.chartLine,
              title: '请求记录',
              sub: '$requestsCount 条记录',
              onTap: () => pushMobileV4Subpage(context, const RequestsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.scrollText,
              title: '运行日志',
              sub: '$logsCount 条日志',
              onTap: () => pushMobileV4Subpage(context, const LogsView()),
            ),
            MobileV4SettingsRow(
              icon: QuanXIcons.radar,
              title: 'DNS 诊断',
              sub: '检查解析器健康状态与防泄漏',
              onTap: () =>
                  pushMobileV4Subpage(context, const DnsDiagnosticPage()),
            ),
          ],
        ),
        const MobileV4GroupLabel('采集选项'),
        MobileV4Card(
          children: [
            MobileV4SettingsRow(
              icon: QuanXIcons.fileText,
              title: '日志记录',
              sub: openLogs ? '已开启核心日志采集' : '已暂停日志记录',
              trailing: MobileV4MiniSwitch(
                value: openLogs,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref
                      .read(appSettingProvider.notifier)
                      .update((state) => state.copyWith(openLogs: value));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TelemetryMetric extends StatelessWidget {
  const _TelemetryMetric({
    required this.palette,
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
  });

  final MobileV4Palette palette;
  final String label;
  final String value;
  final String unit;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: palette.micro),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                letterSpacing: -.6,
                color: palette.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(fontSize: 9.5, color: palette.muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9.5,
            color: palette.faint,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
