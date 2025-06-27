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

  late final String _projectName;
  late final String _orgName;
  late final Versions? _fvmFlutterVersion;
  late final bool _useMelos;

  String get _flutterCmd =>
      _fvmFlutterVersion != null ? 'fvm flutter' : 'flutter';

  String get _dartCmd => _fvmFlutterVersion != null ? 'fvm dart' : 'dart';

  final _verbose = false;

  @override
  Future<void> run() async {
    _projectName = logger.prompt('Project name:').toSnakeCase();
    if (_projectName.trim().isEmpty) {
      return logger.err('Project name cannot be empty');
    }

    _orgName = logger.prompt(
      'Organization name:',
      defaultValue: 'com.example',
    );

    _fvmFlutterVersion = await _getFlutterVersion();

    _useMelos = await _configureMelos();

    // create flutter project
    await _createProject();

    // project root shell
    final rootShell = Shell(
      workingDirectory: _projectName,
      verbose: _verbose,
    );
    // flutter app root shell
    final appShell = _useMelos
        ? Shell(
            workingDirectory: '$_projectName/apps/$_projectName',
            verbose: _verbose,
          )
        : rootShell;

    // FVM config
    if (_fvmFlutterVersion != null) {
      await _configureFvm(shell: appShell);
    }

    // get and upgrade dependencies
    await _getDependencies(shell: appShell);

    // dart fix and format
    await _fixAndFormat(shell: rootShell);
  }

  bool _isCmdAvailable(String cmd) => whichSync(cmd) != null;

  Future<Versions?> _getFlutterVersion() async {
    final useFvm = logger.confirm(
      'Do you want to use FVM?',
      defaultValue: true,
    );
    if (!useFvm) return null;

    final shell = Shell(verbose: _verbose);
    // install fvm if not installed
    if (!_isCmdAvailable('fvm')) {
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

  Future<void> _createProject() async {
    var createCommand = 'create $_projectName --org $_orgName --no-pub --empty';
    if (_fvmFlutterVersion case Versions(:final name)) {
      createCommand = 'fvm spawn $name $createCommand';
    } else {
      createCommand = 'flutter $createCommand';
    }
    final progress = logger.progress('Creating project...');
    await Shell(
      verbose: _verbose,
      workingDirectory: _useMelos ? '$_projectName/apps' : null,
    ).run(createCommand);
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

  Future<bool> _configureMelos() async {
    final useMelos = logger.confirm('Do you want to use Melos?');
    if (!useMelos) return false;
    final shell = Shell(verbose: _verbose);

    // install melos if not installed
    if (!_isCmdAvailable('melos')) {
      final confirmInstall = logger.confirm(
        'Melos is not installed. Do you want to install it?',
      );
      if (!confirmInstall) {
        logger.info('Melos configuration skipped.');
        return false;
      }
      final progress = logger.progress('Installing melos...');
      await shell.run('$_dartCmd pub global activate melos ^7.0.0-dev.9');
      progress.complete('Melos installed successfully');
    }

    final melosVersion = (await shell.run('melos --version')).outText;

    // configure melos
    final workspaceName = logger.prompt(
      'Melos workspace name:',
      defaultValue: _projectName.toPascalCase(),
    );

    // root pubspec
    final pubspecFile = await File(
      '$_projectName/pubspec.yaml',
    ).create(recursive: true);
    await pubspecFile.writeAsString('''
name: $workspaceName

environment:
  sdk: ">=3.8.1 <4.0.0"

dev_dependencies:
  melos: ^$melosVersion

# workspace: 

melos:
''');

    // root .gitignore
    final gitIgnore = await File(
      '$_projectName/.gitignore',
    ).create();
    await gitIgnore.writeAsString('''
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
''');

    await Directory('$_projectName/apps').create(recursive: true);
    return true;
  }
}
