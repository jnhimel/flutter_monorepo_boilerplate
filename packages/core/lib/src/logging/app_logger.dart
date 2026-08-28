import 'package:logger/logger.dart' as pkg;

/// Thin logging facade so features depend on this interface, not on the
/// `logger` package directly (keeps the swap-to-something-else cost low).
abstract class AppLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default console implementation backed by package:logger. Good enough for
/// dev/local; wire a real backend in via [ErrorReporter] instead of swapping
/// this out.
class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger()
    : _logger = pkg.Logger(printer: pkg.PrettyPrinter(methodCount: 0));

  final pkg.Logger _logger;

  @override
  void debug(String message) => _logger.d(message);

  @override
  void info(String message) => _logger.i(message);

  @override
  void warning(String message) => _logger.w(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
