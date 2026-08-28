/// Security feature flags for a given app flavor. Both default to `false`
/// because this boilerplate ships stubs, not working implementations.
///
/// To turn on SSL pinning for real: implement certificate/public-key
/// checking in [DioClient]'s `_pinningInterceptor` hook (see network/dio_client.dart)
/// and flip [sslPinningEnabled] to `true` for the flavor(s) that should
/// enforce it.
///
/// To turn on root/jailbreak detection: add a package such as
/// `flutter_jailbreak_detection` at the app level (not in core — keep this
/// package dependency-light), call it during `bootstrap()`, and flip
/// [rootDetectionEnabled] to `true`.
class SecurityConfig {
  const SecurityConfig({
    this.sslPinningEnabled = false,
    this.rootDetectionEnabled = false,
  });

  final bool sslPinningEnabled;
  final bool rootDetectionEnabled;
}
