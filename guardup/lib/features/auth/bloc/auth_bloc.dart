import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// App-wide authentication & session Bloc backed by typed [AuthRepository]
/// session events and [UserRepository.watchProfile] realtime updates.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository? _authRepo;
  final UserRepository? _userRepo;

  static const String _tag = 'AuthBloc';

  AuthBloc({AuthRepository? authRepository, UserRepository? userRepository})
    : _authRepo = authRepository,
      _userRepo = userRepository,
      super(const AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<_AuthUserIdChanged>(_onUserIdChanged, transformer: restartable());
    on<AuthProfileRefreshRequested>(_onProfileRefreshRequested);
    on<AuthRoleSelected>(_onRoleSelected);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileChanged>(_onProfileChanged);
    on<AuthErrorOccurred>(_onErrorOccurred);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthResendOtpRequested>(_onResendOtpRequested);
    on<AuthSendPasswordResetRequested>(_onSendPasswordResetRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUpdateUserStatusRequested>(_onUpdateUserStatusRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
    on<AuthSetSessionRoleRequested>(_onSetSessionRoleRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthReloadRoleDataRequested>(_onReloadRoleDataRequested);
    on<AuthUpdateUserServices>(_onUpdateUserServices);
    on<AuthUpdateUserDocuments>(_onUpdateUserDocuments);

    add(const AuthStarted());
  }

  AuthState _authenticatedState(UserModel profile) {
    final effectiveStatus = profile.role == UserRole.customer
        ? UserStatus.active
        : profile.status;
    return AuthState.authenticated(
      profile,
      status: effectiveStatus,
      email: profile.email,
      phoneCode: profile.phoneCode,
      phoneNumber: profile.phoneNumber,
      userServices: profile.serviceListData ?? const [],
      userDocuments: profile.documents ?? const [],
    );
  }

  Future<AuthState> _mapProfile(UserModel? profile) async {
    if (profile == null) {
      return const AuthState.unauthenticated();
    }
    if (profile.status == UserStatus.deleted) {
      try {
        await _authRepo?.signOut();
      } catch (e) {
        AppLogger.w('Sign out failed for deleted user: $e', tag: _tag);
      }
      return const AuthState.unauthenticated();
    }
    return _authenticatedState(profile);
  }

  Future<void> _onStarted(
    AuthStarted event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    add(_AuthUserIdChanged(authRepo.currentUserId));

    await emit.onEach<String?>(
      authRepo.authStateChanges,
      onData: (userId) => add(_AuthUserIdChanged(userId)),
      onError: (Object error, _) {
        AppLogger.w('Auth state changes stream error: $error', tag: _tag);
      },
    );
  }

  Future<void> _onUserIdChanged(
    _AuthUserIdChanged event,
    Emitter<AuthState> emit,
  ) async {
    final userId = event.userId;
    if (userId == null) {
      if (state.isAuthenticated || state.isUnknown) {
        emit(
          AuthState.unauthenticated(
            pendingRole: state.pendingRole,
            pendingEmail: state.pendingEmail,
          ),
        );
      }
      return;
    }

    final userRepo = _userRepo;
    if (userRepo == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    try {
      final profile = await userRepo.getProfile(userId);
      final initialState = await _mapProfile(profile);
      emit(initialState);

      if (!initialState.isAuthenticated) {
        return;
      }

      await emit.forEach<UserModel?>(
        userRepo.watchProfile(userId),
        onData: (updated) {
          if (updated == null) {
            return const AuthState.unauthenticated();
          }
          if (updated.status == UserStatus.deleted) {
            unawaited(_authRepo?.signOut());
            add(const _AuthUserIdChanged(null));
            return const AuthState.unauthenticated();
          }
          return _authenticatedState(updated);
        },
        onError: (Object error, _) {
          AppLogger.w(
            'Realtime profile subscription error for userId=$userId: $error',
            tag: _tag,
          );
          return state;
        },
      );
    } catch (e, st) {
      AppLogger.e(
        'AuthBloc._onUserIdChanged error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      emit(
        AuthState.unauthenticated(
          operationState: ApiState.failure(e.toString()),
        ),
      );
    }
  }

  Future<void> _onProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final userId = state.user?.id ?? _authRepo?.currentUserId;
    if (userId == null || userId.isEmpty) {
      emit(const AuthState.unauthenticated());
      return;
    }

    try {
      final profile = await _userRepo?.getProfile(userId);
      emit(await _mapProfile(profile));
    } catch (e, st) {
      AppLogger.w(
        'Error refreshing profile for $userId: $e',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  void _onRoleSelected(
    AuthRoleSelected event,
    Emitter<AuthState> emit,
  ) {
    final currentUser = state.user;
    if (currentUser != null) {
      emit(
        state.copyWith(
          pendingRole: event.role,
          operationState: ApiState.success(
            currentUser.copyWith(role: event.role),
          ),
        ),
      );
      return;
    }
    emit(state.copyWith(pendingRole: event.role));
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isUnknown) {
      add(_AuthUserIdChanged(_authRepo?.currentUserId));
      return;
    }
    await _onProfileRefreshRequested(
      const AuthProfileRefreshRequested(),
      emit,
    );
  }

  void _onErrorOccurred(AuthErrorOccurred event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        operationState: ApiState.failure(
          event.message,
          previousData: state.user,
        ),
      ),
    );
  }

  void _onSetSessionRoleRequested(
    AuthSetSessionRoleRequested event,
    Emitter<AuthState> emit,
  ) {
    _onRoleSelected(AuthRoleSelected(event.role), emit);
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    add(_AuthUserIdChanged(event.userId));
  }

  Future<void> _onProfileChanged(
    AuthProfileChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.profile == null) {
      emit(const AuthState.unauthenticated());
      return;
    }
    final status = event.status ?? event.profile!.status;
    if (status == UserStatus.deleted) {
      add(const AuthSignOutRequested());
      return;
    }
    final effectiveStatus = event.profile!.role == UserRole.customer
        ? UserStatus.active
        : status;
    emit(
      state.copyWith(
        sessionStatus: AuthSessionStatus.authenticated,
        status: effectiveStatus,
        email: event.email ?? state.email,
        operationState: ApiState.success(event.profile!),
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(
        state.copyWith(
          operationState: const ApiState.failure(
            'AuthRepository not configured.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        operationState: ApiState.loading(previousData: state.user),
      ),
    );
    try {
      final userId = await authRepo.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      if (_userRepo != null) {
        final profile = await _userRepo.getProfile(userId);
        if (profile != null) {
          if (profile.status == UserStatus.deleted) {
            await authRepo.signOut();
            emit(
              state.copyWith(
                sessionStatus: AuthSessionStatus.unauthenticated,
                status: UserStatus.deleted,
                operationState: const ApiState.failure(
                  'Invalid email or password. Please try again.',
                ),
              ),
            );
            return;
          }

          emit(_authenticatedState(profile));
          add(_AuthUserIdChanged(userId));
          return;
        }
      }
      emit(AuthState.authenticated(UserModel(id: userId, name: 'User')));
      add(_AuthUserIdChanged(userId));
    } catch (e, st) {
      AppLogger.e(
        'AuthBloc._onLoginRequested error',
        tag: _tag,
        error: e,
        stackTrace: st,
      );
      String cleanMessage = 'Login failed. Please check your credentials.';
      final errStr = e.toString().toLowerCase();

      final isEmailUnconfirmed =
          errStr.contains('confirm') ||
          errStr.contains('verif') ||
          errStr.contains('unconfirmed');

      if (errStr.contains('invalid login credentials') ||
          errStr.contains('invalid_credentials')) {
        cleanMessage = 'Invalid email or password. Please try again.';
      } else if (isEmailUnconfirmed) {
        try {
          await authRepo.resendOtp(target: event.email, type: OtpType.email);
        } catch (_) {}
        emit(
          state.copyWith(
            email: event.email,
            pendingEmail: event.email,
            operationState: const ApiState.failure('EMAIL_NOT_CONFIRMED'),
          ),
        );
        return;
      } else if (errStr.contains('network') || errStr.contains('socket')) {
        cleanMessage = 'Network error. Please check your internet connection.';
      }
      emit(state.copyWith(operationState: ApiState.failure(cleanMessage)));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        operationState: ApiState.loading(previousData: state.user),
      ),
    );

    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        final userId = await authRepo.signUpWithEmail(
          email: event.email,
          password: event.password,
          metadata: {
            'role': event.role.apiValue,
            'name': event.name,
            'phone': event.phone,
            'phone_code': event.phoneCode ?? '+91',
          },
        );
        final newUser = UserModel(
          id: userId,
          name: event.name ?? 'New User',
          role: event.role,
        );
        emit(
          state.copyWith(
            sessionStatus: AuthSessionStatus.unauthenticated,
            status: UserStatus.incomplete,
            email: event.email,
            pendingEmail: event.email,
            pendingRole: event.role,
            phoneCode: event.phoneCode,
            phoneNumber: event.phone,
            operationState: ApiState.success(newUser),
          ),
        );
      } catch (e) {
        emit(state.copyWith(operationState: ApiState.failure(e.toString())));
      }
    }
  }

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        operationState: ApiState.loading(previousData: state.user),
      ),
    );

    final authRepo = _authRepo;
    final role = state.sessionRole;
    final UserStatus targetStatus = role == UserRole.customer
        ? UserStatus.active
        : UserStatus.incomplete;

    if (authRepo != null) {
      try {
        final uid = await authRepo.verifyOtp(
          target: event.email,
          token: event.token,
          type: event.type,
        );

        UserModel? profile;
        if (_userRepo != null) {
          try {
            profile = await _userRepo.getProfile(uid);
          } catch (_) {}
        }

        final currentUser =
            profile ??
            state.user ??
            UserModel(id: uid, name: 'User', role: role);

        final dbStatus = profile == null
            ? null
            : (profile.role == UserRole.customer
                  ? UserStatus.active
                  : profile.status);

        final finalStatus = event.type == OtpType.recovery
            ? (dbStatus ?? state.status)
            : (dbStatus ?? targetStatus);

        emit(
          state.copyWith(
            sessionStatus: AuthSessionStatus.authenticated,
            status: finalStatus,
            email: event.email,
            operationState: ApiState.success(currentUser),
            userServices:
                currentUser.serviceListData ?? state.userServices,
            userDocuments: currentUser.documents ?? state.userDocuments,
          ),
        );
        add(_AuthUserIdChanged(uid));
      } catch (e) {
        AppLogger.w('OTP verification failed: $e', tag: _tag);

        String cleanMessage = 'Verification failed. Please try again.';
        final errStr = e.toString().toLowerCase();

        if (errStr.contains('expired')) {
          cleanMessage =
              'The verification code has expired. Please request a new code.';
        } else if (errStr.contains('invalid') ||
            errStr.contains('403') ||
            errStr.contains('400') ||
            errStr.contains('otp_expired')) {
          cleanMessage =
              'Invalid verification code. Please check your 6-digit code and try again.';
        } else if (errStr.contains('network') ||
            errStr.contains('socket') ||
            errStr.contains('timeout')) {
          cleanMessage =
              'Network connection issue. Please check your internet and try again.';
        }

        emit(state.copyWith(operationState: ApiState.failure(cleanMessage)));
      }
    }
  }

  Future<void> _onResendOtpRequested(
    AuthResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        await authRepo.resendOtp(target: event.target, type: event.type);
      } catch (e) {
        emit(state.copyWith(operationState: ApiState.failure(e.toString())));
      }
    }
  }

  Future<void> _onSendPasswordResetRequested(
    AuthSendPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        operationState: ApiState.loading(previousData: state.user),
      ),
    );

    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        await authRepo.sendPasswordResetEmail(email: event.email);
        emit(
          state.copyWith(
            email: event.email,
            pendingEmail: event.email,
            operationState: const ApiState.success(UserModel(id: '', name: '')),
          ),
        );
      } catch (e, st) {
        AppLogger.e(
          'AuthBloc._onSendPasswordResetRequested error',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        String cleanMessage =
            'Failed to send password reset code. Please check your email and try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('rate') || errStr.contains('too many requests')) {
          cleanMessage =
              'Too many requests. Please wait a few moments before trying again.';
        } else if (errStr.contains('network') || errStr.contains('socket')) {
          cleanMessage =
              'Network error. Please check your internet connection.';
        }
        emit(state.copyWith(operationState: ApiState.failure(cleanMessage)));
      }
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      state.copyWith(
        operationState: ApiState.loading(previousData: state.user),
      ),
    );

    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        await authRepo.changePassword(newPassword: event.newPassword);
        try {
          await authRepo.signOut();
        } catch (_) {}

        add(const _AuthUserIdChanged(null));
        emit(
          const AuthState.unauthenticated(
            operationState: ApiState.success(UserModel(id: '', name: '')),
          ),
        );
      } catch (e, st) {
        AppLogger.e(
          'AuthBloc._onResetPasswordRequested error',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        String cleanMessage = 'Failed to reset password. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('same_password')) {
          cleanMessage =
              'New password should be different from your previous password.';
        } else if (errStr.contains('network') || errStr.contains('socket')) {
          cleanMessage =
              'Network error. Please check your internet connection.';
        }
        emit(state.copyWith(operationState: ApiState.failure(cleanMessage)));
      }
    }
  }

  void _onUpdateUserStatusRequested(
    AuthUpdateUserStatusRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(status: event.status));
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null || _userRepo == null) return;

    emit(
      state.copyWith(operationState: ApiState.loading(previousData: current)),
    );
    try {
      final updated = current.copyWith(
        name: event.name ?? current.name,
        profileImageUrl: event.profileImageUrl ?? current.profileImageUrl,
      );
      await _userRepo.updateUserProfile(user: updated);
      emit(state.copyWith(operationState: ApiState.success(updated)));
    } catch (e) {
      emit(
        state.copyWith(
          operationState: ApiState.failure(e.toString(), previousData: current),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo != null) {
      await authRepo.signOut();
    }
    emit(const AuthState.unauthenticated());
    add(const _AuthUserIdChanged(null));
  }

  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(operationState: ApiState.loading(previousData: state.user)));
    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        await authRepo.deleteAccount();
      } catch (e, st) {
        AppLogger.e(
          'AuthBloc._onDeleteAccountRequested error',
          tag: _tag,
          error: e,
          stackTrace: st,
        );
        emit(
          state.copyWith(
            operationState: ApiState.failure(
              'Failed to delete account. Please try again.',
              previousData: state.user,
            ),
          ),
        );
        return;
      }
    }
    emit(const AuthState.unauthenticated());
    add(const _AuthUserIdChanged(null));
  }

  Future<void> _onReloadRoleDataRequested(
    AuthReloadRoleDataRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _onProfileRefreshRequested(
      const AuthProfileRefreshRequested(),
      emit,
    );
  }

  void _onUpdateUserServices(
    AuthUpdateUserServices event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(userServices: event.services));
  }

  void _onUpdateUserDocuments(
    AuthUpdateUserDocuments event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(userDocuments: event.documents));
  }
}

final class _AuthUserIdChanged extends AuthEvent {
  const _AuthUserIdChanged(this.userId);

  final String? userId;

  @override
  List<Object?> get props => [userId];
}
