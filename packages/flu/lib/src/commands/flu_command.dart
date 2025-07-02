import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Base class for all `flu` commands.
abstract class FluCommand extends Command<void> {
  /// Creates a new [FluCommand].
  FluCommand({required this.logger});

  /// The logger used by this command.
  final Logger logger;

  /// The [ArgResults] for this command.
  ArgResults get result => argResults!;
}
