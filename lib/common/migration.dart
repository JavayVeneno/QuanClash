import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';

class Migration {
  static Migration? _instance;
  late int _oldVersion;

  Migration._internal();

  final currentVersion = 2;

  factory Migration() {
    _instance ??= Migration._internal();
    return _instance!;
  }

  Future<Config> migrationIfNeeded(
    Map<String, Object?>? configMap, {
    required Future<Config> Function(MigrationData data) sync,
  }) async {
    _oldVersion = await preferences.getVersion();
    if (_oldVersion == currentVersion) {
      try {
        return Config.realFromJson(configMap);
      } catch (_) {
        final isV0 = configMap?['proxiesStyle'] != null;
        if (isV0) {
          _oldVersion = 0;
        } else {
          throw 'Local data is damaged. A reset is required to fix this issue.';
        }
      }
    }
    MigrationData data = MigrationData(configMap: configMap);
    if (_oldVersion == 0 && configMap != null) {
      final clashConfigMap = await preferences.getClashConfigMap();
      if (clashConfigMap != null) {
        configMap['patchClashConfig'] = clashConfigMap;
        await preferences.clearClashConfig();
      }
      data = await _oldToNow(configMap);
    }
    if (_oldVersion <= 1 && configMap != null) {
      data = _v1ToV2(data);
    }
    final res = await sync(data);
    await preferences.setVersion(currentVersion);
    return res;
  }

  /// v2：旧版本默认主色（玫瑰粉）统一到设计稿靛蓝。
  ///
  /// 只迁移「仍是旧默认值」的配置；用户主动选过的其他颜色保持不变。
  MigrationData _v1ToV2(MigrationData data) {
    final themeProps = data.configMap?['themeProps'];
    if (themeProps is Map &&
        themeProps['primaryColor'] == legacyDefaultPrimaryColor) {
      themeProps['primaryColor'] = defaultPrimaryColor;
    }
    return data;
  }

  Future<MigrationData> _oldToNow(Map<String, Object?> configMap) async {
    return oldToNowTask(configMap);
  }
}

final migration = Migration();
