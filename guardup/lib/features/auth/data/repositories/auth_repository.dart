import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '/core/logger/app_logger.dart';
import '../enum/oauth_provider.enum.dart';
import '../enum/otp_type.enum.dart';

export '../enum/oauth_provider.enum.dart';
export '../enum/otp_type.enum.dart';

/// Thin Supabase GoTrue wrapper handling authentication sessions, sign-in/up,
/// OTP verification, password updates, and account deletion.
class AuthRepository {
  final supa.SupabaseClient client;

  AuthRepository({required this.client});

  supa.SupabaseClient get _supabase => client;

  static const String _tag = 'AuthRepository';

  /// Emits the signed-in user's ID or `null` whenever Supabase auth state changes.
  Stream<String?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      AppLogger.d(
        'Auth state changed: event=${data.event}, sessionUser=${data.session?.user.id}',
        tag: _tag,
      );
      return data.session?.user.id;
    });
  }

  /// Currently signed-in user's ID, or `null` if unauthenticated.
  String? get currentUserId => _supabase.auth.currentUser?.id;

  bool get isAuthenticated => currentUserId != null;

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
      AppLogger.d(
        'signUpWithEmail success: userId=${user.id}, email=${user.email}',
        tag: _tag,
      );
      return user.id;
    } catch (e, st) {
      AppLogger.e('signUpWithEmail error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

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

  Future<String> signIn({required String email, required String password}) =>
      signInWithEmail(email: email, password: password);

  Future<String> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) => signUpWithEmail(email: email, password: password, metadata: data);

  Future<void> sendPasswordReset(String email) =>
      sendPasswordResetEmail(email: email);

  Future<void> updatePassword(String newPassword) =>
      changePassword(newPassword: newPassword);

  Future<String> verifyOtp({
    required String target,
    required String token,
    required OtpType type,
  }) async {
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail
        ? target.trim().toLowerCase()
        : target.trim();
    AppLogger.d(
      'verifyOtp: target=$normalizedTarget, type=${type.apiValue}',
      tag: _tag,
    );

    final supaOtpType = switch (type) {
      OtpType.email => supa.OtpType.email,
      OtpType.sms => supa.OtpType.sms,
      OtpType.recovery => supa.OtpType.recovery,
      OtpType.magicLink => supa.OtpType.magiclink,
      OtpType.emailChange => supa.OtpType.emailChange,
      OtpType.phoneChange => supa.OtpType.phoneChange,
    };

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

  Future<void> resendOtp({
    required String target,
    required OtpType type,
  }) async {
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail
        ? target.trim().toLowerCase()
        : target.trim();
    AppLogger.d(
      'resendOtp: target=$normalizedTarget, type=${type.apiValue}',
      tag: _tag,
    );

    if (type == OtpType.recovery && isEmail) {
      try {
        await _supabase.auth.resetPasswordForEmail(normalizedTarget);
        AppLogger.d(
          'resendOtp success: resent recovery code to $normalizedTarget',
          tag: _tag,
        );
        return;
      } catch (e, st) {
        AppLogger.e('resendOtp error', tag: _tag, error: e, stackTrace: st);
        rethrow;
      }
    }

    final supaOtpType = switch (type) {
      OtpType.email || OtpType.magicLink => supa.OtpType.signup,
      OtpType.sms => supa.OtpType.sms,
      OtpType.recovery => supa.OtpType.recovery,
      OtpType.emailChange => supa.OtpType.emailChange,
      OtpType.phoneChange => supa.OtpType.phoneChange,
    };

    try {
      await _supabase.auth.resend(
        type: supaOtpType,
        email: isEmail ? normalizedTarget : null,
        phone: !isEmail ? normalizedTarget : null,
      );
      AppLogger.d(
        'resendOtp success: resent code to $normalizedTarget',
        tag: _tag,
      );
    } catch (e, st) {
      AppLogger.e('resendOtp error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<String> signInWithOAuth({
    required OAuthProvider provider,
    List<String>? scopes,
    Map<String, String>? queryParams,
  }) async {
    AppLogger.d('signInWithOAuth: provider=${provider.name}', tag: _tag);

    final supaProvider = switch (provider) {
      OAuthProvider.google => supa.OAuthProvider.google,
      OAuthProvider.apple => supa.OAuthProvider.apple,
      OAuthProvider.facebook => supa.OAuthProvider.facebook,
      OAuthProvider.github => supa.OAuthProvider.github,
      OAuthProvider.twitter => supa.OAuthProvider.twitter,
    };

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

  Future<void> sendPasswordResetEmail({required String email}) async {
    AppLogger.d('sendPasswordResetEmail: ${email.trim()}', tag: _tag);
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
      AppLogger.d('sendPasswordResetEmail success', tag: _tag);
    } catch (e, st) {
      AppLogger.e(
        'sendPasswordResetEmail error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

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
        // Session may already be revoked by delete_user RPC
      }
      AppLogger.d('deleteAccount success', tag: _tag);
    } catch (e, st) {
      AppLogger.e('deleteAccount error', tag: _tag, error: e, stackTrace: st);
      rethrow;
    }
  }
}
