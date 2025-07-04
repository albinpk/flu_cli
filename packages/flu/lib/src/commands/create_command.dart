import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:change_case/change_case.dart';
import 'package:process_run/process_run.dart';

import '../models/models.dart';
import '../pub_packages/packages.dart';
import '../services/fvm_service.dart';
import '../services/melos_service.dart';
import 'flu_command.dart';

/// `flu create` command.
class CreateCommand extends FluCommand {
  /// Creates a new [CreateCommand].
  CreateCommand({required super.logger}) {
    argParser
      ..addOption(_kName, abbr: 'n', help: 'The name of the project')
      ..addOption(
        _kDescription,
        abbr: 'd',
        help: 'The description of the project',
      )
      ..addOption(_kOrg, help: 'The organization name')
      ..addOption(_kFlutterVersion, help: 'The Flutter version used in FVM')
      ..addMultiOption(
        _kPlatforms,
        help: 'The platforms supported by this project',
        allowed: _platforms,
      )
      ..addFlag(
        _kMelos,
        help: 'Whether to use Melos for the project',
        defaultsTo: null,
      )
      ..addOption(
        _kWorkspaceName,
        help: 'Name used for pub workspace (root pubspec.yaml)',
      )
      ..addOption(_kInitialVersion, help: 'Initial version of the project')
      ..addMultiOption(_kDependencies, help: 'Dependencies of the project')
      ..addMultiOption(
        _kDevDependencies,
        help: 'Dev dependencies of the project',
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
  late final FlutterApp _flutterApp;

  String get _flutterCmd =>
      _fvmFlutterVersion != null ? 'fvm flutter' : 'flutter';

  String get _dartCmd => _fvmFlutterVersion != null ? 'fvm dart' : 'dart';

  final bool _verbose = false;

  @override
  Future<void> run() async {
    _projectName = (result.option(_kName) ?? logger.prompt('Project name:'))
        .toSnakeCase();
    if (_projectName.trim().isEmpty) {
      return logger.err('Project name cannot be empty');
    }

    final projectDescription =
        result.option(_kDescription) ??
        logger.prompt(
          'Project description:',
          defaultValue: 'A new Flutter project.',
        );

    _orgName =
        result.option(_kOrg) ??
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

    _flutterApp = FlutterApp(_appShell);

    // FVM config
    if (_fvmFlutterVersion != null) {
      await _configureFvm();
    }

    await _setInitialVersion();

    // get and upgrade dependencies
    await _getDependencies();

    final dependencies = <String>{};
    final devDependencies = <String>{};

    // if dependencies are provided as arguments use them,
    // otherwise prompt for dependencies

    final argDependencies = result.multiOption(_kDependencies);
    final argDevDependencies = result.multiOption(_kDevDependencies);
    List<Package>? chosenPackages;
    if (argDependencies.isNotEmpty || argDevDependencies.isNotEmpty) {
      dependencies.addAll(argDependencies);
      devDependencies.addAll(argDevDependencies);
    } else {
      await _addCustomAnalyzer();
      chosenPackages = <Package>[
        ?_choosePackage(modelGeneratorPackages, 'model generator'),
        ?_choosePackage(stateManagementPackages, 'state management'),
        ?_choosePackage(navigatorPackages, 'navigator'),
        ?_choosePackage(networkClientPackages, 'network client'),
      ];
      final additionalPackages = logger.chooseAny(
        'Select any additional packages to include',
        choices: additionalPackagesNames.toList(),
      );
      dependencies.addAll({
        ...chosenPackages.map((e) => e.dependencies).expand((e) => e),
        ...additionalPackages,
      });
      devDependencies.addAll({
        ...chosenPackages.map((e) => e.devDependencies).expand((e) => e),
      });
    }

    // installing dependencies
    if (dependencies.isNotEmpty || devDependencies.isNotEmpty) {
      final progress = logger.progress('Adding packages...');
      await _addPackage(deps: dependencies, devDeps: devDependencies);
      progress.complete('Packages added successfully');
    }

    // post install callbacks
    final postInstallCallbacks = chosenPackages
        ?.map((e) => e.postInstall)
        .nonNulls;
    if (postInstallCallbacks?.isNotEmpty ?? false) {
      final progress = logger.progress('Configuring packages...');
      for (final fn in postInstallCallbacks!) {
        await fn(_flutterApp);
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
    final flutterVersion = result.option(_kFlutterVersion);
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
        result.multiOption(_kPlatforms).nonEmpty ??
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

  Future<void> _setInitialVersion() async {
    final version =
        result.option(_kInitialVersion) ??
        logger.chooseOne(
          'Choose an initial version for you project:',
          defaultValue: '0.1.0',
          choices: const [
            '0.1.0',
            '0.0.1',
            '1.0.0',
            '0.1.0-dev.1',
            '0.0.1-dev.1',
            '1.0.0-dev.1',
          ],
        )!;
    final flutterApp = FlutterApp(_appShell);
    await flutterApp.setPubspecVersion(version);
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
    final melosFlag = result.optionalFlag(_kMelos);
    if (melosFlag == false) return false; // has flag: --no-melos
    final melosService = MelosService(shell: Shell(verbose: _verbose));
    if (melosFlag ?? false) {
      // has flag: --melos
      if (!melosService.isInstalled) throw Exception('Melos is not installed');
    } else {
      if (!logger.confirm('Do you want to use Melos?')) return false;
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
    }
    final defaultWorkspaceName =
        result.option(_kWorkspaceName) ?? '${_projectName}_workspace';
    // configure melos
    final workspaceName = melosFlag ?? false
        ? defaultWorkspaceName
        : logger.prompt(
            'Project workspace name:',
            defaultValue: defaultWorkspaceName,
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

  // options and flags names
  static const _kName = 'name';
  static const _kDescription = 'description';
  static const _kOrg = 'org';
  static const _kFlutterVersion = 'flutter-version';
  static const _kPlatforms = 'platforms';
  static const _kMelos = 'melos';
  static const _kWorkspaceName = 'workspace-name';
  static const _kInitialVersion = 'initial-version';
  static const _kDependencies = 'dependencies';
  static const _kDevDependencies = 'dev-dependencies';
}

extension _List<T> on List<T> {
  /// Returns `null` if the list is empty, otherwise returns the list.
  List<T>? get nonEmpty => isEmpty ? null : this;
}

extension on ArgResults {
  /// Returns the value of the flag with the given [name] if it exists.
  ///
  /// This is useful when using `defaultsTo: null` for [ArgParser.addFlag],
  /// as it allows checking if the flag was explicitly set by the user.
  bool? optionalFlag(String name) {
    try {
      return flag(name);
    } catch (e) {
      return null;
    }
  }
}
