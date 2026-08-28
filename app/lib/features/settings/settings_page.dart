import 'package:core/core.dart';
import 'package:flutter/material.dart';

import '../../theme_mode_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeModeController>();
    final hive = getIt<HiveService>();

    return Scaffold(
      appBar: const AppAppBar(title: 'Settings'),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController,
        builder: (context, mode, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: const AppText.body('Dark mode'),
                value: mode == ThemeMode.dark,
                onChanged: (_) => themeController.toggle(),
              ),
              // ponytail: locale switcher stub — only `en` ships (see
              // README for how to add a translated locale). Persists the
              // choice through HiveService to demonstrate that storage path.
              ListTile(
                title: const AppText.body('Language'),
                trailing: DropdownButton<String>(
                  value: hive.get<String>('locale') ?? 'en',
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) => hive.put('locale', value ?? 'en'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
