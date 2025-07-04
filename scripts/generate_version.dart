// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

Future<void> main() async {
  final versionPath = p.joinAll(
    [Directory.current.path, 'packages', 'flu', 'lib', 'src', 'version.g.dart'],
  );
  print('Updating generated file $versionPath');
  final fluPubspec = p.joinAll([
    Directory.current.path,
    'packages',
    'flu',
    'pubspec.yaml',
  ]);
  final yamlMap = loadYaml(await File(fluPubspec).readAsString()) as YamlMap;
  final currentVersion = yamlMap['version'] as String;
  final versionFileContent =
      """
// This file is generated.

/// The current version of Flu CLI.
const String fluVersion = '$currentVersion';
""";
  await File(versionPath).writeAsString(versionFileContent);
  print('Version updated successfully');
}
