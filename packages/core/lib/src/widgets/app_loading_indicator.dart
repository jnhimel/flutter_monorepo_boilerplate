import 'package:flutter/material.dart';

/// Standard full-space loading state. One shared spinner instead of every
/// feature building its own centered [CircularProgressIndicator].
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
