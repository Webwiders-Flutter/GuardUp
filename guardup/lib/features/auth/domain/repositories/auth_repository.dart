import 'dart:async';

import '../../data/enum/oauth_provider.enum.dart';
import '../../data/enum/otp_type.enum.dart';

export '../../data/enum/oauth_provider.enum.dart';
export '../../data/enum/otp_type.enum.dart';

/// Abstract contract for Authentication operations.
///
/// Belongs to the Domain layer: independent of any specific backend (Supabase, Firebase, REST).
abstract class AuthRepository {
  /// Stream that emits the current user ID or null when auth state changes
  /// (e.g., on sign in, sign out, token refresh).
  Stream<String?> get authStateChanges;

  /// Returns the currently authenticated user's ID, or null if unauthenticated.
  String? get currentUserId;

  /// Whether a user is currently logged in.
  bool get isAuthenticated => currentUserId != null;

  /// Signs up a new user using email and password.
  /// Returns the newly created user ID.
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  });

  /// Signs in an existing user using email and password.
  /// Returns the authenticated user ID.
  Future<String> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs up or starts the sign-in flow using a phone number.
  Future<void> signUpWithPhone({
    required String phoneNumber,
    String? password,
    Map<String, dynamic>? metadata,
  });

  /// Initiates sign in with phone (sends SMS OTP).
  Future<void> signInWithPhone({required String phoneNumber});

  /// Verifies an OTP code for phone, email, or recovery flows.
  /// Returns the authenticated user ID.
  Future<String> verifyOtp({
    required String target,
    required String token,
    required OtpType type,
  });

  /// Resends an OTP to the given target (phone or email).
  Future<void> resendOtp({required String target, required OtpType type});

  /// Signs in or signs up via third-party OAuth provider (Google, Apple, etc.).
  /// Returns the authenticated user ID.
  Future<String> signInWithOAuth({
    required OAuthProvider provider,
    List<String>? scopes,
    Map<String, String>? queryParams,
  });

  /// Signs in passwordlessly via email magic link.
  Future<void> signInWithMagicLink({required String email});

  /// Signs in anonymously / as a guest.
  /// Returns the temporary guest user ID.
  Future<String> signInAnonymously();

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail({required String email});

  /// Updates the current user's password.
  Future<void> changePassword({
    required String newPassword,
    String? oldPassword,
  });

  /// Updates auth user credentials (email, password, or user metadata).
  Future<void> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? metadata,
  });

  /// Refreshes the active authentication token or session.
  Future<void> refreshSession();

  /// Signs out the current user and clears session tokens.
  Future<void> signOut();

  /// Permanently deletes the current user's authentication account.
  Future<void> deleteAccount();
}
