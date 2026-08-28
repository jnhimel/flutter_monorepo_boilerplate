import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// App-wide theme mode, persisted through core's `PreferencesService`.
/// Registered as a singleton so `SettingsPage` and `AppWidget` share one
/// instance.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController(this._prefs)
    : super(
        _prefs.getBool(PreferencesService.themeModeKey)
            ? ThemeMode.dark
            : ThemeMode.light,
      );

  final PreferencesService _prefs;

  Future<void> toggle() async {
    final next = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _prefs.setBool(
      PreferencesService.themeModeKey,
      next == ThemeMode.dark,
    );
    value = next;
  }
}
