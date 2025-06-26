import 'dart:async';

import 'flu_command.dart';

class CreateCommand extends FluCommand {
  CreateCommand({required super.logger});

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project';

  @override
  FutureOr<void>? run() {
    logger.success('Create a new Flutter project');
  }
}
