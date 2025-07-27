import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:process_run/process_run.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Represents a Flutter app.
class FlutterApp {
  /// Creates a new [FlutterApp].
  const FlutterApp(this.shell);

  /// Get [FlutterApp] from the current directory.
  static FlutterApp? findFromCurrentDirectory() {
    final directory = _findAppRoot();
    if (directory == null) return null;
    return FlutterApp(Shell(workingDirectory: directory.path));
  }

  /// Find the root directory of the Flutter app from the current directory.
  static Directory? _findAppRoot() {
    var current = Directory.current;
    while (true) {
      final pubspecPath = p.join(current.path, 'pubspec.yaml');
      if (File(pubspecPath).existsSync()) return current;
      if (current.path == current.parent.path) return null;
      current = current.parent;
    }
  }

  /// A [Shell] instance pointing to the root directory of the Flutter app.
  final Shell shell;

  /// The root directory of the Flutter app.
  Directory get rootDirectory => Directory(shell.options.workingDirectory!);

  String get _root => rootDirectory.path;

  /// The `pubspec.yaml` file of the Flutter app.
  File get pubspecFile => File(p.join(_root, 'pubspec.yaml'));

  /// The `analysis_options.yaml` file of the Flutter app.
  File get analysisOptionsFile => File(p.join(_root, 'analysis_options.yaml'));

  /// The `lib/main.dart` file of the Flutter app.
  File get mainFile => File(p.join(_root, 'lib', 'main.dart'));

  /// The `.gitignore` file of the Flutter app.
  File get gitIgnoreFile => File(p.join(_root, '.gitignore'));

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
