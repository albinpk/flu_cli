import '../models/package.dart';

/// Network client packages for flutter.
final Set<Package> networkClientPackages = {
  // http
  const Package(dependencies: {'http'}),
  const Package(dependencies: {'http2'}),

  // dio
  const Package(dependencies: {'dio'}),

  // rhttp
  Package(
    dependencies: {'rhttp'},
    postInstall: (app) async {
      // rhttp import and init in the main function
      final mainDart = await app.mainFile.readAsLines();
      mainDart.insert(1, "import 'package:rhttp/rhttp.dart';");
      final mainLine = mainDart.indexOf('void main() {');
      mainDart.replaceRange(mainLine, mainLine + 1, [
        'Future<void> main() async {',
        '  await Rhttp.init();',
      ]);
      await app.mainFile.writeAsString('${mainDart.join('\n')}\n');
    },
  ),

  // retrofit
  const Package(
    dependencies: {'retrofit', 'json_annotation'},
    devDependencies: {
      'retrofit_generator',
      'build_runner',
      'json_serializable',
    },
  ),

  // chopper
  const Package(
    dependencies: {'chopper'},
    devDependencies: {'build_runner', 'chopper_generator'},
  ),
};
