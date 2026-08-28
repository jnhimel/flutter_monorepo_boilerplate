import 'package:core/core.dart';

/// Per-flavor configuration, set once in `main_<flavor>.dart` before
/// `bootstrap()` runs.
class EnvConfig {
  const EnvConfig({
    required this.flavorName,
    required this.baseUrl,
    this.securityConfig = const SecurityConfig(),
  });

  final String flavorName;

  /// ponytail: placeholder URL, not a real backend. Point this at the
  /// project's actual API per flavor.
  final String baseUrl;

  final SecurityConfig securityConfig;
}
