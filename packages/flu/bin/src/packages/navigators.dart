import '../models/package.dart';

/// Navigator packages for flutter.
const navigatorPackages = {
  Package(
    dependencies: {'go_router'},
    devDependencies: {'go_router_builder', 'build_runner'},
  ),
  Package(
    dependencies: {'auto_route'},
    devDependencies: {'auto_route_generator', 'build_runner'},
    requireCodegen: true,
  ),
  Package(
    name: kFlutterNavigator2,
    isInbuilt: true,
    dependencies: {},
  ),
};

const kFlutterNavigator2 = 'Flutter Navigator 2';
