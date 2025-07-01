import '../types.dart';

/// A Dart package and its dependencies.
class Package {
  /// Creates a new [Package].
  const Package({
    required this.dependencies,
    this.devDependencies = const {},
    this.name,
    this.postInstall,
  });

  /// Represents no package.
  static const Package none = Package(name: 'None', dependencies: {});

  /// Returns whether this package is [none].
  bool get isNone => this == none;

  /// The dependencies of this package.
  final Set<String> dependencies;

  /// The development dependencies of this package.
  final Set<String> devDependencies;

  /// The name of this package to display.
  final String? name;

  /// The post install callback of this package.
  final PostInstallCallback? postInstall;

  /// The display name of this package. Defaults to the first dependency name.
  String get displayName => name ?? dependencies.first;
}
