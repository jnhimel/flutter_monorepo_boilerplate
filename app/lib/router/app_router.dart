import 'package:core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:notes/notes.dart';

import '../auth/auth_cubit.dart';
import '../features/home/home_page.dart';
import '../features/login/login_page.dart';
import '../features/settings/settings_page.dart';
import '../features/splash/splash_page.dart';
import 'go_router_refresh_stream.dart';

GoRouter buildAppRouter(GetIt getIt) {
  final authCubit = getIt<AuthCubit>();

  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final status = authCubit.state;
      final onSplash = state.matchedLocation == AppRoutePaths.splash;
      final onLogin = state.matchedLocation == AppRoutePaths.login;

      switch (status) {
        case AuthUnknown():
          return onSplash ? null : AppRoutePaths.splash;
        case AuthUnauthenticated():
          return onLogin ? null : AppRoutePaths.login;
        case AuthAuthenticated():
          return (onSplash || onLogin) ? AppRoutePaths.home : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(path: AppRoutePaths.login, builder: (_, _) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          notesShellBranch(getIt),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.settings,
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
          // GENERATOR: register feature routes above this line
        ],
      ),
    ],
  );
}
