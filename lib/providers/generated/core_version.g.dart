// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../core_version.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 当前运行中的内核版本。
///
/// 版本号由内核进程通过 IPC 返回，因此只有内核连接成功后才能查询；
/// 未连接或旧内核不支持该动作时返回空串，界面显示占位符。

@ProviderFor(coreRuntimeVersion)
final coreRuntimeVersionProvider = CoreRuntimeVersionProvider._();

/// 当前运行中的内核版本。
///
/// 版本号由内核进程通过 IPC 返回，因此只有内核连接成功后才能查询；
/// 未连接或旧内核不支持该动作时返回空串，界面显示占位符。

final class CoreRuntimeVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// 当前运行中的内核版本。
  ///
  /// 版本号由内核进程通过 IPC 返回，因此只有内核连接成功后才能查询；
  /// 未连接或旧内核不支持该动作时返回空串，界面显示占位符。
  CoreRuntimeVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coreRuntimeVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coreRuntimeVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return coreRuntimeVersion(ref);
  }
}

String _$coreRuntimeVersionHash() =>
    r'3f3f7584044124f5140528136e46e0ce522130e3';
