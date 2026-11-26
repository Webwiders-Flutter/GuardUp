import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/enum/user_role.enum.dart';
import '../../data/enum/user_status.enum.dart';
import '../../data/model/user.model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'auth_form_event.dart';
import 'auth_form_state.dart';

export 'auth_form_event.dart';
export 'auth_form_state.dart';

/// Screen-scoped Bloc managing login, sign-up, OTP verification/resend, and
/// forgot/reset password form flows.
class AuthFormBloc extends Bloc<AuthFormEvent, AuthFormState> {
  AuthFormBloc({
    required this.authRepository,
    required this.userRepository,
    this.onAuthenticated,
    this.onPendingSignUp,
  }) : super(const AuthFormState()) {
    on<LoginSubmitted>(_onLoginSubmitted, transformer: droppable());
    on<SignUpSubmitted>(_onSignUpSubmitted, transformer: droppable());
    on<OtpSubmitted>(_onOtpSubmitted, transformer: droppable());
    on<OtpResendRequested>(_onOtpResendRequested, transformer: droppable());
    on<PasswordResetCodeRequested>(
      _onPasswordResetCodeRequested,
      transformer: droppable(),
    );
    on<NewPasswordSubmitted>(
      _onNewPasswordSubmitted,
      transformer: droppable(),
    );
  }

  static const String _tag = 'AuthFormBloc';

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final void Function()? onAuthenticated;
  final void Function(UserRole role, String email)? onPendingSignUp;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    emit(
      state.copyWith(
        status: const ApiState.loading(),
        email: normalizedEmail,
        clearAuthenticatedUser: true,
      ),
    );

    try {
      final userId = await asyncHandler(
        () => authRepository.signInWithEmail(
          email: normalizedEmail,
          password: event.password,
        ),
      );

      final profile = await asyncHandler(() => userRepository.getProfile(userId));
      if (profile != null && profile.status == UserStatus.deleted) {
        await authRepository.signOut();
        emit(
          state.copyWith(
            status: ApiState.failure(
              'Invalid email or password. Please try again.',
              error: ApiException(
                'Invalid email or password. Please try again.',
                type: ApiErrorType.validation,
              ),
            ),
          ),
        );
        return;
      }

      onAuthenticated?.call();
      emit(
        state.copyWith(
          authenticatedUser: profile,
          status: const ApiState.success(AuthFormResult.signedIn),
        ),
      );
    } on ApiException catch (e) {
      final raw = e.raw;
      final isUnconfirmed =
          raw is AuthException && raw.code == 'email_not_confirmed';
      if (isUnconfirmed) {
        try {
          await authRepository.resendOtp(
            target: normalizedEmail,
            type: OtpType.email,
          );
        } catch (_) {}
        emit(
          state.copyWith(
            email: normalizedEmail,
            status: const ApiState.success(AuthFormResult.emailNotConfirmed),
          ),
        );
        return;
      }

      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    emit(
      state.copyWith(
        status: const ApiState.loading(),
        email: normalizedEmail,
      ),
    );

    try {
      final conflictError = await userRepository.checkRegistrationConflict(
        email: normalizedEmail,
        phone: event.phone?.trim(),
        phoneCode: event.phoneCode ?? '+91',
      );
      if (conflictError != null) {
        emit(
          state.copyWith(
            status: ApiState.failure(
              conflictError,
              error: ApiException(
                conflictError,
                type: ApiErrorType.validation,
              ),
            ),
          ),
        );
        return;
      }

      await asyncHandler(
        () => authRepository.signUpWithEmail(
          email: normalizedEmail,
          password: event.password,
          metadata: {
            'role': event.role.apiValue,
            'name': event.name?.trim(),
            'phone': event.phone?.trim(),
            'phone_code': event.phoneCode ?? '+91',
          },
        ),
      );

      onPendingSignUp?.call(event.role, normalizedEmail);
      emit(
        state.copyWith(
          email: normalizedEmail,
          status: const ApiState.success(AuthFormResult.signedUp),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onOtpSubmitted(
    OtpSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: const ApiState.loading(),
        email: event.email,
        clearAuthenticatedUser: true,
      ),
    );

    try {
      final uid = await asyncHandler(
        () => authRepository.verifyOtp(
          target: event.email,
          token: event.token,
          type: event.type,
        ),
      );

      UserModel? profile;
      try {
        profile = await userRepository.getProfile(uid);
      } catch (e, st) {
        AppLogger.w(
          'Profile fetch after OTP verify failed: $e',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
      }

      onAuthenticated?.call();
      emit(
        state.copyWith(
          authenticatedUser: profile,
          status: const ApiState.success(AuthFormResult.otpVerified),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onOtpResendRequested(
    OtpResendRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(state.copyWith(status: const ApiState.loading()));
    try {
      await asyncHandler(
        () => authRepository.resendOtp(target: event.target, type: event.type),
      );
      emit(
        state.copyWith(
          email: event.target,
          status: const ApiState.success(AuthFormResult.otpResent),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onPasswordResetCodeRequested(
    PasswordResetCodeRequested event,
    Emitter<AuthFormState> emit,
  ) async {
    final normalizedEmail = event.email.trim().toLowerCase();
    emit(
      state.copyWith(
        status: const ApiState.loading(),
        email: normalizedEmail,
      ),
    );

    try {
      final checkResult = await userRepository.checkEmailExists(normalizedEmail);
      if (!checkResult.exists) {
        final msg =
            checkResult.errorMessage ??
            event.emailNotFoundFallback ??
            'Email address not found.';
        emit(
          state.copyWith(
            status: ApiState.failure(
              msg,
              error: ApiException(msg, type: ApiErrorType.validation),
            ),
          ),
        );
        return;
      }

      await asyncHandler(
        () => authRepository.sendPasswordResetEmail(email: normalizedEmail),
      );
      emit(
        state.copyWith(
          email: normalizedEmail,
          status: const ApiState.success(AuthFormResult.resetCodeSent),
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }

  Future<void> _onNewPasswordSubmitted(
    NewPasswordSubmitted event,
    Emitter<AuthFormState> emit,
  ) async {
    emit(state.copyWith(status: const ApiState.loading()));

    try {
      await asyncHandler(
        () => authRepository.changePassword(newPassword: event.newPassword),
      );
      try {
        await authRepository.signOut();
      } catch (_) {}

      onAuthenticated?.call();
      emit(state.copyWith(status: const ApiState.success(AuthFormResult.passwordChanged)));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ApiState.failure(e.message, error: e)));
    }
  }
}
