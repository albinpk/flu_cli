import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/asset_command.dart';
import 'commands/create_command.dart';
import 'commands/gen_command.dart';
import 'version.g.dart';

/// The executable name for the `flu` CLI.
const executableName = 'flu';

/// A command runner for the `flu` CLI.
class FluCommandRunner extends CompletionCommandRunner<void> {
  /// Creates a new [FluCommandRunner].
  FluCommandRunner()
    : _logger = Logger(),
      super(executableName, 'Flutter Utility for Developers') {
    argParser.addFlag(
      'version',
      help: 'Print the current version.',
      negatable: false,
    );
    addCommand(CreateCommand(logger: _logger));
    addCommand(AssetCommand(logger: _logger));
    addCommand(GenCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<void> run(Iterable<String> args) async {
    if (args case ['--version']) return _logger.info(fluVersion);

    try {
      await runCommand(parse(args));
    } catch (e) {
      _logger.err(e.toString());
    }
  }
}
