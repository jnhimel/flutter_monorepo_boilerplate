import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a `Stream` (here, `AuthCubit`'s state stream) to go_router's
/// `refreshListenable`, so the router re-evaluates its `redirect` whenever
/// auth status changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
