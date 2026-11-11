import 'package:quanclash/enum/enum.dart';

/// 托盘面板窗口与主引擎之间同步的一份只读状态快照。
///
/// 面板运行在独立的 Flutter 引擎里,拿不到主引擎的 Riverpod 容器,因此由主
/// 引擎把渲染需要的字段序列化后推过来。
class PanelState {
  const PanelState({
    this.isStart = false,
    this.coreStatus = 'disconnected',
    this.runTime,
    this.mode = 0,
    this.port = 0,
    this.up = 0,
    this.down = 0,
    this.groupName,
    this.proxyName,
    this.delay,
    this.systemProxy = false,
    this.tun = false,
    this.locale,
    this.themeMode = 'system',
    this.primaryColor,
    this.schemeVariant = 'content',
    this.pureBlack = false,
  });

  final bool isStart;
  final String coreStatus;
  final int? runTime;
  final int mode;
  final int port;
  final num up;
  final num down;
  final String? groupName;
  final String? proxyName;
  final int? delay;
  final bool systemProxy;
  final bool tun;

  // 外观:面板引擎需要自己搭一套和主窗口一致的 MaterialApp。
  final String? locale;
  final String themeMode;
  final int? primaryColor;
  final String schemeVariant;
  final bool pureBlack;

  Mode get outboundMode =>
      mode >= 0 && mode < Mode.values.length ? Mode.values[mode] : Mode.rule;

  PanelState copyWith({
    bool? isStart,
    String? coreStatus,
    int? runTime,
    int? mode,
    int? port,
    num? up,
    num? down,
    String? groupName,
    String? proxyName,
    int? delay,
    bool? systemProxy,
    bool? tun,
    String? locale,
    String? themeMode,
    int? primaryColor,
    String? schemeVariant,
    bool? pureBlack,
  }) {
    return PanelState(
      isStart: isStart ?? this.isStart,
      coreStatus: coreStatus ?? this.coreStatus,
      runTime: runTime ?? this.runTime,
      mode: mode ?? this.mode,
      port: port ?? this.port,
      up: up ?? this.up,
      down: down ?? this.down,
      groupName: groupName ?? this.groupName,
      proxyName: proxyName ?? this.proxyName,
      delay: delay ?? this.delay,
      systemProxy: systemProxy ?? this.systemProxy,
      tun: tun ?? this.tun,
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      schemeVariant: schemeVariant ?? this.schemeVariant,
      pureBlack: pureBlack ?? this.pureBlack,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isStart': isStart,
      'coreStatus': coreStatus,
      'runTime': runTime,
      'mode': mode,
      'port': port,
      'up': up,
      'down': down,
      'groupName': groupName,
      'proxyName': proxyName,
      'delay': delay,
      'systemProxy': systemProxy,
      'tun': tun,
      'locale': locale,
      'themeMode': themeMode,
      'primaryColor': primaryColor,
      'schemeVariant': schemeVariant,
      'pureBlack': pureBlack,
    };
  }

  factory PanelState.fromJson(Map<String, dynamic> json) {
    return PanelState(
      isStart: json['isStart'] as bool? ?? false,
      coreStatus: json['coreStatus'] as String? ?? 'disconnected',
      runTime: (json['runTime'] as num?)?.toInt(),
      mode: (json['mode'] as num?)?.toInt() ?? 0,
      port: (json['port'] as num?)?.toInt() ?? 0,
      up: json['up'] as num? ?? 0,
      down: json['down'] as num? ?? 0,
      groupName: json['groupName'] as String?,
      proxyName: json['proxyName'] as String?,
      delay: (json['delay'] as num?)?.toInt(),
      systemProxy: json['systemProxy'] as bool? ?? false,
      tun: json['tun'] as bool? ?? false,
      locale: json['locale'] as String?,
      themeMode: json['themeMode'] as String? ?? 'system',
      primaryColor: (json['primaryColor'] as num?)?.toInt(),
      schemeVariant: json['schemeVariant'] as String? ?? 'content',
      pureBlack: json['pureBlack'] as bool? ?? false,
    );
  }
}

/// 面板窗口向主引擎发送的命令名。
abstract class PanelCommand {
  static const toggleStart = 'toggleStart';
  static const setMode = 'setMode';
  static const setSystemProxy = 'setSystemProxy';
  static const setTun = 'setTun';
  static const openMain = 'openMain';
  static const hide = 'hide';
  static const exit = 'exit';
}

/// 主引擎推送给面板窗口的方法名。
abstract class PanelEvent {
  static const state = 'state';
  static const blur = 'panel_blur';
}
