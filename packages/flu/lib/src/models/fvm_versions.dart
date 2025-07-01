// ignore_for_file: public_member_api_docs

import 'dart:convert';

/// A model representing `fvm api list` response.
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

/// A flutter version.
class Versions {
  const Versions({
    required this.name,
  });

  factory Versions.fromJson(Map<String, dynamic> json) => Versions(
    name: json['name'] as String,
  );

  /// The name of the version. e.g. `3.32.4`.
  final String name;
}
