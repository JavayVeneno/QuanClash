import 'package:quanclash/common/common.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/speed_test.g.dart';

/// 节点测速状态。
///
/// 手动测速来自仪表盘卡片;打开「自动测速」后,[speedTestTriggerProvider]
/// 在内核就绪和切换节点时给出目标,由 [ApplicationState] 触发。
@Riverpod(keepAlive: true)
class SpeedTest extends _$SpeedTest {
  _SpeedTestRun? _run;

  @override
  SpeedTestState build() {
    ref.onDispose(() => _run?.aborted = true);
    return const SpeedTestState();
  }

  bool get isRunning => state.phase == SpeedTestPhase.running;

  Future<void> run({required SpeedTestTarget target}) async {
    // 切换节点时放弃上一次还在进行的测量,避免旧结果覆盖新节点。
    _run?.aborted = true;
    final run = _SpeedTestRun();
    _run = run;
    state = SpeedTestState(phase: SpeedTestPhase.running, target: target);
    SpeedTestResult result;
    try {
      result = await measureNodeSpeed(
        groupName: target.groupName,
        proxyName: target.proxyName,
        shouldAbort: () => run.aborted,
      );
    } catch (_) {
      result = SpeedTestResult(sampledAt: DateTime.now().toUtc());
    }
    if (run.aborted || !identical(_run, run)) {
      return;
    }
    _run = null;
    state = result.hasMeasurement
        ? SpeedTestState(
            phase: SpeedTestPhase.done,
            result: result,
            target: target,
          )
        : SpeedTestState(phase: SpeedTestPhase.failed, target: target);
  }

  void reset() {
    _run?.aborted = true;
    _run = null;
    state = const SpeedTestState();
  }
}

class _SpeedTestRun {
  bool aborted = false;
}

/// 只有内核已连接时测速才会经过代理节点,否则量到的是直连速度。
@riverpod
bool speedTestAvailable(Ref ref) {
  return ref.watch(isStartProvider) &&
      ref.watch(initProvider) &&
      ref.watch(coreStatusProvider) == CoreStatus.connected;
}

/// 自动测速的触发目标:内核就绪、开启自动测速、且当前出口是真实节点。
@riverpod
SpeedTestTarget? speedTestTrigger(Ref ref) {
  final auto = ref.watch(
    networkSettingProvider.select((state) => state.autoSpeedTest),
  );
  if (!auto || !ref.watch(speedTestAvailableProvider)) {
    return null;
  }
  final groups = ref.watch(groupsProvider);
  final selectedMap = ref.watch(selectedMapProvider);
  final preferredName = ref.watch(
    currentProfileProvider.select((state) => state?.currentGroupName),
  );
  final group = computeCurrentGroup(
    groups,
    preferredName: preferredName,
    selectedMap: selectedMap,
  );
  if (group == null) {
    return null;
  }
  final proxyName = computeRealSelectedProxyState(
    group.now ?? '',
    groups: groups,
    selectedMap: selectedMap,
  ).proxyName;
  if (proxyName.isEmpty || isReservedProxyName(proxyName)) {
    return null;
  }
  return SpeedTestTarget(groupName: group.name, proxyName: proxyName);
}
