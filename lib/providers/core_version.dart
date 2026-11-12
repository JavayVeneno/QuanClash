import 'package:quanclash/common/common.dart';
import 'package:quanclash/core/core.dart';
import 'package:quanclash/enum/enum.dart';
import 'package:quanclash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/core_version.g.dart';

/// 当前运行中的内核版本。
///
/// 版本号由内核进程通过 IPC 返回，因此只有内核连接成功后才能查询；
/// 未连接或旧内核不支持该动作时返回空串，界面显示占位符。
@riverpod
Future<String> coreRuntimeVersion(Ref ref) async {
  if (ref.watch(coreStatusProvider) != CoreStatus.connected) {
    return '';
  }
  try {
    return await coreController.getVersion();
  } catch (e) {
    commonPrint.log('Failed to get core version: $e');
    return '';
  }
}
