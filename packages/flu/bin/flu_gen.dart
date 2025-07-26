import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/process_run.dart';

Future<void> main(List<String> args) async {
  await Shell().run('pwd');
  print('src: ${Platform.script}');
  print('src: ${dirname(Platform.script.toFilePath())}');
}
