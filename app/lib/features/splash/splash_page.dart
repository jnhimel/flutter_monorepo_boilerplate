import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/auth_cubit.dart';

/// Checks for a stored auth token, then lets `AppRouter`'s redirect send the
/// user to `/login` or `/home` once `AuthCubit` emits.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: AppLoadingIndicator());
}
