import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final cmake = Platform.environment['QUANCLASH_BUILDKIT_TEST_CMAKE'];
  final ninja = Platform.environment['QUANCLASH_BUILDKIT_TEST_NINJA'];
  test(
    'CMake rebuilds existing artifacts in the selected config and staging path',
    () async {
      final root = await Directory.systemTemp.createTemp('quanclash-buildkit-');
      addTearDown(() async {
        if (!p.isWithin(
          p.absolute(Directory.systemTemp.path),
          p.absolute(root.path),
        )) {
          throw StateError('Buildkit fixture cleanup escaped temp');
        }
        await root.delete(recursive: true);
      });
      final project = await Directory(
        p.join(root.path, 'project with spaces'),
      ).create();
      final source = await Directory(p.join(project.path, 'windows')).create();
      final mock = await Directory(p.join(root.path, 'mock')).create();
      final output = p.join(project.path, 'build', 'staged artifacts');
      final core = File(p.join(output, 'windows', 'QuanClashCore.exe'));
      final helper = File(
        p.join(output, 'windows', 'QuanClashHelperService.exe'),
      );
      await core.parent.create(recursive: true);
      await core.writeAsString('old core');
      await helper.writeAsString('old helper');
      final cmakeFile = p
          .join(
            Directory.current.path,
            'plugins',
            'setup',
            'buildkit',
            'cmake',
            'buildkit.cmake',
          )
          .replaceAll(r'\', '/');
      await File(p.join(source.path, 'CMakeLists.txt')).writeAsString('''
cmake_minimum_required(VERSION 3.20)
project(buildkit_fixture NONE)
include("$cmakeFile")
set(BUILDKIT_DIR "${mock.path.replaceAll(r'\', '/')}")
apply_buildkit()
''');
      // This fixture only writes markers. It cannot invoke Go/Rust or services.
      await File(p.join(mock.path, 'run_build_tool.cmd')).writeAsString(r'''
@echo off
echo %BUILDKIT_CONFIGURATION%>> "%PROJECT_DIR%\calls.txt"
echo %BUILDKIT_CONFIGURATION%> "%BUILDKIT_OUTPUT_DIR%\windows\QuanClashCore.exe"
echo %BUILDKIT_CONFIGURATION%> "%BUILDKIT_OUTPUT_DIR%\windows\QuanClashHelperService.exe"
''');
      Future<void> run(List<String> arguments) async {
        final result = await Process.run(
          cmake!,
          arguments,
          environment: {'BUILDKIT_OUTPUT_DIR': output},
        );
        expect(
          result.exitCode,
          0,
          reason: '${result.stdout}\n${result.stderr}',
        );
      }

      final build = p.join(root.path, 'cmake-build');
      await run([
        '-S',
        source.path,
        '-B',
        build,
        '-G',
        'Ninja Multi-Config',
        '-DCMAKE_MAKE_PROGRAM=$ninja',
      ]);
      Future<void> buildConfig(String config) => run([
        '--build',
        build,
        '--config',
        config,
        '--target',
        'setup_buildkit_build',
      ]);
      await buildConfig('Debug');
      await buildConfig('Debug');
      await buildConfig('Release');
      expect(await File(p.join(project.path, 'calls.txt')).readAsLines(), [
        'Debug',
        'Debug',
        'Release',
      ]);
      expect((await core.readAsString()).trim(), 'Release');
      expect((await helper.readAsString()).trim(), 'Release');
      await helper.delete();
      await buildConfig('Release');
      expect(await helper.exists(), isTrue);
      expect(
        await Directory(p.join(project.path, 'libclash')).exists(),
        isFalse,
      );
    },
    skip: !Platform.isWindows || cmake == null || ninja == null
        ? 'Opt-in: set QUANCLASH_BUILDKIT_TEST_CMAKE/NINJA for a marker-only CMake fixture'
        : false,
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
