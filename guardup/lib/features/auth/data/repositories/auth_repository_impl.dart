import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:guardup/core/constants/enums/app_enums.dart';
import 'package:guardup/core/constants/env_config.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/data/providers/local/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class _AuthException implements Exception {
  final String message;
  _AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepositoryImpl implements AuthRepository {
  // ignore: unused_field
  final StorageService _storageService;
  final SupabaseClient _supabaseClient;
  final _controller = StreamController<AuthStatus>.broadcast();
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isPasswordRecovery = false;

  AuthRepositoryImpl(this._storageService, this._supabaseClient) {
    _authStateSubscription = _supabaseClient.auth.onAuthStateChange.listen((
      data,
    ) {
      final session = data.session;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _controller.add(AuthStatus.passwordRecovery);
      } else if (session != null) {
        _isPasswordRecovery = false;
        _controller.add(AuthStatus.authenticated);
      } else {
        _isPasswordRecovery = false;
        _controller.add(AuthStatus.unauthenticated);
      }
    });
  }

  @override
  AuthStatus get currentStatus {
    if (_isPasswordRecovery) {
      return AuthStatus.passwordRecovery;
    }
    return _supabaseClient.auth.currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
  }

  @override
  Stream<AuthStatus> get status => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error('Failed to sign in', error: e, stackTrace: stackTrace);
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error during sign in',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    final currentUser = _supabaseClient.auth.currentUser;
    try {
      final res = await _supabaseClient.rpc(
        'check_user_identifier_exists',
        params: {
          'check_email': email,
          if (currentUser != null) 'exclude_user_id': currentUser.id,
        },
      );
      if (res != null) return res as bool;
    } catch (_) {
      // Fallback to direct query if RPC is unavailable
    }

    var query = _supabaseClient.from('users').select('id').eq('email', email);
    if (currentUser != null) {
      query = query.neq('id', currentUser.id);
    }
    final existingEmail = await query.maybeSingle();
    return existingEmail != null;
  }

  @override
  Future<bool> isPhoneRegistered(String phone) async {
    final currentUser = _supabaseClient.auth.currentUser;
    try {
      final res = await _supabaseClient.rpc(
        'check_user_identifier_exists',
        params: {
          'check_phone': phone,
          if (currentUser != null) 'exclude_user_id': currentUser.id,
        },
      );
      if (res != null) return res as bool;
    } catch (_) {
      // Fallback to direct query if RPC is unavailable
    }

    var query = _supabaseClient.from('users').select('id').eq('phone', phone);
    if (currentUser != null) {
      query = query.neq('id', currentUser.id);
    }
    final existingPhone = await query.maybeSingle();
    return existingPhone != null;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String phoneCode,
    required String countryCode,
  }) async {
    try {
      // Check if phone number is already registered
      if (await isPhoneRegistered(phone)) {
        throw _AuthException('Phone number is already registered.');
      }

      // Check if email is already registered
      if (await isEmailRegistered(email)) {
        throw _AuthException('Email address is already registered.');
      }

      await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: '${EnvConfig.authCallbackUrl}?type=signup',
        data: {
          'name': name,
          'phone': phone,
          'phone_code': phoneCode,
          'country_code': countryCode,
          'password': password,
        },
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error('Failed to sign up', error: e, stackTrace: stackTrace);
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error during sign up',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        try {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await removeDeviceToken(token);
          }
        } catch (tokenErr, stackTrace) {
          AppLogs.error(
            'Failed to retrieve and remove device token on sign out',
            error: tokenErr,
            stackTrace: stackTrace,
          );
        }
      }

      await _supabaseClient.auth.signOut();
    } on AuthException catch (e, stackTrace) {
      AppLogs.error('Failed to sign out', error: e, stackTrace: stackTrace);
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error during sign out',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: '${EnvConfig.authCallbackUrl}?type=recovery',
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error(
        'Failed to reset password',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error during password reset',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    try {
      if (oldPassword != null) {
        final email = _supabaseClient.auth.currentUser?.email;
        if (email != null) {
          // Re-authenticate to verify old password
          try {
            await _supabaseClient.auth.signInWithPassword(
              email: email,
              password: oldPassword,
            );
          } on AuthException {
            throw _AuthException('Incorrect old password.');
          }
        }
      }

      await _supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error(
        'Failed to update password',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error during password update',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _supabaseClient.auth.updateUser(UserAttributes(email: newEmail));
    } on AuthException catch (e) {
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> verifyEmailUpdate({
    required String email,
    required String token,
  }) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.emailChange,
      );

      // Once verified, sync the email in the public.users table
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        await _supabaseClient
            .from('users')
            .update({'email': email})
            .eq('id', userId);
      }
    } on AuthException catch (e) {
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> updatePhone({
    required String newPhone,
    required String phoneCode,
    required String countryCode,
  }) async {
    try {
      final formattedPhone = '+$phoneCode$newPhone';
      // Supabase updateUser with phone triggers an SMS OTP
      await _supabaseClient.auth.updateUser(
        UserAttributes(
          phone: formattedPhone,
          data: {
            'phone': newPhone,
            'phone_code': phoneCode,
            'country_code': countryCode,
          },
        ),
      );
    } on AuthException catch (e) {
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> verifyPhoneUpdate({
    required String phone,
    required String token,
    required String phoneCode,
    required String countryCode,
  }) async {
    try {
      final formattedPhone = '+$phoneCode$phone';
      await _supabaseClient.auth.verifyOTP(
        phone: formattedPhone,
        token: token,
        type: OtpType.phoneChange,
      );

      // Once verified, sync the phone details in the public.users table
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId != null) {
        await _supabaseClient
            .from('users')
            .update({
              'phone': phone,
              'phone_code': phoneCode,
              'country_code': countryCode,
            })
            .eq('id', userId);
      }
    } on AuthException catch (e) {
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    try {
      final email = _supabaseClient.auth.currentUser?.email;
      if (email != null) {
        // Re-authenticate to verify identity before deletion
        try {
          await _supabaseClient.auth.signInWithPassword(
            email: email,
            password: password,
          );
          await _supabaseClient.rpc('delete_user');
          await signOut();
        } on AuthException {
          throw _AuthException('Incorrect password.');
        }
      }
    } catch (e, stackTrace) {
      if (e is _AuthException) rethrow;
      AppLogs.error(
        'Failed to delete account',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException('Could not delete account. Please try again later.');
    }
  }

  @override
  UserEntity? get currentUser {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) return null;

    final metadata = user.userMetadata ?? {};
    return UserEntity(
      id: user.id,
      email: user.email ?? '',
      name: metadata['name'] as String?,
      profileImage: metadata['profileImage'] as String?,
      phone: metadata['phone'] as String?,
      phoneCode: metadata['phone_code'] as String?,
      countryCode: metadata['country_code'] as String?,
      isPhoneVerified: user.phone != null && user.phone!.isNotEmpty,
      createdAt: user.createdAt,
    );
  }

  @override
  Future<void> saveDeviceToken(String token) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        // Fetch current tokens
        final userResp = await _supabaseClient
            .from('users')
            .select('device_tokens')
            .eq('id', user.id)
            .maybeSingle();

        List<dynamic> currentTokens = [];
        if (userResp != null && userResp['device_tokens'] != null) {
          currentTokens = List.from(userResp['device_tokens']);
        }

        // Add the new token if it doesn't exist
        if (!currentTokens.contains(token)) {
          currentTokens.add(token);
          await _supabaseClient
              .from('users')
              .update({'device_tokens': currentTokens})
              .eq('id', user.id);
          AppLogs.info("FCM Token saved to users table.");
        }
      }
    } catch (e, stackTrace) {
      AppLogs.error("Error saving FCM token", error: e, stackTrace: stackTrace);
      throw Exception('Failed to save device token');
    }
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user != null) {
        final userResp = await _supabaseClient
            .from('users')
            .select('device_tokens')
            .eq('id', user.id)
            .maybeSingle();

        if (userResp != null && userResp['device_tokens'] != null) {
          final List<dynamic> tokens = List.from(userResp['device_tokens']);
          if (tokens.contains(token)) {
            tokens.remove(token);
            await _supabaseClient
                .from('users')
                .update({'device_tokens': tokens})
                .eq('id', user.id);
            AppLogs.info('Device token successfully removed from users table.');
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogs.error(
        'Error removing device token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> verifySignupEmail({
    required String email,
    required String token,
  }) async {
    try {
      await _supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error(
        'Failed to verify signup email OTP',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String token,
  }) async {
    try {
      _isPasswordRecovery = true;
      await _supabaseClient.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error(
        'Failed to verify password recovery OTP',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException(e.message);
    }
  }

  @override
  Future<void> resendSignupEmail({required String email}) async {
    try {
      await _supabaseClient.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: '${EnvConfig.authCallbackUrl}?type=signup',
      );
    } on AuthException catch (e, stackTrace) {
      AppLogs.error(
        'Failed to resend signup email',
        error: e,
        stackTrace: stackTrace,
      );
      throw _AuthException(e.message);
    } catch (e, stackTrace) {
      AppLogs.error(
        'Unexpected error resending signup email',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _controller.close();
  }
}
