import 'dart:async';
import 'dart:io';

import 'package:change_case/change_case.dart';
import 'package:process_run/process_run.dart';

import '../models/models.dart';
import '../packages/packages.dart';
import '../services/fvm_service.dart';
import '../services/melos_service.dart';
import 'flu_command.dart';

/// `flu create` command.
class CreateCommand extends FluCommand {
  /// Creates a new [CreateCommand].
  CreateCommand({required super.logger}) {
    argParser
      ..addOption('name', abbr: 'n', help: 'The name of the project')
      ..addOption(
        'description',
        abbr: 'd',
        help: 'The description of the project',
      )
      ..addOption('org', help: 'The organization name')
      ..addOption('flutter-version', help: 'The Flutter version')
      ..addMultiOption(
        'platforms',
        help: 'The platforms supported by this project',
        allowed: _platforms,
      );
  }

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
    _projectName = (result.option('name') ?? logger.prompt('Project name:'))
        .toSnakeCase();
    if (_projectName.trim().isEmpty) {
      return logger.err('Project name cannot be empty');
    }

    final projectDescription =
        result.option('description') ??
        logger.prompt(
          'Project description:',
          defaultValue: 'A new Flutter project.',
        );

    _orgName =
        result.option('org') ??
        logger.prompt(
          'Organization name:',
          defaultValue: 'com.example',
        );

    _fvmFlutterVersion = await _getFlutterVersion();

    _useMelos = await _configureMelos();

    // create flutter project
    await _createProject(description: projectDescription);

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
      final flutterApp = FlutterApp(_appShell);
      for (final fn in postInstallCallbacks) {
        await fn(flutterApp);
      }
      progress.complete('Packages configured successfully');
    }

    // dart fix and format
    await _fixAndFormat();
  }

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
    final fvmService = FvmService(shell: Shell(verbose: _verbose));

    // if --flutter-version is provided
    final flutterVersion = result.option('flutter-version');
    if (flutterVersion != null) {
      if (!fvmService.isInstalled) {
        throw Exception('FVM is not installed. Install FVM and try again.');
      }
      if (!await fvmService.hasVersion(flutterVersion)) {
        throw Exception('Flutter version $flutterVersion not found in FVM');
      }
      return Versions(name: flutterVersion);
    }

    final useFvm = logger.confirm(
      'Do you want to use FVM?',
      defaultValue: true,
    );
    if (!useFvm) return null;

    // install fvm if not installed
    if (!fvmService.isInstalled) {
      final confirmInstall = logger.confirm(
        'FVM is not installed. Do you want to install it?',
      );
      if (!confirmInstall) {
        logger.info('FVM configuration skipped.');
        return null;
      }

      final progress = logger.progress('Installing FVM...');
      await fvmService.install();
      progress.complete('FVM installed successfully');
    }

    // choose flutter version
    final versions = await fvmService.getVersions();
    if (versions.isEmpty) {
      return throw Exception('No Flutter versions found in FVM');
    }
    return logger.chooseOne<Versions>(
      'Choose Flutter version:',
      choices: versions,
      display: (choice) => choice.name,
    );
  }

  /// List of supported platforms.
  static const _platforms = [
    'android',
    'ios',
    'web',
    'linux',
    'macos',
    'windows',
  ];

  Future<void> _createProject({required String description}) async {
    final selectedPlatforms =
        result.multiOption('platforms').nonEmpty ??
        logger.chooseAny(
          'Select platforms:',
          choices: _platforms,
          defaultValues: _platforms,
        );
    if (selectedPlatforms.isEmpty) {
      return logger.err('No platforms selected');
    }
    var createCommand =
        'create $_projectName'
        ' --platforms ${selectedPlatforms.join(',')}'
        ' --description "$description"'
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
    final fvmService = FvmService(shell: _appShell);
    final progress = logger.progress('Configuring FVM...');
    await fvmService.use(version: _fvmFlutterVersion!.name);
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
    final melosService = MelosService(shell: Shell(verbose: _verbose));
    final useMelos = logger.confirm('Do you want to use Melos?');
    if (!useMelos) return false;

    // install melos if not installed
    if (!melosService.isInstalled) {
      final confirmInstall = logger.confirm(
        'Melos is not installed. Do you want to install it?',
      );
      if (!confirmInstall) {
        logger.info('Melos configuration skipped.');
        return false;
      }
      final progress = logger.progress('Installing melos...');
      await melosService.install();
      progress.complete('Melos installed successfully');
    }

    // configure melos
    final workspaceName = logger.prompt(
      'Melos workspace name:',
      defaultValue: _projectName.toPascalCase(),
    );
    await melosService.configureWorkspace(
      workspaceName: workspaceName,
      projectPath: _projectName,
    );
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

extension _List<T> on List<T> {
  List<T>? get nonEmpty => isEmpty ? null : this;
}
