// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../speed_test.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 节点测速状态。
///
/// 手动测速来自仪表盘卡片;打开「自动测速」后,[speedTestTriggerProvider]
/// 在内核就绪和切换节点时给出目标,由 [ApplicationState] 触发。

@ProviderFor(SpeedTest)
final speedTestProvider = SpeedTestProvider._();

/// 节点测速状态。
///
/// 手动测速来自仪表盘卡片;打开「自动测速」后,[speedTestTriggerProvider]
/// 在内核就绪和切换节点时给出目标,由 [ApplicationState] 触发。
final class SpeedTestProvider
    extends $NotifierProvider<SpeedTest, SpeedTestState> {
  /// 节点测速状态。
  ///
  /// 手动测速来自仪表盘卡片;打开「自动测速」后,[speedTestTriggerProvider]
  /// 在内核就绪和切换节点时给出目标,由 [ApplicationState] 触发。
  SpeedTestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speedTestProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speedTestHash();

  @$internal
  @override
  SpeedTest create() => SpeedTest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeedTestState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeedTestState>(value),
    );
  }
}

String _$speedTestHash() => r'b4f3a37ab00b09ae707979d2901cf94fba051a9c';

/// 节点测速状态。
///
/// 手动测速来自仪表盘卡片;打开「自动测速」后,[speedTestTriggerProvider]
/// 在内核就绪和切换节点时给出目标,由 [ApplicationState] 触发。

abstract class _$SpeedTest extends $Notifier<SpeedTestState> {
  SpeedTestState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SpeedTestState, SpeedTestState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpeedTestState, SpeedTestState>,
              SpeedTestState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 只有内核已连接时测速才会经过代理节点,否则量到的是直连速度。

@ProviderFor(speedTestAvailable)
final speedTestAvailableProvider = SpeedTestAvailableProvider._();

/// 只有内核已连接时测速才会经过代理节点,否则量到的是直连速度。

final class SpeedTestAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 只有内核已连接时测速才会经过代理节点,否则量到的是直连速度。
  SpeedTestAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speedTestAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speedTestAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return speedTestAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$speedTestAvailableHash() =>
    r'2909de6416414ebb88f0433e733815025e175074';

/// 自动测速的触发目标:内核就绪、开启自动测速、且当前出口是真实节点。

@ProviderFor(speedTestTrigger)
final speedTestTriggerProvider = SpeedTestTriggerProvider._();

/// 自动测速的触发目标:内核就绪、开启自动测速、且当前出口是真实节点。

final class SpeedTestTriggerProvider
    extends
        $FunctionalProvider<
          SpeedTestTarget?,
          SpeedTestTarget?,
          SpeedTestTarget?
        >
    with $Provider<SpeedTestTarget?> {
  /// 自动测速的触发目标:内核就绪、开启自动测速、且当前出口是真实节点。
  SpeedTestTriggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speedTestTriggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speedTestTriggerHash();

  @$internal
  @override
  $ProviderElement<SpeedTestTarget?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SpeedTestTarget? create(Ref ref) {
    return speedTestTrigger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeedTestTarget? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpeedTestTarget?>(value),
    );
  }
}

String _$speedTestTriggerHash() => r'7666ef1a360c45961b55ed3f480aeda453716fa1';
