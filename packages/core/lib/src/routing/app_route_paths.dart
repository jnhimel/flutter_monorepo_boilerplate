/// Top-level route path constants shared between `app` and any feature
/// package that needs to build a `GoRoute` under one of the shell branches.
class AppRoutePaths {
  const AppRoutePaths._();

  static const splash = '/splash';
  static const login = '/login';

  // Bottom-nav shell branches.
  static const home = '/home';
  static const notes = '/notes';
  static const settings = '/settings';
}
