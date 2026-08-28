import 'package:flutter/material.dart';

/// Thin wrapper over [AppBar] so every screen gets the same app bar without
/// each feature re-declaring `PreferredSizeWidget` boilerplate.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
