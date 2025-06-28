import '../models/package.dart';

/// Navigator packages for flutter.
const Set<Package> navigatorPackages = {
  Package(
    dependencies: {'go_router'},
    devDependencies: {'go_router_builder', 'build_runner'},
  ),
  Package(
    dependencies: {'auto_route'},
    devDependencies: {'auto_route_generator', 'build_runner'},
  ),
};
