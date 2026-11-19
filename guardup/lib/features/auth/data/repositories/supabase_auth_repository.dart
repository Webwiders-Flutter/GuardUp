import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/logger/supabase_logger.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete Supabase implementation of [AuthRepository] with full logging.
class SupabaseAuthRepository implements AuthRepository {
  final supa.SupabaseClient? client;

  SupabaseAuthRepository({this.client});

  supa.SupabaseClient get _supabase {
    return client ?? supa.Supabase.instance.client;
  }

  @override
  Stream<String?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      SupabaseLogger.info(
        'Auth state changed: event=${data.event}, sessionUser=${data.session?.user.id}',
        operation: 'authStateChanges',
      );
      return data.session?.user.id;
    });
  }

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  bool get isAuthenticated => currentUserId != null;

  @override
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    SupabaseLogger.request('signUpWithEmail', payload: {
      'email': normalizedEmail,
      'password': password,
      'metadata': metadata,
    });

    try {
      final response = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: metadata,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign up failed: User response was null.');
      }
      SupabaseLogger.success('signUpWithEmail', result: 'userId=${user.id}, email=${user.email}');
      return user.id;
    } catch (e, st) {
      SupabaseLogger.error('signUpWithEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    SupabaseLogger.request('signInWithEmail', payload: {
      'email': email.trim(),
      'password': password,
    });

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed: User response was null.');
      }
      SupabaseLogger.success('signInWithEmail', result: 'userId=${user.id}');
      return user.id;
    } catch (e, st) {
      SupabaseLogger.error('signInWithEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signUpWithPhone({
    required String phoneNumber,
    String? password,
    Map<String, dynamic>? metadata,
  }) async {
    SupabaseLogger.request('signUpWithPhone', payload: {
      'phone': phoneNumber.trim(),
      'metadata': metadata,
    });

    try {
      if (password != null && password.isNotEmpty) {
        await _supabase.auth.signUp(
          phone: phoneNumber.trim(),
          password: password,
          data: metadata,
        );
      } else {
        await _supabase.auth.signInWithOtp(
          phone: phoneNumber.trim(),
          data: metadata,
        );
      }
      SupabaseLogger.success('signUpWithPhone', message: 'SMS OTP or signup initiated');
    } catch (e, st) {
      SupabaseLogger.error('signUpWithPhone', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signInWithPhone({required String phoneNumber}) async {
    SupabaseLogger.request('signInWithPhone', details: phoneNumber.trim());
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber.trim());
      SupabaseLogger.success('signInWithPhone', message: 'SMS OTP sent');
    } catch (e, st) {
      SupabaseLogger.error('signInWithPhone', e, st);
      rethrow;
    }
  }

  @override
  Future<String> verifyOtp({
    required String target,
    required String token,
    required OtpType type,
  }) async {
    SupabaseLogger.request('verifyOtp', payload: {
      'target': target,
      'token': token,
      'type': type.apiValue,
    });

    supa.OtpType supaOtpType;
    switch (type) {
      case OtpType.email:
        supaOtpType = supa.OtpType.email;
      case OtpType.sms:
        supaOtpType = supa.OtpType.sms;
      case OtpType.recovery:
        supaOtpType = supa.OtpType.recovery;
      case OtpType.magicLink:
        supaOtpType = supa.OtpType.magiclink;
      case OtpType.emailChange:
        supaOtpType = supa.OtpType.emailChange;
      case OtpType.phoneChange:
        supaOtpType = supa.OtpType.phoneChange;
    }

    final isEmail = target.contains('@');
    final normalizedTarget = isEmail ? target.trim().toLowerCase() : target.trim();
    SupabaseLogger.request(
      'verifyOtp',
      details: 'target=$normalizedTarget, type=${type.apiValue}, tokenLength=${token.trim().length}',
    );

    try {
      supa.AuthResponse response;
      if (isEmail && type == OtpType.email) {
        try {
          response = await _supabase.auth.verifyOTP(
            token: token.trim(),
            type: supa.OtpType.signup,
            email: normalizedTarget,
          );
        } catch (signupErr) {
          try {
            response = await _supabase.auth.verifyOTP(
              token: token.trim(),
              type: supa.OtpType.email,
              email: normalizedTarget,
            );
          } catch (_) {
            throw signupErr;
          }
        }
      } else {
        response = await _supabase.auth.verifyOTP(
          token: token.trim(),
          type: supaOtpType,
          email: isEmail ? normalizedTarget : null,
          phone: !isEmail ? normalizedTarget : null,
        );
      }

      final user = response.user;
      if (user == null) {
        throw Exception('OTP verification failed: User was null.');
      }
      SupabaseLogger.success('verifyOtp', result: 'verified userId=${user.id}');
      return user.id;
    } catch (e, st) {
      SupabaseLogger.error('verifyOtp', e, st);
      rethrow;
    }
  }

  @override
  Future<void> resendOtp({required String target, required OtpType type}) async {
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail ? target.trim().toLowerCase() : target.trim();
    SupabaseLogger.request('resendOtp', details: 'target=$normalizedTarget, type=${type.apiValue}');

    if (type == OtpType.recovery && isEmail) {
      try {
        await _supabase.auth.resetPasswordForEmail(normalizedTarget);
        SupabaseLogger.success('resendOtp', message: 'Resent recovery code to $normalizedTarget');
        return;
      } catch (e, st) {
        SupabaseLogger.error('resendOtp', e, st);
        rethrow;
      }
    }

    supa.OtpType supaOtpType;
    switch (type) {
      case OtpType.email:
      case OtpType.magicLink:
        supaOtpType = supa.OtpType.signup;
      case OtpType.sms:
        supaOtpType = supa.OtpType.sms;
      case OtpType.recovery:
        supaOtpType = supa.OtpType.recovery;
      case OtpType.emailChange:
        supaOtpType = supa.OtpType.emailChange;
      case OtpType.phoneChange:
        supaOtpType = supa.OtpType.phoneChange;
    }

    try {
      await _supabase.auth.resend(
        type: supaOtpType,
        email: isEmail ? normalizedTarget : null,
        phone: !isEmail ? normalizedTarget : null,
      );
      SupabaseLogger.success('resendOtp', message: 'Resent code to $normalizedTarget');
    } catch (e, st) {
      SupabaseLogger.error('resendOtp', e, st);
      rethrow;
    }
  }

  @override
  Future<String> signInWithOAuth({
    required OAuthProvider provider,
    List<String>? scopes,
    Map<String, String>? queryParams,
  }) async {
    SupabaseLogger.request('signInWithOAuth', details: 'provider=${provider.name}');

    supa.OAuthProvider supaProvider;
    switch (provider) {
      case OAuthProvider.google:
        supaProvider = supa.OAuthProvider.google;
      case OAuthProvider.apple:
        supaProvider = supa.OAuthProvider.apple;
      case OAuthProvider.facebook:
        supaProvider = supa.OAuthProvider.facebook;
      case OAuthProvider.github:
        supaProvider = supa.OAuthProvider.github;
      case OAuthProvider.twitter:
        supaProvider = supa.OAuthProvider.twitter;
    }

    try {
      final success = await _supabase.auth.signInWithOAuth(
        supaProvider,
        scopes: scopes?.join(' '),
        queryParams: queryParams,
      );
      if (!success) {
        throw Exception('OAuth sign in initiation failed.');
      }
      SupabaseLogger.success('signInWithOAuth', message: 'OAuth flow opened');
      return currentUserId ?? '';
    } catch (e, st) {
      SupabaseLogger.error('signInWithOAuth', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signInWithMagicLink({required String email}) async {
    SupabaseLogger.request('signInWithMagicLink', details: email.trim());
    try {
      await _supabase.auth.signInWithOtp(email: email.trim());
      SupabaseLogger.success('signInWithMagicLink', message: 'Magic link sent');
    } catch (e, st) {
      SupabaseLogger.error('signInWithMagicLink', e, st);
      rethrow;
    }
  }

  @override
  Future<String> signInAnonymously() async {
    SupabaseLogger.request('signInAnonymously');
    try {
      final response = await _supabase.auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw Exception('Anonymous sign in failed.');
      }
      SupabaseLogger.success('signInAnonymously', result: 'userId=${user.id}');
      return user.id;
    } catch (e, st) {
      SupabaseLogger.error('signInAnonymously', e, st);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    SupabaseLogger.request('sendPasswordResetEmail', details: email.trim());
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      SupabaseLogger.success('sendPasswordResetEmail', message: 'Reset email sent');
    } catch (e, st) {
      SupabaseLogger.error('sendPasswordResetEmail', e, st);
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    SupabaseLogger.request('changePassword');
    try {
      if (oldPassword != null && oldPassword.isNotEmpty) {
        final currentEmail = _supabase.auth.currentUser?.email;
        final currentPhone = _supabase.auth.currentUser?.phone;
        if (currentEmail != null && currentEmail.isNotEmpty) {
          await _supabase.auth.signInWithPassword(
            email: currentEmail,
            password: oldPassword,
          );
        } else if (currentPhone != null && currentPhone.isNotEmpty) {
          await _supabase.auth.signInWithPassword(
            phone: currentPhone,
            password: oldPassword,
          );
        }
      }

      await _supabase.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );
      SupabaseLogger.success('changePassword', message: 'Password updated successfully');
    } catch (e, st) {
      SupabaseLogger.error('changePassword', e, st);
      rethrow;
    }
  }

  @override
  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? metadata,
  }) async {
    SupabaseLogger.request('updateUser', payload: {
      'email': email,
      'metadata': metadata,
    });
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(
          email: email?.trim(),
          password: password,
          data: metadata,
        ),
      );
      SupabaseLogger.success('updateUser', message: 'User updated successfully');
    } catch (e, st) {
      SupabaseLogger.error('updateUser', e, st);
      rethrow;
    }
  }

  @override
  Future<void> refreshSession() async {
    SupabaseLogger.request('refreshSession');
    try {
      await _supabase.auth.refreshSession();
      SupabaseLogger.success('refreshSession', message: 'Session refreshed');
    } catch (e, st) {
      SupabaseLogger.error('refreshSession', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    SupabaseLogger.request('signOut', details: 'userId=$currentUserId');
    try {
      await _supabase.auth.signOut();
      SupabaseLogger.success('signOut', message: 'Signed out successfully');
    } catch (e, st) {
      SupabaseLogger.error('signOut', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    final uid = currentUserId;
    SupabaseLogger.warning('deleteAccount requested for userId=$uid');
    try {
      if (uid != null) {
        await _supabase.rpc('delete_user', params: {'p_user_id': uid});
      }
      try {
        await signOut();
      } catch (_) {
        // Ignored: session could already be destroyed by delete_user RPC
      }
      SupabaseLogger.success('deleteAccount', message: 'Account deleted');
    } catch (e, st) {
      SupabaseLogger.error('deleteAccount', e, st);
      rethrow;
    }
  }
}
