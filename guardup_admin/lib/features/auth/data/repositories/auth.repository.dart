import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._auth);

  final GoTrueClient _auth;

  User? get currentUser => _auth.currentUser;

  Session? get currentSession => _auth.currentSession;

  String? get currentUserId => _auth.currentUser?.id;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) {
    return _auth.signUp(email: email, password: password, data: data);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> resetPassword(String email) {
    return _auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) {
    return _auth.updateUser(
      UserAttributes(email: email, password: password, data: data),
    );
  }

  Future<void> resendSignupConfirmation(String email) {
    return _auth.resend(type: OtpType.signup, email: email);
  }
}
