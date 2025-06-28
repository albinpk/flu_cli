import '../models/package.dart';

/// Network client packages for flutter.
const Set<Package> networkClientPackages = {
  // http
  Package(dependencies: {'http'}),
  Package(dependencies: {'http2'}),

  // dio
  Package(dependencies: {'dio'}),

  // rhttp
  Package(dependencies: {'rhttp'}),

  // retrofit
  Package(
    dependencies: {'retrofit', 'json_annotation'},
    devDependencies: {
      'retrofit_generator',
      'build_runner',
      'json_serializable',
    },
  ),

  // chopper
  Package(
    dependencies: {'chopper'},
    devDependencies: {'build_runner', 'chopper_generator'},
  ),
};
