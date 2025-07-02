import 'dart:io';

import 'package:process_run/process_run.dart';

import '../functions.dart';
import '../models/models.dart';

/// FVM utilities and helpers.
class FvmService {
  /// Creates a new [FvmService].
  const FvmService({required this.shell});

  /// The shell to use for running commands.
  final Shell shell;

  /// Whether `fvm` command is available on the system.
  bool get isInstalled => isCmdAvailable('fvm');

  /// Installs `fvm` command on the system.
  Future<void> install() async {
    if (Platform.isMacOS || Platform.isLinux) {
      await shell.run('''
curl -fsSL https://fvm.app/install.sh -o install.sh
bash install.sh
rm install.sh
''');
    } else if (Platform.isWindows) {
      // TODO(albin): test this
      await shell.run('choco install fvm');
    }
  }

  /// List of all installed Flutter versions.
  Future<List<Versions>> getVersions() async {
    final versionResult = await shell.run(
      'fvm api list'
      ' --compress'
      ' --skip-size-calculation',
    );
    return FvmVersions.fromJson(versionResult.first.outText).versions;
  }

  /// Checks whether [version] is installed.
  Future<bool> hasVersion(String version) async {
    return (await getVersions()).any((v) => v.name == version);
  }

  /// Setup FVM on the [shell] directory.
  Future<void> use({required String version}) async {
    await shell.run(
      'fvm use $version'
      ' --force'
      ' --skip-setup'
      ' --skip-pub-get',
    );
    // adding fvm to .gitignore
    await File(
      '${shell.options.workingDirectory!}/.gitignore',
    ).writeAsString(
      '''

# FVM Version Cache
.fvm/
''',
      mode: FileMode.append,
    );
  }
}
