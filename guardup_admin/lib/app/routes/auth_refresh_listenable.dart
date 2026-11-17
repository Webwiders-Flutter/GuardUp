import 'dart:async';

import '/features/auth/di/auth.providers.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRefreshProvider = Provider<AuthRefreshListenable>((ref) {
  final repository = ref.watch(authRepositoryProvider);

  final notifier = AuthRefreshListenable(repository.authStateChanges);

  ref.onDispose(notifier.dispose);

  return notifier;
});

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Stream<AuthState> stream) {
    _subscription = stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
