import 'dart:async';

import 'package:guardup/core/constants/enums/app_enums.dart';

import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Stream of authentication status
  Stream<AuthStatus> get status;

  /// Gets the current authentication status synchronously
  AuthStatus get currentStatus;

  /// Signs in with Email and Password
  Future<void> signIn({required String email, required String password});

  /// Signs up with Email and Password
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String phoneCode,
    required String countryCode,
  });

  /// Checks if an email is already registered
  Future<bool> isEmailRegistered(String email);

  /// Checks if a phone number is already registered
  Future<bool> isPhoneRegistered(String phone);

  /// Signs out the current user
  Future<void> signOut();

  /// Sends a password reset email
  Future<void> resetPassword({required String email});

  /// Updates the user's password (used after password recovery or change password)
  Future<void> updatePassword({
    required String newPassword,
    String? oldPassword,
  });

  /// Updates the user's email
  Future<void> updateEmail({required String newEmail});

  /// Verifies the OTP for email update
  Future<void> verifyEmailUpdate({
    required String email,
    required String token,
  });

  /// Updates the user's phone number
  Future<void> updatePhone({
    required String newPhone,
    required String phoneCode,
    required String countryCode,
  });

  /// Verifies the OTP for phone update
  Future<void> verifyPhoneUpdate({
    required String phone,
    required String token,
    required String phoneCode,
    required String countryCode,
  });

  /// Deletes the current user account
  Future<void> deleteAccount({required String password});

  /// Gets the current authenticated user
  UserEntity? get currentUser;

  /// Saves the FCM device token for the current user
  Future<void> saveDeviceToken(String token);

  /// Removes the FCM device token for the current user
  Future<void> removeDeviceToken(String token);

  /// Verifies the OTP for email signup
  Future<void> verifySignupEmail({
    required String email,
    required String token,
  });

  /// Verifies the OTP for password recovery
  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String token,
  });

  /// Resends the signup confirmation email
  Future<void> resendSignupEmail({required String email});
}
