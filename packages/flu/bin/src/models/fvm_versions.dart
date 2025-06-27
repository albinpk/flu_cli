import 'dart:convert';

class FvmVersions {
  const FvmVersions({
    required this.versions,
  });

  factory FvmVersions.fromMap(Map<String, dynamic> map) => FvmVersions(
    versions: (map['versions'] as List)
        .map((e) => Versions.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  factory FvmVersions.fromJson(String json) =>
      FvmVersions.fromMap(jsonDecode(json) as Map<String, dynamic>);

  final List<Versions> versions;
}

class Versions {
  const Versions({
    required this.name,
  });

  factory Versions.fromJson(Map<String, dynamic> json) => Versions(
    name: json['name'] as String,
  );

  final String name;
}
