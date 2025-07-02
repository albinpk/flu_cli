import 'package:process_run/process_run.dart';

/// Checks whether the [cmd] is available on the system.
bool isCmdAvailable(String cmd) => whichSync(cmd) != null;
