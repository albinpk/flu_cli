import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Base class for all commands.
abstract class FluCommand extends Command<void> {
  FluCommand({required this.logger});

  /// The logger used by this command.
  final Logger logger;
}
