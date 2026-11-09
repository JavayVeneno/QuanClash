import 'package:quanclash/common/common.dart';
import 'package:quanclash/providers/app.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class IntranetIP extends StatelessWidget {
  const IntranetIP({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: 96.ap,
      child: DashboardCard(
        onPressed: () {},
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.monitorSmartphone,
              color: DashboardPalette.primary,
              title: appLocalizations.intranetIP,
            ),
            const Spacer(),
            Consumer(
              builder: (_, ref, _) {
                final localIp = ref.watch(localIpProvider);
                return FadeThroughBox(
                  child: localIp != null
                      ? TooltipText(
                          text: Text(
                            localIp.isNotEmpty
                                ? localIp
                                : appLocalizations.noNetwork,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontFamily: 'JetBrainsMono',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(2),
                          child: const AspectRatio(
                            aspectRatio: 1,
                            child: CommonCircleLoading(),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
