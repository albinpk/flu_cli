import 'dart:io';

import 'package:process_run/process_run.dart';

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
}
