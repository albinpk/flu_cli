import 'dart:io';

import 'package:process_run/process_run.dart';

import '../functions.dart';

/// Melos utilities and helpers.
class MelosService {
  /// Creates a new [MelosService].
  const MelosService({required this.shell});

  /// The shell to use for running commands.
  final Shell shell;

  /// Whether `melos` command is available on the system.
  bool get isInstalled => isCmdAvailable('melos');

  /// Installs `melos` command on the system.
  Future<void> install() async {
    await shell.run('dart pub global activate melos ^7.0.0-dev.9');
  }

  /// Returns the version of `melos`.
  Future<String> version() async {
    return (await shell.run('melos --version')).outText;
  }

  /// Generates the content of a `pubspec.yaml` file for a Melos workspace.
  Future<String> generatePubspecContent({required String workspaceName}) async {
    final melosVersion = await version();
    return '''
name: $workspaceName

environment:
  sdk: ">=3.8.1 <4.0.0"

dev_dependencies:
  melos: ^$melosVersion

# workspace: 

melos:
''';
  }

  /// Configures a Melos workspace in given [projectPath].
  Future<void> configureWorkspace({
    required String workspaceName,
    required String projectPath,
  }) async {
    // create root pubspec.yaml
    final pubspecFile = await File(
      '$projectPath/pubspec.yaml',
    ).create(recursive: true);
    await pubspecFile.writeAsString(
      await generatePubspecContent(workspaceName: workspaceName),
    );

    // create root .gitignore
    final gitIgnore = await File('$projectPath/.gitignore').create();
    await gitIgnore.writeAsString(gitIgnoreContent);

    //    // create apps directory for the flutter app
    await Directory('$projectPath/apps').create(recursive: true);
  }

  /// Content of a `.gitignore` file for a Melos workspace.
  static const String gitIgnoreContent = '''
# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# Dart/Pub related
**/doc/api/
.dart_tool/
.pub-cache/
.pub/
/build/
''';
}
