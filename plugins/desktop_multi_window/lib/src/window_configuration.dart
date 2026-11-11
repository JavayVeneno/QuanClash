import 'dart:ui' show Rect;

class WindowConfiguration {
  const WindowConfiguration({
    required this.arguments,
    this.hiddenAtLaunch = true,
    this.frame,
    this.alwaysOnTop = false,
    this.skipTaskbar = false,
    this.frameless = false,
  });

  /// The arguments passed to the new window.
  final String arguments;

  final bool hiddenAtLaunch;

  /// 窗口位置与大小(逻辑像素)。为空时使用插件默认的 800x600。
  final Rect? frame;

  /// 置顶显示。
  final bool alwaysOnTop;

  /// 不在任务栏显示。
  final bool skipTaskbar;

  /// 无标题栏、无边框。
  final bool frameless;

  factory WindowConfiguration.fromJson(Map<String, dynamic> json) {
    final frame = json['frame'];
    return WindowConfiguration(
      arguments: json['arguments'] as String? ?? '',
      hiddenAtLaunch: json['hiddenAtLaunch'] as bool? ?? false,
      frame: frame is List && frame.length == 4
          ? Rect.fromLTWH(
              (frame[0] as num).toDouble(),
              (frame[1] as num).toDouble(),
              (frame[2] as num).toDouble(),
              (frame[3] as num).toDouble(),
            )
          : null,
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? false,
      skipTaskbar: json['skipTaskbar'] as bool? ?? false,
      frameless: json['frameless'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arguments': arguments,
      'hiddenAtLaunch': hiddenAtLaunch,
      'frame': frame == null
          ? null
          : [frame!.left, frame!.top, frame!.width, frame!.height],
      'alwaysOnTop': alwaysOnTop,
      'skipTaskbar': skipTaskbar,
      'frameless': frameless,
    };
  }

  @override
  String toString() {
    return 'WindowConfiguration(arguments: $arguments, '
        'hiddenAtLaunch: $hiddenAtLaunch, frame: $frame, '
        'alwaysOnTop: $alwaysOnTop, skipTaskbar: $skipTaskbar, '
        'frameless: $frameless)';
  }

  @override
  bool operator ==(Object other) {
    return other is WindowConfiguration &&
        other.arguments == arguments &&
        other.hiddenAtLaunch == hiddenAtLaunch &&
        other.frame == frame &&
        other.alwaysOnTop == alwaysOnTop &&
        other.skipTaskbar == skipTaskbar &&
        other.frameless == frameless;
  }

  @override
  int get hashCode => Object.hash(
    arguments,
    hiddenAtLaunch,
    frame,
    alwaysOnTop,
    skipTaskbar,
    frameless,
  );
}
