import 'package:core/src/di/core_module.dart';
import 'package:core/src/storage/database/app_database.dart';
import 'package:core/src/storage/secure_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `CoreModule` must stay `abstract` for `injectable_generator` (it errors
/// with "[CoreModule] must be an abstract class!" otherwise), so it can't be
/// instantiated directly here. Mirrors the private `_$CoreModule` subclass
/// injectable itself generates in `service_locator.config.dart` — a
/// no-override subclass just to get a concrete instance for this test.
class _TestCoreModule extends CoreModule {}

void main() {
  final module = _TestCoreModule();

  test('appDatabase provides an AppDatabase instance', () {
    expect(module.appDatabase, isA<AppDatabase>());
  });

  test('secureStorageService provides a SecureStorageService instance', () {
    expect(module.secureStorageService, isA<SecureStorageService>());
  });

  test(
    'preferencesService initializes SharedPreferences before returning',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = await module.preferencesService;
      expect(service.getBool('missing_key'), isFalse);
    },
  );
}
