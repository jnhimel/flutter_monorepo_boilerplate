import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../logging/app_logger.dart';
import '../network/dio_client.dart';
import '../security/security_config.dart';
import 'service_locator.config.dart';

final GetIt getIt = GetIt.instance;

/// Registers everything `core` owns. Call once from the app's `bootstrap()`
/// before `registerNotesDependencies` (or any other feature package's
/// registration function).
///
/// Most registrations are generated from `@LazySingleton`/`@module`
/// annotations across this package (see `core_module.dart`,
/// `app_logger.dart`, `error_reporter.dart`). `DioClient` stays manual
/// because it needs a flavor's runtime `baseUrl`/`SecurityConfig`, which
/// injectable can't see at compile time.
@InjectableInit()
Future<void> registerCoreDependencies(
  GetIt getIt, {
  required String baseUrl,
  SecurityConfig securityConfig = const SecurityConfig(),
}) async {
  await getIt.init();

  getIt.registerLazySingleton(
    () => DioClient(
      baseUrl: baseUrl,
      logger: getIt<AppLogger>(),
      securityConfig: securityConfig,
    ),
  );
}
