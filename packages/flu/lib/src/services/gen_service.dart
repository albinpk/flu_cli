import 'dart:io';

import 'package:path/path.dart' as path;

import '../models/flutter_app.dart';
import '../version.g.dart';

/// Git reference / version tag.
const _ref = 'flu-v$fluVersion';

final _rustBinUrl =
    'https://github.com/albinpk/flu_cli/blob/$_ref/bin/rust_dart_gen_${Platform.operatingSystem}?raw=true';

/// Handle model generation related operations.
class GenService {
  /// Create a new [GenService].
  const GenService(this.app);

  /// The Flutter app.
  final FlutterApp app;

  /// The path to the flu_gen rust binary.
  String get rustBinaryPath => path.join(
    path.dirname(Platform.script.toFilePath()),
    'flu_gen-$fluVersion${Platform.isWindows ? '.exe' : ''}',
  );

  /// Whether the flu_gen rust binary is available.
  bool hasRustBinary() => File(rustBinaryPath).existsSync();

  /// Download and save the flu_gen rust binary from GitHub.
  Future<void> downloadRustBinary() async {
    final httpClient = HttpClient();
    try {
      final request = await httpClient.getUrl(Uri.parse(_rustBinUrl));
      final response = await request.close();
      final sink = File(rustBinaryPath).openWrite();
      await response.pipe(sink);
      await sink.close();
      if (Platform.isMacOS || Platform.isLinux) {
        await app.shell.run('chmod +x $rustBinaryPath');
      }
    } catch (e) {
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Run the flu_gen rust binary.
  Future<void> generate() async {
    await app.shell.run(rustBinaryPath);
  }
}
