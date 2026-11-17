import 'package:guardup_admin/core/logger/app_logger.dart';
import 'package:guardup_admin/features/notifications/di/user_device.providers.dart';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/di/auth.providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth.repository.dart';

class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    final user = _repository.currentUser;
    ref
        .read(userDeviceControllerProvider.notifier)
        .listenToTokenRefresh(() => _repository.currentUserId ?? '');

    _repository.authStateChanges.listen(_handleAuthStateChange);

    return user;
  }

  void _handleAuthStateChange(AuthState event) {
    switch (event.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
        final userId = event.session?.user.id ?? _repository.currentUserId;
        if (userId != null && userId.isNotEmpty) {
          ref
              .read(userDeviceControllerProvider.notifier)
              .syncCurrentDevice(userId: userId);
        }
        break;
      default:
        break;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => asyncHandler(() async {
        final response = await _repository.signInWithPassword(
          email: email,
          password: password,
        );
        return response.user;
      }),
    );

    return !state.hasError && state.value != null;
  }

  Future<bool> signOut() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => asyncHandler(() async {
        try {
          await ref
              .read(userDeviceControllerProvider.notifier)
              .clearCurrentDevice();
        } catch (e) {
          AppLogger.w(
            'Failed to deactivate device on sign out: $e',
            tag: 'AuthController',
          );
        }
        await _repository.signOut();
        return null;
      }),
    );

    return !state.hasError;
  }

  Future<bool> changePassword(String newPassword) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => asyncHandler(() async {
        final response = await _repository.updateUser(password: newPassword);
        return response.user;
      }),
    );

    return !state.hasError;
  }
}
