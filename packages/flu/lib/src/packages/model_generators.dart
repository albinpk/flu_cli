import '../models/package.dart';

/// Code generation packages.
final Set<Package> modelGeneratorPackages = {
  Package(
    name: 'freezed',
    dependencies: {'freezed_annotation', 'json_annotation'},
    devDependencies: {'build_runner', 'freezed', 'json_serializable'},
    postInstall: (app) async {
      await app.addAllToGitIgnore(['*.freezed.dart', '*.g.dart']);
    },
  ),
  Package(
    name: 'json_serializable',
    dependencies: {'json_annotation'},
    devDependencies: {'build_runner', 'json_serializable'},
    postInstall: (app) async {
      await app.addToGitIgnore('*.g.dart');
    },
  ),
};
