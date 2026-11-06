import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

final _log = Logger('options');

class BuildConfig {
  final String tags;
  final String goLdflags;
  final String coreDir;
  final String coreName;
  final String libName;
  final String outputDir;
  final String helperDir;
  final String helperName;
  final String distDir;

  const BuildConfig({
    required this.tags,
    required this.goLdflags,
    required this.coreDir,
    required this.coreName,
    required this.libName,
    required this.outputDir,
    required this.helperDir,
    required this.helperName,
    required this.distDir,
  });

  static const _defaults = BuildConfig(
    tags: 'with_gvisor',
    goLdflags: '-w -s',
    coreDir: 'core',
    coreName: 'QuanClashCore',
    libName: 'libclash',
    outputDir: 'libclash',
    helperDir: 'services/helper',
    helperName: 'QuanClashHelperService',
    distDir: 'dist',
  );

  static BuildConfig load({
    required String rootDir,
    Map<String, String>? environment,
  }) {
    final env = environment ?? Platform.environment;
    final outputOverride = env['BUILDKIT_OUTPUT_DIR'];
    final configPath = p.join(rootDir, 'build_config.yaml');
    final file = File(configPath);
    YamlMap? yaml;
    if (!file.existsSync()) {
      _log.fine('No build_config.yaml found, using defaults');
    } else {
      yaml = loadYaml(file.readAsStringSync()) as YamlMap?;
    }
    return BuildConfig(
      tags: yaml?['tags'] as String? ?? _defaults.tags,
      goLdflags: yaml?['go_ldflags'] as String? ?? _defaults.goLdflags,
      coreDir: yaml?['core_dir'] as String? ?? _defaults.coreDir,
      coreName: yaml?['core_name'] as String? ?? _defaults.coreName,
      libName: yaml?['lib_name'] as String? ?? _defaults.libName,
      outputDir: outputOverride?.isNotEmpty == true
          ? p.normalize(p.absolute(p.join(rootDir, outputOverride!)))
          : yaml?['output_dir'] as String? ?? _defaults.outputDir,
      helperDir: yaml?['helper_dir'] as String? ?? _defaults.helperDir,
      helperName: yaml?['helper_name'] as String? ?? _defaults.helperName,
      distDir: yaml?['dist_dir'] as String? ?? _defaults.distDir,
    );
  }
}
