import 'package:flutter/material.dart';

/// Thin wrapper around the default Material [TextTheme]. Kept intentionally
/// empty of overrides — swap in a custom font family here if a project needs
/// one.
class AppTextTheme {
  const AppTextTheme._();

  static TextTheme build(ColorScheme scheme) =>
      Typography.material2021(colorScheme: scheme).black
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}
