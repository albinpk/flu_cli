import 'dart:io';

import './src/command_runner.dart';

Future<void> main(List<String> args) async {
  var code = 0;
  try {
    await FluCommandRunner().run(args);
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    code = 1;
    // ignore: avoid_print
    print(e);
  }
  await flushThenExit(code);
}

Future<void> flushThenExit(int code) {
  return Future.wait<void>([
    stdout.close(),
    stderr.close(),
  ]).then<void>((_) => exit(code));
}
