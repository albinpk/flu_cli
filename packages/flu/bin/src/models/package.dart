import '../types.dart';

/// A Dart package model.
class Package {
  const Package({
    required this.dependencies,
    this.name,
    this.devDependencies = const {},
    this.postInstall,
  });

  static const Package none = Package(name: 'None', dependencies: {});

  bool get isNone => this == none;

  final Set<String> dependencies;
  final String? name;
  final Set<String> devDependencies;
  final PostInstallCallback? postInstall;

  String get displayName => name ?? dependencies.first;
}
