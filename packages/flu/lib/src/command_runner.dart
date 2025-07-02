import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/create_command.dart';

/// The executable name for the `flu` CLI.
const executableName = 'flu';

/// A command runner for the `flu` CLI.
class FluCommandRunner extends CompletionCommandRunner<void> {
  /// Creates a new [FluCommandRunner].
  FluCommandRunner()
    : _logger = Logger(),
      super(executableName, 'Flutter Utility for Developers') {
    addCommand(CreateCommand(logger: _logger));
  }

  final Logger _logger;

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      await runCommand(parse(args));
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _logger.err(e.toString());
    }
  }
}
