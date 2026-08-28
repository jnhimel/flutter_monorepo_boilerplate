import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell UI for the Home / Notes / Settings tabs. `app` wires this
/// into a `StatefulShellRoute.indexedStack` alongside its own and the notes
/// package's route branches — this widget only owns the nav bar chrome.
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
