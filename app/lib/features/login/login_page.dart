import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/auth_cubit.dart';
import '../../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await context.read<AuthCubit>().login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = ok ? null : 'Enter an email and password.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppAppBar(title: l10n.loginTitle),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextField(controller: _emailController, label: l10n.emailLabel),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: l10n.passwordLabel,
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AppText.body(_error!, color: Theme.of(context).colorScheme.error),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: l10n.loginButton,
              onPressed: _submit,
              loading: _loading,
            ),
          ],
        ),
      ),
    );
  }
}
