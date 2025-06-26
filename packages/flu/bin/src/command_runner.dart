import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/create_command.dart';

/// The executable name for the `flu` CLI.
const executableName = 'flu';

/// A command runner for the `flu` CLI.
class FluCommandRunner extends CompletionCommandRunner<void> {
  FluCommandRunner()
    : _logger = Logger(),
      super(executableName, 'Flutter Utility for Developers') {
    addCommand(CreateCommand(logger: _logger));
  }

  final Logger _logger;
}
