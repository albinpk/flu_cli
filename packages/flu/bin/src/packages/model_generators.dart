import '../models/package.dart';

/// Code generation packages.
const Set<Package> modelGeneratorPackages = {
  Package(
    name: 'freezed',
    dependencies: {'freezed_annotation', 'json_annotation'},
    devDependencies: {'build_runner', 'freezed', 'json_serializable'},
  ),
  Package(
    name: 'json_serializable',
    dependencies: {'json_annotation'},
    devDependencies: {'build_runner', 'json_serializable'},
  ),
};
