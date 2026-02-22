import 'dart:io';

/// Detects hardware capabilities to choose the optimal Pikafish binary.
/// Reads /proc/cpuinfo directly — no FFI needed.
class CpuDetector {
  static bool? _hasDotprod;

  /// Returns true if this ARM64 CPU supports dotProduct (asimddp).
  /// This selects libpikafish_dotprod.so over libpikafish.so.
  static Future<bool> hasDotprod() async {
    if (_hasDotprod != null) return _hasDotprod!;
    try {
      final cpuInfo = await File('/proc/cpuinfo').readAsString();
      _hasDotprod = cpuInfo.contains('asimddp') ||
          cpuInfo.contains('dotprod') ||
          cpuInfo.contains('svei8mm');
    } catch (e) {
      // If we cannot read /proc/cpuinfo (e.g. SELinux restrictions on physical device)
      // gracefully fallback to the basic ARM64 binary without dotprod.
      print('[Engine] Warning: Could not read /proc/cpuinfo - $e');
      _hasDotprod = false;
    }
    return _hasDotprod!;
  }

  /// Returns the .so filename for the best-fit engine binary.
  static Future<String> selectLibraryName() async {
    return await hasDotprod() ? 'libpikafish_dotprod.so' : 'libpikafish.so';
  }
}
