import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/models/models.dart';
import 'package:quanclash/panel/panel_state.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:quanclash/state.dart';
import 'package:quanclash/views/panel/panel_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 主窗口内的托盘面板(非 Windows 平台的回退实现)。
///
/// Windows 上面板是独立窗口,由 [PanelWindowManager] 驱动;这里负责把
/// Riverpod 状态映射成 [PanelState],并复用同一份 [PanelBody]。
class PanelView extends ConsumerWidget {
  const PanelView({super.key});

  void _handleOpen(WidgetRef ref, [PageLabel? pageLabel]) {
    window?.showMain();
    if (pageLabel != null) {
      globalState.container
          .read(currentPageLabelProvider.notifier)
          .toPage(pageLabel);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStart = ref.watch(isStartProvider);
    final coreStatus = ref.watch(coreStatusProvider);
    final runTime = ref.watch(runTimeProvider);
    final traffics = ref.watch(trafficsProvider).list;
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final systemProxy = ref.watch(
      networkSettingProvider.select((state) => state.systemProxy),
    );
    final tunEnable = ref.watch(
      patchClashConfigProvider.select((state) => state.tun.enable),
    );
    final port = ref.watch(trayStateProvider.select((state) => state.port));
    final groups = ref.watch(groupsProvider);
    final selectedMap = ref.watch(selectedMapProvider);
    final group = computeCurrentGroup(
      groups,
      preferredName: ref.watch(
        currentProfileProvider.select((state) => state?.currentGroupName),
      ),
      selectedMap: selectedMap,
    );
    final proxyName = group == null
        ? null
        : computeRealSelectedProxyState(
            group.now ?? '',
            groups: groups,
            selectedMap: selectedMap,
          ).proxyName;
    final lastTraffic = traffics.isNotEmpty ? traffics.last : const Traffic();
    final delayMap = ref.watch(delayDataSourceProvider);
    final testUrl = group?.testUrl.takeFirstValid([
      ref.watch(appSettingProvider.select((state) => state.testUrl)),
    ]);
    final delay = proxyName == null || proxyName.isEmpty
        ? null
        : delayMap[testUrl]?[proxyName];
    final themeProps = ref.watch(themeSettingProvider);
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );

    final state = PanelState(
      isStart: isStart,
      coreStatus: coreStatus.name,
      runTime: runTime,
      mode: mode.index,
      port: port,
      up: lastTraffic.up,
      down: lastTraffic.down,
      groupName: group?.name,
      proxyName: proxyName,
      delay: delay,
      systemProxy: systemProxy,
      tun: tunEnable,
      locale: locale,
      themeMode: themeProps.themeMode.name,
      primaryColor: themeProps.primaryColor,
      schemeVariant: themeProps.schemeVariant.name,
      pureBlack: themeProps.pureBlack,
    );

    final actions = PanelActions(
      onToggleStart: () {
        debouncer.call(FunctionTag.updateStatus, () {
          globalState.container
              .read(setupActionProvider.notifier)
              .updateStatus(!isStart, isInit: !ref.read(initProvider));
        }, duration: commonDuration);
      },
      onModeChanged: (value) {
        ref.read(setupActionProvider.notifier).changeMode(value);
      },
      onSystemProxyChanged: (value) {
        ref
            .read(networkSettingProvider.notifier)
            .update((state) => state.copyWith(systemProxy: value));
      },
      onTunChanged: (value) {
        ref
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith.tun(enable: value));
      },
      onOpenMain: (pageLabel) => _handleOpen(ref, pageLabel),
      onHide: () => window?.hide(),
      onExit: () {
        globalState.container.read(systemActionProvider.notifier).handleExit();
      },
    );

    return PanelBody(state: state, actions: actions);
  }
}
