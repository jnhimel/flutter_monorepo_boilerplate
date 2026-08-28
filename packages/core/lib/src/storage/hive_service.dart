import 'package:hive_flutter/hive_flutter.dart';

/// Thin generic key-value wrapper over Hive — one `settings` box, not a full
/// ORM layer. Use [AppDatabase] (Drift) instead when you need real querying.
///
/// ponytail: single generic box ceiling; add typed boxes/adapters per model
/// if a project outgrows key-value settings storage.
class HiveService {
  static const settingsBoxName = 'settings';

  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(settingsBoxName);
  }

  T? get<T>(String key) => _settingsBox.get(key) as T?;

  Future<void> put(String key, dynamic value) => _settingsBox.put(key, value);

  Future<void> delete(String key) => _settingsBox.delete(key);
}
