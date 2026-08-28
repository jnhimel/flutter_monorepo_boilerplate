import 'package:flutter/material.dart';

/// Thin wrapper over [Text] using the theme's text styles by name, so
/// features don't reach into `Theme.of(context).textTheme` directly.
class AppText extends StatelessWidget {
  const AppText(this.data, {super.key, this.style, this.color});

  const AppText.title(this.data, {super.key, this.color})
    : style = AppTextVariant.title;

  const AppText.body(this.data, {super.key, this.color})
    : style = AppTextVariant.body;

  const AppText.caption(this.data, {super.key, this.color})
    : style = AppTextVariant.caption;

  final String data;
  final AppTextVariant? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = switch (style) {
      AppTextVariant.title => textTheme.titleLarge,
      AppTextVariant.body => textTheme.bodyMedium,
      AppTextVariant.caption => textTheme.bodySmall,
      null => textTheme.bodyMedium,
    };
    return Text(data, style: base?.copyWith(color: color));
  }
}

/// Named text styles [AppText] can render as.
enum AppTextVariant { title, body, caption }
