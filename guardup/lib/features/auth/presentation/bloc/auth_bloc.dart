import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/constants/enums/app_enums.dart';
import 'package:guardup/core/services/injection_container.dart';
import 'package:guardup/core/services/push_notification_service.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/features/auth/domain/entities/user_entity.dart';
import 'package:guardup/features/auth/domain/repositories/auth_repository.dart';
import 'package:guardup/features/auth/domain/usecases/login_usecase.dart';
import 'package:guardup/features/auth/domain/usecases/signup_usecase.dart';
import 'package:guardup/features/profile/domain/usecases/get_profile_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;

  StreamSubscription<AuthStatus>? _authStatusSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required LoginUseCase loginUseCase,
    required SignUpUseCase signUpUseCase,
  }) : _authRepository = authRepository,
       _loginUseCase = loginUseCase,
       _signUpUseCase = signUpUseCase,
       super(const AuthInitialState()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthDeleteAccountRequested>(_onAuthDeleteAccountRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthUpdatePasswordRequested>(_onAuthUpdatePasswordRequested);
    on<AuthUpdateEmailRequested>(_onAuthUpdateEmailRequested);
    on<AuthVerifyEmailUpdateRequested>(_onAuthVerifyEmailUpdateRequested);
    on<AuthUpdatePhoneRequested>(_onAuthUpdatePhoneRequested);
    on<AuthVerifyPhoneUpdateRequested>(_onAuthVerifyPhoneUpdateRequested);
    on<AuthVerifySignupPhoneRequested>(_onAuthVerifySignupPhoneRequested);
    on<AuthVerifySignupEmailRequested>(_onAuthVerifySignupEmailRequested);
    on<AuthVerifyPasswordRecoveryOtpRequested>(
      _onAuthVerifyPasswordRecoveryOtpRequested,
    );
    on<AuthResendSignupEmailRequested>(_onAuthResendSignupEmailRequested);
    on<AuthRefreshEvent>(_onAuthRefreshEvent);

    _authStatusSubscription = _authRepository.status.listen((status) {
      if (status == AuthStatus.passwordRecovery) {
        add(AuthStatusChanged(status));
      }
    });

    _initializeSplashDelay();
  }

  void _initializeSplashDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (isClosed) return;

    if (state is AuthPasswordRecoveryState) return;

    add(AuthStatusChanged(_authRepository.currentStatus));

    _authStatusSubscription?.cancel();
    _authStatusSubscription = _authRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(const UnAuthenticatedState());
      case AuthStatus.authenticated:
        final user = _authRepository.currentUser;

        // Re-initialize push notifications so the token is saved for the newly authenticated user
        try {
          sl<PushNotificationService>().init();
        } catch (_) {}

        if (user != null) {
          final profileResult = await sl<GetProfileUseCase>().call(user.id);
          profileResult.fold(
            (failure) => emit(
              AuthenticatedState(user, DateTime.now().millisecondsSinceEpoch),
            ),
            (fullProfile) => emit(
              AuthenticatedState(
                fullProfile,
                DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        } else {
          emit(const UnAuthenticatedState());
        }
        return;
      case AuthStatus.passwordRecovery:
        return emit(const AuthPasswordRecoveryState());
      case AuthStatus.unknown:
        return emit(const AuthInitialState());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    await result.fold(
      (failure) async {
        if (failure.message.contains('Email not confirmed')) {
          emit(const AuthEmailNotConfirmedState());
        } else {
          emit(AuthErrorState(failure.message));
        }
      },
      (_) async {
        final user = _authRepository.currentUser;
        if (user != null) {
          final profileResult = await sl<GetProfileUseCase>().call(user.id);
          profileResult.fold(
            (failure) => emit(
              AuthenticatedState(user, DateTime.now().millisecondsSinceEpoch),
            ),
            (fullProfile) => emit(
              AuthenticatedState(
                fullProfile,
                DateTime.now().millisecondsSinceEpoch,
              ),
            ),
          );
        } else {
          emit(const UnAuthenticatedState());
        }
      },
    );
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    final result = await _signUpUseCase(
      email: event.email,
      password: event.password,
      name: event.name,
      phone: event.phone,
      phoneCode: event.phoneCode,
      countryCode: event.countryCode,
    );
    await result.fold(
      (failure) async {
        emit(AuthErrorState(failure.message));
      },
      (_) async {
        // Now that email confirmation is required, we do not have a session yet.
        // We will verify the phone on first login.
        emit(const AuthEmailNotConfirmedState());
      },
    );
  }

  Future<void> _onAuthVerifySignupPhoneRequested(
    AuthVerifySignupPhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.verifyPhoneUpdate(
        phone: event.phone,
        token: event.token,
        phoneCode: event.phoneCode,
        countryCode: event.countryCode,
      );
      emit(const AuthVerifySignupPhoneSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
    } catch (e, stackTrace) {
      AppLogs.error(
        'Error during logout request',
        error: e,
        stackTrace: stackTrace,
      );
      emit(AuthErrorState(e.toString()));
    }
  }

  // Future<void> _onAuthDeleteAccountRequested(
  //   AuthDeleteAccountRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   // emit(const A());
  //   try {
  //     await _authRepository.deleteAccount(password: event.password);
  //     emit(const AuthDeleteAccountSuccessState());
  //   } catch (e) {
  //     emit(AuthErrorState(e.toString()));
  //   }
  // }

  Future<void> _onAuthDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;

    if (user == null) {
      emit(const UnAuthenticatedState());
      return;
    }

    emit(AuthDeleteAccountLoadingState(user));

    try {
      await _authRepository.deleteAccount(password: event.password);

      emit(const AuthDeleteAccountSuccessState());
    } catch (e) {
      emit(AuthDeleteAccountErrorState(user: user, message: e.toString()));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.resetPassword(email: event.email);
      // Wait for deep link to trigger passwordRecovery status, or go back to login.
      emit(const AuthForgotPasswordSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthUpdatePasswordRequested(
    AuthUpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.updatePassword(
        newPassword: event.newPassword,
        oldPassword: event.oldPassword,
      );
      emit(const AuthUpdatePasswordSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthUpdateEmailRequested(
    AuthUpdateEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final isRegistered = await _authRepository.isEmailRegistered(
        event.newEmail,
      );
      if (isRegistered) {
        emit(const AuthErrorState('Email address is already registered.'));
        return;
      }

      await _authRepository.updateEmail(newEmail: event.newEmail);
      emit(
        AuthUpdateEmailOtpSentState(event.newEmail, isResend: event.isResend),
      );
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthVerifyEmailUpdateRequested(
    AuthVerifyEmailUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.verifyEmailUpdate(
        email: event.email,
        token: event.token,
      );
      emit(const AuthUpdateEmailSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthUpdatePhoneRequested(
    AuthUpdatePhoneRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      final isRegistered = await _authRepository.isPhoneRegistered(
        event.newPhone,
      );
      if (isRegistered) {
        emit(const AuthErrorState('Phone number is already registered.'));
        return;
      }

      await _authRepository.updatePhone(
        newPhone: event.newPhone,
        phoneCode: event.phoneCode,
        countryCode: event.countryCode,
      );
      emit(
        AuthUpdatePhoneOtpSentState(
          event.newPhone,
          event.phoneCode,
          event.countryCode,
        ),
      );
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthVerifyPhoneUpdateRequested(
    AuthVerifyPhoneUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.verifyPhoneUpdate(
        phone: event.phone,
        token: event.token,
        phoneCode: event.phoneCode,
        countryCode: event.countryCode,
      );
      emit(const AuthUpdatePhoneSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthRefreshEvent(
    AuthRefreshEvent event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      final profileResult = await sl<GetProfileUseCase>().call(user.id);
      profileResult.fold(
        (failure) => emit(
          AuthenticatedState(user, DateTime.now().millisecondsSinceEpoch),
        ),
        (fullProfile) => emit(
          AuthenticatedState(
            fullProfile,
            DateTime.now().millisecondsSinceEpoch,
          ),
        ),
      );
    }
  }

  Future<void> _onAuthVerifySignupEmailRequested(
    AuthVerifySignupEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.verifySignupEmail(
        email: event.email,
        token: event.token,
      );
      emit(const AuthVerifySignupEmailSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthVerifyPasswordRecoveryOtpRequested(
    AuthVerifyPasswordRecoveryOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.verifyPasswordRecoveryOtp(
        email: event.email,
        token: event.token,
      );
      emit(const AuthVerifyPasswordRecoveryOtpSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  Future<void> _onAuthResendSignupEmailRequested(
    AuthResendSignupEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoadingState());
    try {
      await _authRepository.resendSignupEmail(email: event.email);
      emit(const AuthResendSignupEmailSuccessState());
    } catch (e) {
      emit(AuthErrorState(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStatusSubscription?.cancel();
    return super.close();
  }
}
