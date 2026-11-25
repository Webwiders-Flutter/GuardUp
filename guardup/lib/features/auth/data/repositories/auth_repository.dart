import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/logger/app_logger.dart';
import '../../domain/repositories/auth_repository.dart';

/// Concrete Supabase implementation of [AuthRepository] with full logging.
class SupabaseAuthRepository implements AuthRepository {
  final supa.SupabaseClient? client;

  SupabaseAuthRepository({this.client});

  supa.SupabaseClient get _supabase {
    return client ?? supa.Supabase.instance.client;
  }

  static const String _tag = 'AuthRepository';

  @override
  Stream<String?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      AppLogger.d(
        'Auth state changed: event=${data.event}, sessionUser=${data.session?.user.id}',
        tag: _tag,
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
    AppLogger.d('signUpWithEmail: $normalizedEmail', tag: _tag);

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
      AppLogger.d('signUpWithEmail success: userId=${user.id}, email=${user.email}', tag: _tag);
      return user.id;
    } catch (e, st) {
      AppLogger.e('signUpWithEmail error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.d('signInWithEmail: ${email.trim()}', tag: _tag);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed: User response was null.');
      }
      AppLogger.d('signInWithEmail success: userId=${user.id}', tag: _tag);
      return user.id;
    } catch (e, st) {
      AppLogger.e('signInWithEmail error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> signUpWithPhone({
    required String phoneNumber,
    String? password,
    Map<String, dynamic>? metadata,
  }) async {
    AppLogger.d('signUpWithPhone: ${phoneNumber.trim()}', tag: _tag);

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
      AppLogger.d('signUpWithPhone success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('signUpWithPhone error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> signInWithPhone({required String phoneNumber}) async {
    AppLogger.d('signInWithPhone: ${phoneNumber.trim()}', tag: _tag);
    try {
      await _supabase.auth.signInWithOtp(phone: phoneNumber.trim());
      AppLogger.d('signInWithPhone success: SMS OTP sent', tag: _tag);
    } catch (e, st) {
      AppLogger.e('signInWithPhone error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<String> verifyOtp({
    required String target,
    required String token,
    required OtpType type,
  }) async {
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail ? target.trim().toLowerCase() : target.trim();
    AppLogger.d('verifyOtp: target=$normalizedTarget, type=${type.apiValue}', tag: _tag);

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
      AppLogger.d('verifyOtp success: userId=${user.id}', tag: _tag);
      return user.id;
    } catch (e, st) {
      AppLogger.e('verifyOtp error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> resendOtp({required String target, required OtpType type}) async {
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail ? target.trim().toLowerCase() : target.trim();
    AppLogger.d('resendOtp: target=$normalizedTarget, type=${type.apiValue}', tag: _tag);

    if (type == OtpType.recovery && isEmail) {
      try {
        await _supabase.auth.resetPasswordForEmail(normalizedTarget);
        AppLogger.d('resendOtp success: resent recovery code to $normalizedTarget', tag: _tag);
        return;
      } catch (e, st) {
        AppLogger.e('resendOtp error', tag: _tag, error: e, stackTrace: st);
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
      AppLogger.d('resendOtp success: resent code to $normalizedTarget', tag: _tag);
    } catch (e, st) {
      AppLogger.e('resendOtp error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<String> signInWithOAuth({
    required OAuthProvider provider,
    List<String>? scopes,
    Map<String, String>? queryParams,
  }) async {
    AppLogger.d('signInWithOAuth: provider=${provider.name}', tag: _tag);

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
      AppLogger.d('signInWithOAuth success: flow opened', tag: _tag);
      return currentUserId ?? '';
    } catch (e, st) {
      AppLogger.e('signInWithOAuth error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> signInWithMagicLink({required String email}) async {
    AppLogger.d('signInWithMagicLink: ${email.trim()}', tag: _tag);
    try {
      await _supabase.auth.signInWithOtp(email: email.trim());
      AppLogger.d('signInWithMagicLink success: sent', tag: _tag);
    } catch (e, st) {
      AppLogger.e('signInWithMagicLink error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<String> signInAnonymously() async {
    AppLogger.d('signInAnonymously', tag: _tag);
    try {
      final response = await _supabase.auth.signInAnonymously();
      final user = response.user;
      if (user == null) {
        throw Exception('Anonymous sign in failed.');
      }
      AppLogger.d('signInAnonymously success: userId=${user.id}', tag: _tag);
      return user.id;
    } catch (e, st) {
      AppLogger.e('signInAnonymously error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    AppLogger.d('sendPasswordResetEmail: ${email.trim()}', tag: _tag);
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      AppLogger.d('sendPasswordResetEmail success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('sendPasswordResetEmail error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> changePassword({
    required String newPassword,
    String? oldPassword,
  }) async {
    AppLogger.d('changePassword', tag: _tag);
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
      AppLogger.d('changePassword success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('changePassword error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? metadata,
  }) async {
    AppLogger.d('updateUser: email=$email', tag: _tag);
    try {
      await _supabase.auth.updateUser(
        supa.UserAttributes(
          email: email?.trim(),
          password: password,
          data: metadata,
        ),
      );
      AppLogger.d('updateUser success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('updateUser error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> refreshSession() async {
    AppLogger.d('refreshSession', tag: _tag);
    try {
      await _supabase.auth.refreshSession();
      AppLogger.d('refreshSession success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('refreshSession error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    AppLogger.d('signOut: userId=$currentUserId', tag: _tag);
    try {
      await _supabase.auth.signOut();
      AppLogger.d('signOut success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('signOut error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    final uid = currentUserId;
    AppLogger.w('deleteAccount requested for userId=$uid', tag: _tag);
    try {
      if (uid != null) {
        await _supabase.rpc('delete_user', params: {'p_user_id': uid});
      }
      try {
        await signOut();
      } catch (_) {
        // Ignored: session could already be destroyed by delete_user RPC
      }
      AppLogger.d('deleteAccount success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('deleteAccount error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}
