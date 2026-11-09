import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/app.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class NetworkDetection extends ConsumerStatefulWidget {
  const NetworkDetection({super.key});

  @override
  ConsumerState<NetworkDetection> createState() => _NetworkDetectionState();
}

class _NetworkDetectionState extends ConsumerState<NetworkDetection> {
  String _countryCodeToEmoji(String countryCode) {
    final String code = countryCode.toUpperCase();
    if (code.length != 2) {
      return countryCode;
    }
    final int firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final quanX = context.quanX;
    final colorScheme = context.colorScheme;
    final networkDetection = ref.watch(networkDetectionProvider);
    final ipInfo = networkDetection.ipInfo;
    final isLoading = networkDetection.isLoading;
    final delay = networkDetection.delay;
    final emojiTextStyle = context.textTheme.bodySmall?.copyWith(
      fontFamily: FontFamily.twEmoji.value,
    );
    return SizedBox(
      height: 96.ap,
      child: DashboardCard(
        onPressed: () {},
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.gauge,
              color: DashboardPalette.blue,
              title: appLocalizations.networkDetection,
              trailing: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  globalState.showMessage(
                    title: appLocalizations.tip,
                    message: TextSpan(text: appLocalizations.detectionTip),
                    cancelable: false,
                  );
                },
                icon: Icon(
                  QuanXIcons.info,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: globalState.measure.titleSmallHeight + 2,
              child: FadeThroughBox(
                child: delay != null
                    ? TooltipText(
                        text: Text(
                          '$delay ms',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : isLoading
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        child: const AspectRatio(
                          aspectRatio: 1,
                          child: CommonCircleLoading(),
                        ),
                      )
                    : Text(
                        'Timeout',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
              ),
            ),
            if (ipInfo != null) ...[
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_countryCodeToEmoji(ipInfo.countryCode)} ',
                      style: emojiTextStyle,
                    ),
                    TextSpan(text: ipInfo.ip),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: quanX.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
