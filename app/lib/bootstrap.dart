import 'dart:async';

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:notes/notes.dart';

import 'auth/auth_cubit.dart';
import 'auth/auth_repository.dart';
import 'env/env_config.dart';
import 'router/app_router.dart';
import 'theme_mode_controller.dart';

/// Shared app startup, called from each `main_<flavor>.dart`. Registers
/// every dependency, then runs [app] inside a guarded zone so uncaught
/// errors reach [ErrorReporter] instead of just the console.
Future<void> bootstrap(EnvConfig env, Widget app) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await registerCoreDependencies(
        getIt,
        baseUrl: env.baseUrl,
        securityConfig: env.securityConfig,
      );
      registerNotesDependencies(getIt);

      getIt.registerLazySingleton<AuthRepository>(FakeAuthRepository.new);
      getIt.registerLazySingleton(
        () => AuthCubit(getIt<AuthRepository>(), getIt<SecureStorageService>()),
      );
      getIt.registerLazySingleton(
        () => ThemeModeController(getIt<PreferencesService>()),
      );
      // GENERATOR: register feature dependencies above this line

      getIt.registerLazySingleton(() => buildAppRouter(getIt));

      FlutterError.onError = (details) {
        getIt<ErrorReporter>().recordError(
          details.exception,
          details.stack ?? StackTrace.current,
          fatal: true,
        );
      };

      runApp(app);
    },
    (error, stackTrace) {
      if (getIt.isRegistered<ErrorReporter>()) {
        getIt<ErrorReporter>().recordError(error, stackTrace, fatal: true);
      }
    },
  );
}
