/// Crash/error reporting seam. Wire a real Crashlytics/Sentry implementation
/// of this interface per-project — deliberately not a dependency of this
/// package so `core` doesn't force a firebase/sentry SDK on every consumer.
abstract class ErrorReporter {
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false});
}

/// No-op default so the app runs out of the box. Replace the registration in
/// `registerCoreDependencies` with a real implementation when wiring
/// Crashlytics/Sentry.
class NoopErrorReporter implements ErrorReporter {
  @override
  void recordError(Object error, StackTrace stackTrace, {bool fatal = false}) {
    // ponytail: no-op ceiling — swap for a real ErrorReporter (Crashlytics/
    // Sentry) per project; this ships so bootstrap() has something to call.
  }
}
