/// A Dart package model.
class Package {
  const Package({
    required this.dependencies,
    this.name,
    this.devDependencies = const {},
  });

  static const Package none = Package(name: 'None', dependencies: {});

  bool get isNone => this == none;

  final Set<String> dependencies;
  final String? name;
  final Set<String> devDependencies;

  String get displayName => name ?? dependencies.first;
}
