import 'package:process_run/process_run.dart';

Future<void> main(List<String> args) async {
  await Shell().run('pwd');
}
