import 'dart:async';

import '../models/flutter_app.dart';
import '../services/gen_service.dart';
import 'flu_command.dart';

/// `flu gen` command.
class GenCommand extends FluCommand {
  /// Creates a new [GenCommand].
  GenCommand({required super.logger}) {
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
  String get name => 'gen';

  @override
  String get description => '';

  @override
  Future<void> run() async {
    final app = FlutterApp.findFromCurrentDirectory();
    if (app == null) {
      throw Exception(
        'No Flutter app found in current directory or parent directories',
      );
    }

    final genService = GenService(app);

    await genService.generate();
  }

  // options and flags names
  static const _kClassName = 'class-name';
  static const _kWatch = 'watch';
}
