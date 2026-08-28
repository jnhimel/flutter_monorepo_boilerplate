import 'package:core/core.dart';

import 'app_widget.dart';
import 'bootstrap.dart';
import 'env/env_config.dart';

void main() {
  bootstrap(
    const EnvConfig(
      flavorName: 'staging',
      baseUrl: 'https://staging.api.example.com',
      securityConfig: SecurityConfig(),
    ),
    const AppWidget(),
  );
}
