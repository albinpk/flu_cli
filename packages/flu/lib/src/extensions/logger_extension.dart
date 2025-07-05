import 'package:mason_logger/mason_logger.dart';

/// Logs the object to the console. For development purposes.
@Deprecated('Should not be used in production')
void echo(Object? object, [Object? name]) {
  Logger().success('${name != null ? '$name: ' : ''}$object');
}

/// Extension for logging objects.
extension LoggerExt<T> on T {
  /// Logs the object and returns.
  ///
  /// For development purposes.
  @Deprecated('Should not be used in production')
  T log([Object? name]) {
    echo(this, name);
    return this;
  }
}
