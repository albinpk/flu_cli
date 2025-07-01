import '../models/package.dart';

/// Navigator packages for flutter.
const Set<Package> stateManagementPackages = {
  // riverpod
  Package(
    name: 'riverpod',
    dependencies: {'flutter_riverpod'},
    devDependencies: {'custom_lint', 'riverpod_lint'},
  ),
  Package(
    name: 'riverpod generator',
    dependencies: {'flutter_riverpod', 'riverpod_annotation'},
    devDependencies: {
      'riverpod_generator',
      'build_runner',
      'custom_lint',
      'riverpod_lint',
    },
  ),

  // riverpod + flutter_hooks
  Package(
    name: 'riverpod + flutter_hooks',
    dependencies: {'hooks_riverpod', 'flutter_hooks'},
    devDependencies: {'custom_lint', 'riverpod_lint'},
  ),
  Package(
    name: 'riverpod generator + flutter_hooks',
    dependencies: {'hooks_riverpod', 'flutter_hooks', 'riverpod_annotation'},
    devDependencies: {
      'riverpod_generator',
      'build_runner',
      'custom_lint',
      'riverpod_lint',
    },
  ),

  // bloc
  Package(dependencies: {'flutter_bloc'}),

  // provider
  Package(dependencies: {'provider'}),

  // mobx
  Package(
    dependencies: {'mobx', 'flutter_mobx'},
    devDependencies: {'build_runner', 'mobx_codegen'},
  ),

  // getx
  Package(dependencies: {'get'}),
};
