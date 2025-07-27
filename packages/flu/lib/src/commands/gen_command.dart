import 'dart:async';

import '../models/flutter_app.dart';
import '../services/gen_service.dart';
import 'flu_command.dart';

/// `flu gen` command.
class GenCommand extends FluCommand {
  /// Creates a new [GenCommand].
  GenCommand({required super.logger});

  @override
  String get name => 'gen';

  @override
  String get description => '[WIP] A faster model generator';

  @override
  Future<void> run() async {
    final app = FlutterApp.findFromCurrentDirectory();
    if (app == null) {
      throw Exception(
        'No Flutter app found in current directory or parent directories',
      );
    }

    final genService = GenService(app);

    if (!genService.hasRustBinary()) {
      final progress = logger.progress('Downloading executable file');
      try {
        await genService.downloadRustBinary();
        progress.complete('Downloaded complete!');
      } catch (e) {
        progress.fail('Failed to download!');
        return logger.err(e.toString());
      }
    }

    final progress = logger.progress('Generating...');
    try {
      await genService.generate();
      progress.complete('Generated successfully!');
    } catch (e) {
      progress.fail('Failed to generate!');
      logger.err(e.toString());
    }
  }
}
