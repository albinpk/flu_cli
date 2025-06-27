import 'dart:async';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:process_run/process_run.dart';

import '../models/fvm_versions.dart';
import 'flu_command.dart';

class CreateCommand extends FluCommand {
  CreateCommand({required super.logger});

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project';

  Versions? _fvmFlutterVersion;

  String get _flutterCmd =>
      _fvmFlutterVersion != null ? 'fvm flutter' : 'flutter';

  String get _dartCmd => _fvmFlutterVersion != null ? 'fvm dart' : 'dart';

  @override
  Future<void> run() async {
    final projectName = logger.prompt('Project name:').toSnakeCase();
    if (projectName.trim().isEmpty) {
      return logger.err('Project name cannot be empty');
    }

    final orgName = logger.prompt(
      'Organization name:',
      defaultValue: 'com.example',
    );

    _fvmFlutterVersion = await _getFlutterVersion();

    // create flutter project
    await _createProject(
      projectName: projectName,
      orgName: orgName,
    );

    // project root shell
    final shell = Shell(workingDirectory: './$projectName', verbose: false);

    // FVM config
    if (_fvmFlutterVersion != null) {
      await _configureFvm(shell: shell);
    }

    // get and upgrade dependencies
    await _getDependencies(shell: shell);

    // dart fix and format
    await _fixAndFormat(shell: shell);
  }

  Future<Versions?> _getFlutterVersion() async {
    final useFvm = logger.confirm(
      'Do you want to use FVM?',
      defaultValue: true,
    );
    if (!useFvm) return null;

    final shell = Shell(verbose: false);
    // install fvm if not installed
    if (await which('fvm') == null) {
      final confirmInstall = logger.confirm(
        'FVM is not installed. Do you want to install it?',
      );
      if (!confirmInstall) {
        logger.info('FVM configuration skipped.');
        return null;
      }

      final progress = logger.progress('Installing FVM...');
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
      progress.complete('FVM installed successfully');
    }

    // choose flutter version
    final versionResult = await shell.run(
      'fvm api list --compress --skip-size-calculation',
    );
    final versions = FvmVersions.fromJson(versionResult.first.outText).versions;
    if (versions.isEmpty) {
      return throw Exception('No Flutter versions found in FVM');
    }
    return logger.chooseOne<Versions>(
      'Choose Flutter version:',
      choices: versions,
      display: (choice) => choice.name,
    );
  }

  Future<void> _createProject({
    required String projectName,
    required String orgName,
  }) async {
    var createCommand = 'create $projectName --org $orgName --no-pub --empty';
    if (_fvmFlutterVersion case Versions(:final name)) {
      createCommand = 'fvm spawn $name $createCommand';
    } else {
      createCommand = 'flutter $createCommand';
    }
    final progress = logger.progress('Creating project...');
    await Shell(verbose: false).run(createCommand);
    progress.complete('Project created successfully');
  }

  Future<void> _configureFvm({required Shell shell}) async {
    final progress = logger.progress('Configuring FVM...');
    await shell.run(
      'fvm use ${_fvmFlutterVersion!.name} --force --skip-setup --skip-pub-get',
    );
    // adding fvm to .gitignore
    await File('${shell.options.workingDirectory!}/.gitignore').writeAsString(
      '''

# FVM Version Cache
.fvm/
''',
      mode: FileMode.append,
    );
    progress.complete('FVM configured successfully');
  }

  Future<void> _getDependencies({required Shell shell}) async {
    final progress = logger.progress('Downloading dependencies...');
    await shell.run('''
$_flutterCmd pub get
$_flutterCmd pub upgrade
''');
    progress.complete('Dependencies downloaded successfully');
  }

  Future<void> _fixAndFormat({required Shell shell}) async {
    final progress = logger.progress('Code formatting...');
    await shell.run('''
$_dartCmd fix --apply
$_dartCmd format .
''');
    progress.complete('Code formatted successfully');
  }
}
