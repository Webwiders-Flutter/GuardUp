import 'dart:async';
import 'package:flutter/foundation.dart';

/// A [ChangeNotifier] that converts a [Stream] into a [Listenable].
/// This is used by GoRouter's refreshListenable to trigger route rebuilds
/// when the authentication state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
