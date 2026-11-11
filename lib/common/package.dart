import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import 'common.dart';

extension PackageInfoExtension on PackageInfo {
  /// Default User-Agent used for subscription downloads.
  ///
  /// It must start with `mihomo/`: providers match the prefix and hand out a
  /// single placeholder node to clients they do not recognise as mihomo.
  String get ua => [
    'mihomo/$coreVersion',
    '$appName/v$version',
    'clash-verge',
    'Platform/${Platform.operatingSystem}',
  ].join(' ');
}
