import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Deploys the NNUE evaluation file from assets to a filesystem path
/// that the native Pikafish engine can read.
class NnueDeployer {
  static const String _assetPath = 'assets/pikafish.nnue';
  static const String _fileName = 'pikafish.nnue';

  static String? _cachedPath;

  /// Returns the absolute path to the NNUE file,
  /// copying from assets ONLY if necessary (missing or size mismatch).
  static Future<String> deploy() async {
    if (_cachedPath != null) return _cachedPath!;

    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/$_fileName');

    // Load asset metadata to check size
    final ByteData assetData = await rootBundle.load(_assetPath);
    final int assetSize = assetData.lengthInBytes;

    bool shouldCopy = true;
    if (await dest.exists()) {
      final stat = await dest.stat();
      if (stat.size == assetSize) {
        shouldCopy = false;
      }
    }

    if (shouldCopy) {
      print(
          '[Engine] Deploying 52MB NNUE asset to ${dest.path} (one-time operation)...');
      final Stopwatch sw = Stopwatch()..start();

      final bytes = assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      );
      await dest.writeAsBytes(bytes, flush: true);

      print('[Engine] NNUE deployment took ${sw.elapsedMilliseconds}ms');
    }

    _cachedPath = dest.path;
    return _cachedPath!;
  }

  /// Forces re-deployment (useful for updates).
  static Future<String> redeploy() async {
    _cachedPath = null;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/$_fileName');
    if (await dest.exists()) await dest.delete();
    return deploy();
  }
}
