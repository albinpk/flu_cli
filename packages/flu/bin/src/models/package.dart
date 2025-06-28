/// A Dart package model.
class Package {
  const Package({
    required this.dependencies,
    this.name,
    this.devDependencies = const {},
    this.requireCodegen = false,
    this.isInbuilt = false,
  });

  final Set<String> dependencies;
  final String? name;
  final Set<String> devDependencies;
  final bool requireCodegen;
  final bool isInbuilt;

  String get displayName => name ?? dependencies.first;
}
