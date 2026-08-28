import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Trivial placeholder — no feature package needed for a tab this simple.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppAppBar(title: 'Home'),
      body: const Center(child: AppText.title('Welcome')),
    );
  }
}
