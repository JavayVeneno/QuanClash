import 'package:quanclash/enum/enum.dart';

String mobileV4ModeLabel(Mode mode) {
  return switch (mode) {
    Mode.rule => '规则模式',
    Mode.global => '全局模式',
    Mode.direct => '直连模式',
  };
}

String mobileV4ModeShortLabel(Mode mode) {
  return switch (mode) {
    Mode.rule => '规则',
    Mode.global => '全局',
    Mode.direct => '直连',
  };
}

Mode? mobileV4ModeFromLabel(String label) {
  return switch (label) {
    '规则模式' => Mode.rule,
    '全局模式' => Mode.global,
    '直连模式' => Mode.direct,
    _ => null,
  };
}

List<Mode> get mobileV4Modes => const [Mode.rule, Mode.global, Mode.direct];

/// Formats bytes-per-second into a tabular numeric value and unit string.
///
/// Displays `0.0 KB/s` when idle so the readout matches the v4 design spec.
(String value, String unit) mobileV4FormatSpeed(num bytesPerSecond) {
  final raw = bytesPerSecond.toDouble();
  if (raw <= 0) {
    return ('0.0', 'KB/s');
  }
  const kb = 1024.0;
  const mb = kb * 1024.0;
  const gb = mb * 1024.0;
  if (raw < mb) {
    return ((raw / kb).toStringAsFixed(1), 'KB/s');
  }
  if (raw < gb) {
    return ((raw / mb).toStringAsFixed(1), 'MB/s');
  }
  return ((raw / gb).toStringAsFixed(2), 'GB/s');
}

/// Formats byte counts into compact human-readable value and unit strings.
(String value, String unit) mobileV4FormatBytes(num bytes) {
  final raw = bytes.toDouble();
  if (raw <= 0) {
    return ('0', 'GB');
  }
  const kb = 1024.0;
  const mb = kb * 1024.0;
  const gb = mb * 1024.0;
  const tb = gb * 1024.0;
  if (raw >= tb) {
    final v = raw / tb;
    return (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1), 'TB');
  }
  if (raw >= gb) {
    return ((raw / gb).toStringAsFixed(1), 'GB');
  }
  if (raw >= mb) {
    return ((raw / mb).toStringAsFixed(1), 'MB');
  }
  return ((raw / kb).toStringAsFixed(0), 'KB');
}
