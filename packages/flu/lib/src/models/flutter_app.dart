import 'dart:io';

import 'package:process_run/process_run.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Represents a Flutter app.
class FlutterApp {
  /// Creates a new [FlutterApp].
  const FlutterApp(this._shell);

  /// A [Shell] instance pointing to the root directory of the Flutter app.
  final Shell _shell;

  /// The root directory of the Flutter app.
  String get _root => _shell.options.workingDirectory!;

  /// The `pubspec.yaml` file of the Flutter app.
  File get pubspecFile => File('$_root/pubspec.yaml');

  /// The `analysis_options.yaml` file of the Flutter app.
  File get analysisOptionsFile => File('$_root/analysis_options.yaml');

  /// The `lib/main.dart` file of the Flutter app.
  File get mainFile => File('$_root/lib/main.dart');

  /// The `.gitignore` file of the Flutter app.
  File get gitIgnoreFile => File('$_root/.gitignore');

  /// Adds give [line] to the `.gitignore` file if it doesn't exist.
  Future<void> addToGitIgnore(String line) async => addAllToGitIgnore([line]);

  /// Adds multiple lines to the `.gitignore` file if they don't exist.
  Future<void> addAllToGitIgnore(List<String> lines) async {
    final gitignoreLines = await gitIgnoreFile.readAsLines();
    final linesToAdd = lines.where((e) => !gitignoreLines.contains(e)).toList();
    if (linesToAdd.isEmpty) return;
    gitignoreLines.add('\n${linesToAdd.join('\n')}\n');
    await gitIgnoreFile.writeAsString(gitignoreLines.join('\n'));
  }

  /// Sets the `version` field of the `pubspec.yaml` file to [version].
  Future<void> setPubspecVersion(String version) async {
    final pubSource = await pubspecFile.readAsString();
    final editor = YamlEditor(pubSource)..update(['version'], version);
    await pubspecFile.writeAsString(editor.toString());
  }
}
