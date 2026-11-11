import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quanclash/common/common.dart';

void main() {
  group('default User-Agent', () {
    final info = PackageInfo(
      appName: appName,
      packageName: packageName,
      version: '0.0.1',
      buildNumber: '1',
    );

    test('starts with the mihomo client prefix', () {
      expect(info.ua.startsWith('mihomo/$coreVersion '), isTrue);
    });

    test('keeps the clash-verge and platform markers', () {
      expect(info.ua, contains('clash-verge'));
      expect(info.ua, contains('Platform/${Platform.operatingSystem}'));
      expect(info.ua, contains('$appName/v0.0.1'));
    });
  });
}
