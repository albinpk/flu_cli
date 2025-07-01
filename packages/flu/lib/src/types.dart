import 'dart:async';

import 'models/models.dart';

/// Post install callback for a package.
typedef PostInstallCallback = FutureOr<void> Function(FlutterApp app);
