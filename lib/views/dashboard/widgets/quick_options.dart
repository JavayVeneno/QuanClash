import 'package:quanclash/common/common.dart';
import 'package:quanclash/providers/config.dart';
import 'package:quanclash/views/config/network.dart';
import 'package:quanclash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_style.dart';

class TUNButton extends StatelessWidget {
  const TUNButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: getWidgetHeight(1) + 16.ap,
      child: DashboardCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return Builder(
                builder: (context) {
                  return AdaptiveSheetScaffold(
                    body: generateListView(
                      generateSection(
                        items: [
                          if (system.isDesktop) const TUNItem(),
                          if (system.isMacOS) const AutoSetSystemDnsItem(),
                          const TunStackItem(),
                        ],
                      ),
                    ),
                    title: appLocalizations.tun,
                  );
                },
              );
            },
          );
        },
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.chartLine,
              color: DashboardPalette.blue,
              title: appLocalizations.tun,
              trailing: Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    patchClashConfigProvider.select(
                      (state) => state.tun.enable,
                    ),
                  );
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: enable,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : null,
                    ),
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? DashboardPalette.green
                          : null,
                    ),
                    onChanged: (value) {
                      ref
                          .read(patchClashConfigProvider.notifier)
                          .update((state) => state.copyWith.tun(enable: value));
                    },
                  );
                },
              ),
            ),
            const Spacer(),
            Consumer(
              builder: (_, ref, _) {
                final stack = ref.watch(
                  patchClashConfigProvider.select(
                    (state) => state.tun.stack,
                  ),
                );
                return Text(
                  stack.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.quanX.textSecondary,
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

class SystemProxyButton extends StatelessWidget {
  const SystemProxyButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: getWidgetHeight(1) + 16.ap,
      child: DashboardCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return AdaptiveSheetScaffold(
                body: generateListView(
                  generateSection(
                    items: [const SystemProxyItem(), const BypassDomainItem()],
                  ),
                ),
                title: appLocalizations.systemProxy,
              );
            },
          );
        },
        padding: EdgeInsets.all(12.ap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCardTitle(
              icon: QuanXIcons.shuffle,
              color: DashboardPalette.primary,
              title: appLocalizations.systemProxy,
              trailing: Consumer(
                builder: (_, ref, _) {
                  final systemProxy = ref.watch(
                    networkSettingProvider.select((state) => state.systemProxy),
                  );
                  return Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: systemProxy,
                    thumbColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : null,
                    ),
                    trackColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? DashboardPalette.green
                          : null,
                    ),
                    onChanged: (value) {
                      ref
                          .read(networkSettingProvider.notifier)
                          .update(
                            (state) => state.copyWith(systemProxy: value),
                          );
                    },
                  );
                },
              ),
            ),
            const Spacer(),
            Consumer(
              builder: (_, ref, _) {
                final port = ref.watch(
                  patchClashConfigProvider.select(
                    (state) => state.mixedPort,
                  ),
                );
                return Text(
                  '${appLocalizations.port} $port',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.quanX.textSecondary,
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

class VpnButton extends StatelessWidget {
  const VpnButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return AdaptiveSheetScaffold(
                body: generateListView(
                  generateSection(
                    items: [
                      const VPNItem(),
                      const VpnSystemProxyItem(),
                      const TunStackItem(),
                    ],
                  ),
                ),
                title: 'VPN',
              );
            },
          );
        },
        info: const Info(label: 'VPN', iconData: QuanXIcons.chartLine),
        child: Container(
          padding: baseInfoEdgeInsets.copyWith(top: 4, bottom: 8, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 1,
                child: TooltipText(
                  text: Text(
                    appLocalizations.options,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.adjustSize(-2).toLight,
                  ),
                ),
              ),
              Consumer(
                builder: (_, ref, _) {
                  final enable = ref.watch(
                    vpnSettingProvider.select((state) => state.enable),
                  );
                  return Switch(
                    value: enable,
                    onChanged: (value) {
                      ref
                          .read(vpnSettingProvider.notifier)
                          .update((state) => state.copyWith(enable: value));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
