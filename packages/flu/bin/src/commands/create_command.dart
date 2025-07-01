import 'dart:async';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:process_run/process_run.dart';

import '../models/models.dart';
import '../packages/packages.dart';
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
  late final Shell _rootShell;
  late final Shell _appShell;

  String get _flutterCmd =>
      _fvmFlutterVersion != null ? 'fvm flutter' : 'flutter';

  String get _dartCmd => _fvmFlutterVersion != null ? 'fvm dart' : 'dart';

  final bool _verbose = false;

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
    _rootShell = Shell(
      workingDirectory: _projectName,
      verbose: _verbose,
    );
    // flutter app root shell
    _appShell = _useMelos
        ? Shell(
            workingDirectory: '$_projectName/apps/$_projectName',
            verbose: _verbose,
          )
        : _rootShell;

    // FVM config
    if (_fvmFlutterVersion != null) {
      await _configureFvm();
    }

    // get and upgrade dependencies
    await _getDependencies();

    // dart fix and format
    await _fixAndFormat();

    await _addCustomAnalyzer();

    final packages = <Package>[
      ?_choosePackage(modelGeneratorPackages, 'model generator'),
      ?_choosePackage(stateManagementPackages, 'state management'),
      ?_choosePackage(navigatorPackages, 'navigator'),
      ?_choosePackage(networkClientPackages, 'network client'),
    ];

    final additionalPackages = logger.chooseAny(
      'Select any additional packages to include',
      choices: additionalPackagesNames.toList(),
    );

    final dependencies = {
      ...packages.map((e) => e.dependencies).expand((e) => e),
      ...additionalPackages,
    };
    final devDependencies = {
      ...packages.map((e) => e.devDependencies).expand((e) => e),
    };

    // installing dependencies
    if (dependencies.isNotEmpty || devDependencies.isNotEmpty) {
      final progress = logger.progress('Adding packages...');
      await _addPackage(deps: dependencies, devDeps: devDependencies);
      progress.complete('Packages added successfully');
    }

    // post install callbacks
    final postInstallCallbacks = packages.map((e) => e.postInstall).nonNulls;
    if (postInstallCallbacks.isNotEmpty) {
      final progress = logger.progress('Configuring packages...');
      for (final fn in postInstallCallbacks) {
        await fn(FlutterApp(_appShell));
      }
      progress.complete('Packages configured successfully');
    }
  }

  bool _isCmdAvailable(String cmd) => whichSync(cmd) != null;

  Future<void> _addPackage({
    Set<String> deps = const {},
    Set<String> devDeps = const {},
  }) async {
    if (deps.isEmpty && devDeps.isEmpty) return;
    await _appShell.run(
      '$_flutterCmd pub add '
      '${deps.join(' ')} '
      '${devDeps.map((e) => 'dev:$e').join(' ')}',
    );
  }

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
    final platforms = ['android', 'ios', 'web', 'linux', 'macos', 'windows'];
    final selectedPlatforms = logger.chooseAny(
      'Select platforms:',
      choices: platforms,
      defaultValues: platforms,
    );
    if (selectedPlatforms.isEmpty) {
      return logger.err('No platforms selected');
    }
    var createCommand =
        'create $_projectName'
        ' --platforms ${selectedPlatforms.join(',')}'
        ' --org $_orgName'
        ' --no-pub'
        ' --empty';
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

  Future<void> _configureFvm() async {
    final progress = logger.progress('Configuring FVM...');
    await _appShell.run(
      'fvm use ${_fvmFlutterVersion!.name} --force --skip-setup --skip-pub-get',
    );
    // adding fvm to .gitignore
    await File(
      '${_appShell.options.workingDirectory!}/.gitignore',
    ).writeAsString(
      '''

# FVM Version Cache
.fvm/
''',
      mode: FileMode.append,
    );
    progress.complete('FVM configured successfully');
  }

  Future<void> _getDependencies() async {
    final progress = logger.progress('Downloading dependencies...');
    await _appShell.run('''
$_flutterCmd pub get
$_flutterCmd pub upgrade
''');
    progress.complete('Dependencies downloaded successfully');
  }

  Future<void> _fixAndFormat() async {
    final progress = logger.progress('Code formatting...');
    await _rootShell.run('''
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

  Future<void> _addCustomAnalyzer() async {
    final analyzer = logger.chooseOne(
      'Choose an analyzer:',
      choices: AnalyzerPackages.values,
      display: (choice) => choice.name.toSnakeCase(),
    );
    // flutter_lints is default
    if (analyzer == AnalyzerPackages.flutterLints) return;

    final progress = logger.progress('Updating analyzer...');
    await _appShell.run('$_flutterCmd pub remove flutter_lints');
    final analysisOptionsFile = File(
      '${_appShell.options.workingDirectory!}/analysis_options.yaml',
    );
    if (analyzer != AnalyzerPackages.none) {
      await _addPackage(devDeps: {analyzer.name.toSnakeCase()});
    }
    await analysisOptionsFile.writeAsString(
      '${analyzer.analysisOptionsEntry}\n',
    );
    progress.complete('Analyzer updated successfully');
  }

  Package? _choosePackage(Set<Package> packages, String category) {
    final package = logger.chooseOne(
      'Select a $category package to install',
      choices: [...packages, Package.none],
      display: (choice) => choice.displayName,
    );
    return package.isNone ? null : package;
  }
}
