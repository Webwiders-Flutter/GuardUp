import 'dart:async';

import '/core/utils/callback/async_callback.handler.dart';
import '/features/users/data/models/user_model.dart';
import '/features/auth/data/repositories/admin_user.repository.dart';
import '/features/auth/di/auth.providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/logger/app_logger.dart';
import '/features/auth/data/repositories/auth.repository.dart';

class AdminUserController extends AsyncNotifier<UserModel?> {
  AdminUserRepository get _repo => ref.read(adminUserRepositoryProvider);
  AuthRepository get _authRepo => ref.read(authRepositoryProvider);

  @override
  FutureOr<UserModel?> build() async {
    await refreshProfile();
    return state.value;
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    required String mobileNumber,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final data = <String, dynamic>{
          'full_name': fullName,
          'email': email,
          'mobile_number': mobileNumber,
        };

        // Sync email with auth if changed
        final currentAuthEmail = _authRepo.currentUser?.email;
        if (email.isNotEmpty && email != currentAuthEmail) {
          try {
            await _authRepo.updateUser(email: email);
          } catch (e) {
            AppLogger.w('Auth email update notice: $e');
          }
        }

        return await _repo.updateProfile(data);
      }),
    );

    state = result;
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => asyncHandler(() => _repo.getProfile()),
    );
    state = result;
  }
}
