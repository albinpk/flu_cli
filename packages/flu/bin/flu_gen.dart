import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:process_run/process_run.dart';

Future<void> main(List<String> args) async {
  await Shell().run('pwd');
  print('src: ${Platform.script}');
  final dir = dirname(Platform.script.toFilePath());
  await File(path.join(dir, 'flu_hello')).create();
  print('done');
}
