import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

import '../models/flutter_app.dart';
import '../version.g.dart';

// TODO(albin): add ref / tag
const _rustBinUrl =
    'https://github.com/albinpk/flu_cli/blob/gen-dev/bin/rust_dart_gen?raw=true';

/// Handle model generation related operations.
class GenService {
  /// Create a new [GenService].
  const GenService(this.app);

  /// The Flutter app.
  final FlutterApp app;

  /// The path to the flu_gen rust binary.
  String get rustBinaryPath => p.join(
    p.dirname(Platform.script.toFilePath()),
    'flu_gen-$fluVersion',
  );

  /// Whether the flu_gen rust binary is available.
  bool hasRustBinary() => File(rustBinaryPath).existsSync();

  /// Download and save the flu_gen rust binary from GitHub.
  Future<void> downloadRustBinary() async {
    final logger = Logger();
    final httpClient = HttpClient();
    final progress = logger.progress('Downloading executable file');
    try {
      final request = await httpClient.getUrl(Uri.parse(_rustBinUrl));
      final response = await request.close();
      final sink = File(rustBinaryPath).openWrite();
      await response.pipe(sink);
      await sink.close();
      // TODO(albin): windows?
      await app.shell.run('chmod +x $rustBinaryPath');
      progress.complete('Downloaded complete!');
    } catch (e) {
      progress.fail('Failed to download!');
      rethrow;
    } finally {
      httpClient.close();
    }
  }

  /// Run the flu_gen rust binary.
  Future<void> generate() async {
    if (!hasRustBinary()) {
      try {
        await downloadRustBinary();
      } catch (e) {
        Logger().err(e.toString());
        return;
      }
    }

    await app.shell.run(rustBinaryPath);
  }
}

// benchmark

// 10 files
// build_runner: =>
//      24.45s user 1.89s system 145% cpu 18.119 total
//      2.90s user 0.44s system 110% cpu 3.036 total
// flu_gen =>
//      0.03s user 0.01s system 61% cpu 0.059 total
//      0.03s user 0.01s system 81% cpu 0.045 total

// 100 files
// build_runner: =>
//      30.32s user 2.61s system 140% cpu 23.443 total
//      5.57s user 0.71s system 129% cpu 4.858 total
// flu_gen =>
//      0.21s user 0.04s system 80% cpu 0.306 total
//      0.16s user 0.02s system 91% cpu 0.195 total

// 500 files
// build_runner: =>
//      52.93s user 5.24s system 138% cpu 41.911 total
//      17.46s user 1.71s system 150% cpu 12.763 total
// flu_gen =>
//      0.92s user 0.15s system 74% cpu 1.442 total
//      0.81s user 0.10s system 87% cpu 1.044 total

// 1000 files
// build_runner: =>
//      87.54s user 11.67s system 129% cpu 1:16.48 total
//      38.55s user 3.69s system 138% cpu 30.524 total
// flu_gen =>
//      1.72s user 0.30s system 81% cpu 2.493 total
//      1.67s user 0.22s system 79% cpu 2.378 total

// 5000 files
// build_runner: =>
//      576.81s user 74.82s system 112% cpu 9:40.13 total
//      224.51s user 8.55s system 120% cpu 3:13.58 total
// flu_gen =>
//      7.95s user 1.31s system 83% cpu 11.115 total
//      7.95s user 1.38s system 83% cpu 11.172 total
