import 'package:injectable/injectable.dart';

import '../storage/database/app_database.dart';
import '../storage/hive_service.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

/// Provides the core services injectable can't generate a registration for
/// directly: [AppDatabase] and [SecureStorageService] both take an optional
/// test-only constructor parameter injectable can't resolve, and
/// [PreferencesService]/[HiveService] need an async `init()` step before
/// they're usable.
@module
abstract class CoreModule {
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();

  @lazySingleton
  SecureStorageService get secureStorageService => SecureStorageService();

  @preResolve
  Future<PreferencesService> get preferencesService async {
    final service = PreferencesService();
    await service.init();
    return service;
  }

  @preResolve
  Future<HiveService> get hiveService async {
    final service = HiveService();
    await service.init();
    return service;
  }
}
