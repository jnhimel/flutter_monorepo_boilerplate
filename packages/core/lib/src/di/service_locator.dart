import 'package:get_it/get_it.dart';

import '../logging/app_logger.dart';
import '../logging/error_reporter.dart';
import '../network/dio_client.dart';
import '../security/security_config.dart';
import '../storage/database/app_database.dart';
import '../storage/hive_service.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

final GetIt getIt = GetIt.instance;

// ponytail: manual get_it registration; switch to injectable codegen if
// registration count grows unwieldy across many feature packages.

/// Registers everything `core` owns as lazy singletons. Call once from the
/// app's `bootstrap()` before `registerNotesDependencies` (or any other
/// feature package's registration function).
Future<void> registerCoreDependencies(
  GetIt getIt, {
  required String baseUrl,
  SecurityConfig securityConfig = const SecurityConfig(),
}) async {
  getIt.registerLazySingleton<AppLogger>(ConsoleAppLogger.new);
  getIt.registerLazySingleton<ErrorReporter>(NoopErrorReporter.new);

  getIt.registerLazySingleton(
    () => DioClient(
      baseUrl: baseUrl,
      logger: getIt<AppLogger>(),
      securityConfig: securityConfig,
    ),
  );

  getIt.registerLazySingleton(SecureStorageService.new);
  getIt.registerLazySingleton(AppDatabase.new);

  final prefs = PreferencesService();
  await prefs.init();
  getIt.registerSingleton(prefs);

  final hive = HiveService();
  await hive.init();
  getIt.registerSingleton(hive);
}
