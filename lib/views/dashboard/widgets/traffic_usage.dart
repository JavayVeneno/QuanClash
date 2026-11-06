import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class TrafficUsage extends StatelessWidget {
  const TrafficUsage({super.key});

  Widget _buildTrafficDataItem(
    BuildContext context,
    Icon icon,
    num trafficValue,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              trafficValue.traffic.value,
              style: context.textTheme.bodySmall,
            ),
          ],
        ),
        Text(
          trafficValue.traffic.unit,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.quanX.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    const primaryColor = DashboardPalette.primary;
    const secondaryColor = DashboardPalette.blue;
    return SizedBox(
      height: getWidgetHeight(2),
      child: RepaintBoundary(
        child: DashboardCard(
          onPressed: () {},
          padding: EdgeInsets.all(14.ap),
          child: Consumer(
            builder: (_, ref, _) {
              final totalTraffic = ref.watch(totalTrafficProvider);
              final upTotalTrafficValue = totalTraffic.up;
              final downTotalTrafficValue = totalTraffic.down;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardCardTitle(
                    icon: QuanXIcons.chartPie,
                    color: DashboardPalette.blue,
                    title: appLocalizations.trafficUsage,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: DonutChart(
                            data: [
                              DonutChartData(
                                value: upTotalTrafficValue.toDouble(),
                                color: primaryColor,
                              ),
                              DonutChartData(
                                value: downTotalTrafficValue.toDouble(),
                                color: secondaryColor,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _legend(
                                context,
                                primaryColor,
                                appLocalizations.upload,
                              ),
                              const SizedBox(height: 6),
                              _legend(
                                context,
                                secondaryColor,
                                appLocalizations.download,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTrafficDataItem(
                    context,
                    const Icon(
                      QuanXIcons.arrowUp,
                      color: primaryColor,
                      size: 14,
                    ),
                    upTotalTrafficValue,
                  ),
                  const SizedBox(height: 6),
                  _buildTrafficDataItem(
                    context,
                    const Icon(
                      QuanXIcons.arrowDown,
                      color: secondaryColor,
                      size: 14,
                    ),
                    downTotalTrafficValue,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
