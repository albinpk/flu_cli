import 'dart:async';

import 'package:change_case/change_case.dart';

import '../models/flutter_app.dart';
import '../services/flutter_assets_service.dart';
import 'flu_command.dart';

/// `flu asset` command.
class AssetCommand extends FluCommand {
  /// Creates a new [AssetCommand].
  AssetCommand({required super.logger}) {
    argParser
      ..addFlag(
        _kWatch,
        abbr: 'w',
        negatable: false,
        help: 'Watch for changes and re-generate the assets class.',
      )
      ..addOption(
        _kClassName,
        abbr: 'n',
        defaultsTo: 'Assets',
        help: 'The name of the generated asset class.',
      );
  }

  @override
  String get name => 'asset';

  @override
  String get description =>
      'Generates const references for your Flutter assets.';

  @override
  Future<void> run() async {
    final app = FlutterApp.findFromCurrentDirectory();
    if (app == null) {
      throw Exception(
        'No Flutter app found in current directory or parent directories',
      );
    }

    final assetsService = FlutterAssetsService(app);

    if (result.flag(_kWatch)) {
      await assetsService.listenForChanges(() {
        _generateAssetFile(service: assetsService);
      });
    } else {
      await _generateAssetFile(service: assetsService);
    }
  }

  Future<void> _generateAssetFile({
    required FlutterAssetsService service,
  }) async {
    final assetsPaths = await service.getAssetsPathFromPubspec();
    if (assetsPaths.isEmpty) {
      return logger.warn('No assets found in pubspec.yaml');
    }
    final files = await service.getAssetFiles(paths: assetsPaths);
    await service.generateAssetClass(
      files: files,
      className: result.option(_kClassName)!.toPascalCase(),
    );
    logger.success('Assets generated successfully');
  }

  // options and flags names
  static const _kClassName = 'class-name';
  static const _kWatch = 'watch';
}
