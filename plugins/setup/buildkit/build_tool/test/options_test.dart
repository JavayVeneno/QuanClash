import 'dart:io';

import 'package:build_tool/src/options.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('quanclash-build-options-');
  });
  tearDown(() {
    if (!p.isWithin(
      p.normalize(p.absolute(Directory.systemTemp.path)),
      p.normalize(p.absolute(root.path)),
    )) {
      throw StateError('Build options fixture cleanup escaped temp');
    }
    root.deleteSync(recursive: true);
  });

  test('defaults remain compatible without an output override', () {
    final config = BuildConfig.load(rootDir: root.path, environment: const {});
    expect(config.outputDir, 'libclash');
    expect(config.tags, 'with_gvisor');
    expect(config.coreName, 'QuanClashCore');
  });

  test('explicit staging overrides YAML without changing other fields', () {
    File(p.join(root.path, 'build_config.yaml')).writeAsStringSync(
      'output_dir: original\ntags: custom\ncore_name: custom-core\n',
    );
    final config = BuildConfig.load(
      rootDir: root.path,
      environment: const {'BUILDKIT_OUTPUT_DIR': 'build/staged artifacts'},
    );
    expect(config.outputDir, p.join(root.path, 'build', 'staged artifacts'));
    expect(config.tags, 'custom');
    expect(config.coreName, 'custom-core');
    expect(File(p.join(root.path, 'build_config.yaml')).readAsStringSync(),
        contains('output_dir: original'));
  });

  test('absolute override stays absolute and empty override preserves YAML',
      () {
    File(p.join(root.path, 'build_config.yaml'))
        .writeAsStringSync('output_dir: custom\n');
    final absolute = p.join(root.path, 'isolated');
    expect(
        BuildConfig.load(
            rootDir: root.path,
            environment: {'BUILDKIT_OUTPUT_DIR': absolute}).outputDir,
        absolute);
    expect(
        BuildConfig.load(
            rootDir: root.path,
            environment: const {'BUILDKIT_OUTPUT_DIR': ''}).outputDir,
        'custom');
  });

  test('an empty YAML file still supports staging', () {
    File(p.join(root.path, 'build_config.yaml')).writeAsStringSync('');
    expect(
        BuildConfig.load(
                rootDir: root.path,
                environment: const {'BUILDKIT_OUTPUT_DIR': 'build/staged'})
            .outputDir,
        p.join(root.path, 'build', 'staged'));
  });
}
