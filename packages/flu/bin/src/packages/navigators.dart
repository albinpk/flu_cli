import '../models/package.dart';

/// Navigator packages for flutter.
const Set<Package> navigatorPackages = {
  // go_router
  Package(dependencies: {'go_router'}),
  Package(
    name: 'go_router_generator',
    dependencies: {'go_router'},
    devDependencies: {'go_router_builder', 'build_runner'},
  ),

  // auto_route
  Package(
    dependencies: {'auto_route'},
    devDependencies: {'auto_route_generator', 'build_runner'},
  ),
};
