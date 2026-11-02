import 'dart:async';

import 'package:flutter/foundation.dart';

import '/features/auth/auth.dart';

/// A [ChangeNotifier] that listens to [AuthBloc] stream changes
/// and triggers [GoRouter] to re-evaluate its redirect logic.
class AuthRefreshListenable extends ChangeNotifier {
  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _subscription;

  AuthRefreshListenable(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
