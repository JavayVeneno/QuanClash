import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// 节点测速的测量主机。Cloudflare 的公开测速端点按字节数返回/接收数据。
const speedTestHost = 'speed.cloudflare.com';

/// 单次测速的下载上限与时长上限。
const speedTestDownloadBytes = 20 * 1024 * 1024;
const speedTestDownloadDuration = Duration(seconds: 6);

/// 单次测速的上传上限与时长上限。
const speedTestUploadBytes = 2 * 1024 * 1024;
const speedTestUploadDuration = Duration(seconds: 6);

/// 测速连接停滞多久后按已收到的数据结算。
const _stallTimeout = Duration(seconds: 5);

enum SpeedTestPhase { idle, running, done, failed }

/// 自动测速的触发目标:当前分组 + 实际出口节点。
class SpeedTestTarget {
  const SpeedTestTarget({required this.groupName, required this.proxyName});

  final String groupName;
  final String proxyName;

  @override
  bool operator ==(Object other) =>
      other is SpeedTestTarget &&
      other.groupName == groupName &&
      other.proxyName == proxyName;

  @override
  int get hashCode => Object.hash(groupName, proxyName);
}

/// 一次测速的结果。所有速率单位都是 Mbps。
class SpeedTestResult {
  const SpeedTestResult({
    this.downloadMbps,
    this.uploadMbps,
    this.latencyMs,
    required this.sampledAt,
    this.groupName = '',
    this.proxyName = '',
  });

  final double? downloadMbps;
  final double? uploadMbps;
  final int? latencyMs;
  final DateTime sampledAt;
  final String groupName;
  final String proxyName;

  /// 至少测到一个有效数值,才算测速成功。
  bool get hasMeasurement =>
      downloadMbps != null || uploadMbps != null || latencyMs != null;
}

class SpeedTestState {
  const SpeedTestState({
    this.phase = SpeedTestPhase.idle,
    this.result,
    this.target,
  });

  final SpeedTestPhase phase;
  final SpeedTestResult? result;
  final SpeedTestTarget? target;

  SpeedTestState copyWith({
    SpeedTestPhase? phase,
    SpeedTestResult? result,
    SpeedTestTarget? target,
  }) {
    return SpeedTestState(
      phase: phase ?? this.phase,
      result: result ?? this.result,
      target: target ?? this.target,
    );
  }
}

/// 通过应用自身的代理链路(内核混合端口)测速,结果反映当前选中节点。
///
/// 未启动内核时 [QuanClashHttpOverrides] 会直连,调用方需要自行拦截。
/// [shouldAbort] 在每个阶段和下载分块之间检查,用于切换节点时放弃旧测试。
Future<SpeedTestResult> measureNodeSpeed({
  String groupName = '',
  String proxyName = '',
  bool Function()? shouldAbort,
}) async {
  bool aborted() => shouldAbort?.call() ?? false;
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..userAgent = 'QuanClash-SpeedTest';
  final sampledAt = DateTime.now().toUtc();
  try {
    final latency = await _measureLatency(client, aborted);
    if (aborted()) {
      return SpeedTestResult(sampledAt: sampledAt);
    }
    final download = await _measureDownload(client, aborted);
    if (aborted()) {
      return SpeedTestResult(sampledAt: sampledAt);
    }
    final upload = await _measureUpload(client, aborted);
    return SpeedTestResult(
      downloadMbps: download,
      uploadMbps: upload,
      latencyMs: latency,
      sampledAt: sampledAt,
      groupName: groupName,
      proxyName: proxyName,
    );
  } finally {
    client.close(force: true);
  }
}

/// 首字节时间(含代理建连),单位毫秒。
Future<int?> _measureLatency(HttpClient client, bool Function() aborted) async {
  try {
    final stopwatch = Stopwatch()..start();
    final request = await client.getUrl(
      Uri.https(speedTestHost, '/__down', {'bytes': '0'}),
    );
    final response = await request.close();
    final elapsed = stopwatch.elapsedMilliseconds;
    await response.drain<void>();
    if (aborted() || response.statusCode != HttpStatus.ok) {
      return null;
    }
    return elapsed;
  } catch (_) {
    return null;
  }
}

/// 从第一个数据块开始计时,避免把建连和首字节时间算进速率。
Future<double?> _measureDownload(
  HttpClient client,
  bool Function() aborted,
) async {
  final stopwatch = Stopwatch()..start();
  Duration? firstByteAt;
  var received = 0;
  try {
    final request = await client.getUrl(
      Uri.https(speedTestHost, '/__down', {'bytes': '$speedTestDownloadBytes'}),
    );
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    try {
      await for (final chunk in response.timeout(_stallTimeout)) {
        firstByteAt ??= stopwatch.elapsed;
        received += chunk.length;
        if (aborted() ||
            stopwatch.elapsed - firstByteAt >= speedTestDownloadDuration) {
          break;
        }
      }
    } on TimeoutException {
      // 连接停滞:按已经收到的数据结算。
    }
  } catch (_) {
    // 中途失败:按已经收到的数据结算。
  }
  if (received <= 0 || firstByteAt == null) {
    return null;
  }
  final seconds =
      (stopwatch.elapsed - firstByteAt).inMicroseconds /
      Duration.microsecondsPerSecond;
  if (seconds <= 0) {
    return null;
  }
  return received * 8 / seconds / 1000000;
}

/// 上传小样本并计时;超过时长上限视为失败,不上报不可信的数值。
Future<double?> _measureUpload(
  HttpClient client,
  bool Function() aborted,
) async {
  if (aborted()) {
    return null;
  }
  try {
    final stopwatch = Stopwatch()..start();
    final request = await client.postUrl(Uri.https(speedTestHost, '/__up'));
    request.headers.contentType = ContentType.binary;
    request.contentLength = speedTestUploadBytes;
    request.add(Uint8List(speedTestUploadBytes));
    final response = await request.close().timeout(speedTestUploadDuration);
    final seconds =
        stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    await response.drain<void>();
    if (aborted() ||
        response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices ||
        seconds <= 0) {
      return null;
    }
    return speedTestUploadBytes * 8 / seconds / 1000000;
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}
