import 'package:quanclash/common/common.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/providers/app.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class NetworkSpeed extends StatefulWidget {
  const NetworkSpeed({super.key});

  @override
  State<NetworkSpeed> createState() => _NetworkSpeedState();
}

class _NetworkSpeedState extends State<NetworkSpeed> {
  List<Point> initPoints = const [Point(0, 0), Point(1, 0)];

  List<Point> _getPoints(List<Traffic> traffics) {
    final List<Point> trafficPoints = traffics
        .toList()
        .asMap()
        .map(
          (index, e) => MapEntry(
            index,
            Point((index + initPoints.length).toDouble(), e.speed.toDouble()),
          ),
        )
        .values
        .toList();

    return [...initPoints, ...trafficPoints];
  }

  Traffic _getLastTraffic(List<Traffic> traffics) {
    if (traffics.isEmpty) return const Traffic();
    return traffics.last;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    return SizedBox(
      height: getWidgetHeight(2),
      child: RepaintBoundary(
        child: DashboardCard(
          onPressed: () {},
          padding: EdgeInsets.all(14.ap),
          child: Consumer(
            builder: (_, ref, _) {
              final traffics = ref.watch(trafficsProvider).list;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DashboardCardTitle(
                          icon: QuanXIcons.gauge,
                          color: DashboardPalette.primary,
                          title: appLocalizations.networkSpeed,
                        ),
                      ),
                      Text(
                        _getLastTraffic(traffics).speedText,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: quanX.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LineChart(
                      gradient: true,
                      color: DashboardPalette.primary,
                      points: _getPoints(traffics),
                    ),
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
