import 'dart:io';

import 'package:flu/src/command_runner.dart';

Future<void> main(List<String> args) async {
  var code = 0;
  try {
    await FluCommandRunner().run(args);
  } catch (e) {
    code = 1;
  }
  await flushThenExit(code);
}

Future<void> flushThenExit(int code) {
  return Future.wait<void>([
    stdout.close(),
    stderr.close(),
  ]).then<void>((_) => exit(code));
}
