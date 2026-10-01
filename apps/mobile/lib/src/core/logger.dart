import 'package:flutter/foundation.dart';

/// Timestamped in-memory log for diagnosing auth/network issues on-device.
/// Everything also goes to console (visible via `flutter logs`) in debug builds.
class AppLog {
  static final List<String> _buf = [];
  static List<String> get entries => List.unmodifiable(_buf);

  static void _add(String level, String msg) {
    final line = '[${DateTime.now().toIso8601String()}] $level $msg';
    if (_buf.length >= 300) _buf.removeAt(0);
    _buf.add(line);
    if (kDebugMode) debugPrint(line);
  }

  /// Redacts obvious secrets before logging.
  static String _scrub(String msg) => msg
      .replaceAll(RegExp(r'"password"\s*:\s*"[^"]*"'), '"password":"***"')
      .replaceAll(RegExp(r'"accessToken"\s*:\s*"[^"]*"'), '"accessToken":"***"')
      .replaceAll(RegExp(r'"refreshToken"\s*:\s*"[^"]*"'), '"refreshToken":"***"')
      .replaceAll(RegExp(r'"otpToken"\s*:\s*"[^"]*"'), '"otpToken":"***"')
      .replaceAll(RegExp(r'Bearer [A-Za-z0-9\-_.]+'), 'Bearer ***');

  static void info(String msg) => _add('INFO', _scrub(msg));
  static void warn(String msg) => _add('WARN', _scrub(msg));
  static void error(String msg) => _add('ERROR', _scrub(msg));
}
