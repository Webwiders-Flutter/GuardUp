import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/supabase_logger.dart';
import '/core/state/api_state.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository? _authRepo;
  final UserRepository? _userRepo;

  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<dynamic>? _profileSubscription;

  AuthBloc({AuthRepository? authRepository, UserRepository? userRepository})
    : _authRepo = authRepository,
      _userRepo = userRepository,
      super(const AuthState.unknown()) {
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

    _init();
  }

  void _init() {
    if (_authRepo == null) {
      add(const AuthCheckStatusRequested());
      return;
    }

    _setupStreamListeners();
    add(const AuthCheckStatusRequested());
  }

  void _setupStreamListeners() {
    _authSubscription?.cancel();
    _authSubscription = _authRepo?.authStateChanges.listen(
      (userId) {
        add(AuthUserChanged(userId));
      },
      onError: (Object error) {
        SupabaseLogger.warning(
          'Auth state changes stream error: $error',
          operation: 'authStateChanges',
        );
      },
    );
  }

  void _listenToProfile(String userId) {
    if (_userRepo == null) return;
    _profileSubscription?.cancel();
    _profileSubscription = _userRepo
        .watchUserData(userId)
        .listen(
          (data) {
            if (data == null) {
              add(const AuthProfileChanged(null));
              return;
            }
            final profile = UserModel.fromJson(data);
            final status =
                UserStatus.tryFromApiValue(data['status'] as String?);
            add(AuthProfileChanged(
              profile,
              status: status,
              email: data['email'] as String?,
              userData: data,
            ));
          },
          onError: (Object error) {
            SupabaseLogger.warning(
              'Realtime profile subscription error for userId=$userId: $error',
              operation: 'watchUserData',
            );
          },
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

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    final currentUid = authRepo.currentUserId;
    if (currentUid != null) {
      try {
        _listenToProfile(currentUid);

        Map<String, dynamic>? userData;
        if (_userRepo != null) {
          userData = await _userRepo.getUserData(currentUid);
        }

        if (userData != null) {
          final profile = UserModel.fromJson(userData);
          final status =
              UserStatus.tryFromApiValue(userData['status'] as String?);
          final email = userData['email'] as String?;
          final phoneCode = userData['phone_code'] as String?;
          final phone = userData['phone_number'] as String?;

          emit(
            AuthState.authenticated(
              profile,
              status: status,
              email: email,
              phoneCode: phoneCode,
              phoneNumber: phone,
              userData: userData,
            ),
          );
        } else {
          // Profile record not found or still being created
          emit(const AuthState.unauthenticated());
        }
      } catch (e, st) {
        SupabaseLogger.error('AuthBloc._onCheckStatusRequested', e, st);
        emit(
          AuthState.unauthenticated(
            operationState: ApiState.failure(e.toString()),
          ),
        );
      }
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  void _onSetSessionRoleRequested(
    AuthSetSessionRoleRequested event,
    Emitter<AuthState> emit,
  ) {
    final currentUser = state.user ?? const UserModel(id: '', name: '');
    final updatedUser = currentUser.copyWith(role: event.role);

    emit(state.copyWith(operationState: ApiState.success(updatedUser)));
  }

  Future<void> _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.userId == null) {
      _profileSubscription?.cancel();
      _profileSubscription = null;
      emit(const AuthState.unauthenticated());
    } else {
      _listenToProfile(event.userId!);
      Map<String, dynamic>? userData;
      if (_userRepo != null) {
        userData = await _userRepo.getUserData(event.userId!);
      }
      if (userData != null) {
        final profile = UserModel.fromJson(userData);
        final status =
            UserStatus.tryFromApiValue(userData['status'] as String?);
        emit(
          AuthState.authenticated(
            profile,
            status: status,
            email: userData['email'] as String?,
            phoneCode: userData['phone_code'] as String?,
            phoneNumber: userData['phone_number'] as String?,
            userData: userData,
          ),
        );
      }
    }
  }

  Future<void> _onProfileChanged(
    AuthProfileChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.profile != null) {
      final user = event.profile!;
      final newStatus = event.status ?? state.status;

      // Realtime Admin Action: If admin blocked the user
      if (newStatus == UserStatus.blocked) {
        emit(
          state.copyWith(
            sessionStatus: AuthSessionStatus.authenticated,
            status: UserStatus.blocked,
            operationState: ApiState.success(user),
            userData: event.userData ?? state.userData,
          ),
        );
        return;
      }

      // Realtime Admin Action: If admin deleted the user
      if (newStatus == UserStatus.deleted) {
        add(const AuthSignOutRequested());
        return;
      }

      // Realtime Admin Action: Approved / Active / Pending Approval
      emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.authenticated,
          status: newStatus,
          email: event.email ?? state.email,
          operationState: ApiState.success(user),
          userData: event.userData ?? state.userData,
        ),
      );
    } else {
      emit(const AuthState.unauthenticated());
    }
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
        final userData = await _userRepo.getUserData(userId);
        if (userData != null) {
          final status =
              UserStatus.tryFromApiValue(userData['status'] as String?);

          // If account is deleted: sign out immediately and show error (do not show deleted screen)
          if (status == UserStatus.deleted) {
            await authRepo.signOut();
            emit(
              state.copyWith(
                sessionStatus: AuthSessionStatus.unauthenticated,
                status: UserStatus.deleted,
                operationState: const ApiState.failure(
                  'This account has been deleted. Please register or contact support.',
                ),
              ),
            );
            return;
          }

          final profile = UserModel.fromJson(userData);
          final email = userData['email'] as String?;
          final phoneCode = userData['phone_code'] as String?;
          final phone = userData['phone_number'] as String?;

          emit(
            AuthState.authenticated(
              profile,
              status: status,
              email: email,
              phoneCode: phoneCode,
              phoneNumber: phone,
            ),
          );
          _listenToProfile(userId);
          return;
        }
      }
      emit(AuthState.authenticated(UserModel(id: userId, name: 'User')));
      _listenToProfile(userId);
    } catch (e, st) {
      SupabaseLogger.error('AuthBloc._onLoginRequested', e, st);
      String cleanMessage = 'Login failed. Please check your credentials.';
      final errStr = e.toString().toLowerCase();

      final isEmailUnconfirmed = errStr.contains('confirm') ||
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
        // Note: public.users is automatically populated by PostgreSQL trigger handle_new_user()
        emit(
          state.copyWith(
            sessionStatus: AuthSessionStatus.unauthenticated,
            status: UserStatus.incomplete,
            email: event.email,
            phoneCode: event.phoneCode,
            phoneNumber: event.phone,
            operationState: ApiState.success(newUser),
          ),
        );
      } catch (e) {
        emit(state.copyWith(operationState: ApiState.failure(e.toString())));
      }
    } else {
      // Development mock fallback
      final mockUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: event.name ?? 'New User',
        role: event.role,
      );
      emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.unauthenticated,
          status: UserStatus.incomplete,
          email: event.email,
          phoneCode: event.phoneCode,
          phoneNumber: event.phone,
          operationState: ApiState.success(mockUser),
        ),
      );
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

        // Fetch user profile from DB to get real role and server-assigned data
        UserModel? profile;
        UserStatus? dbStatus;
        if (_userRepo != null) {
          try {
            final raw = await _userRepo.getUserData(uid);
            if (raw != null) {
              profile = UserModel.fromJson(raw);
              dbStatus = UserStatus.tryFromApiValue(raw['status'] as String?);
            }
          } catch (_) {}
        }

        // Realtime: Listen immediately to changes in public.users (admin approve/block/delete)
        _listenToProfile(uid);

        final currentUser = profile ??
            state.user ??
            UserModel(id: uid, name: 'User', role: role);

        final finalStatus = event.type == OtpType.recovery
            ? (dbStatus ?? state.status)
            : (dbStatus ?? targetStatus);

        emit(
          state.copyWith(
            sessionStatus: AuthSessionStatus.authenticated,
            status: finalStatus,
            email: event.email,
            operationState: ApiState.success(currentUser),
          ),
        );
      } catch (e) {
        SupabaseLogger.warning('OTP verification failed: $e', operation: 'verifyOtp');

        String cleanMessage = 'Verification failed. Please try again.';
        final errStr = e.toString().toLowerCase();

        if (errStr.contains('expired')) {
          cleanMessage = 'The verification code has expired. Please request a new code.';
        } else if (errStr.contains('invalid') ||
            errStr.contains('403') ||
            errStr.contains('400') ||
            errStr.contains('otp_expired')) {
          cleanMessage = 'Invalid verification code. Please check your 6-digit code and try again.';
        } else if (errStr.contains('network') ||
            errStr.contains('socket') ||
            errStr.contains('timeout')) {
          cleanMessage = 'Network connection issue. Please check your internet and try again.';
        }

        emit(state.copyWith(operationState: ApiState.failure(cleanMessage)));
      }
    } else {
      // Development mock fallback: verification succeeds
      final currentUser =
          state.user ??
          UserModel(
            id: 'mock_${role.name}_user',
            name: role == UserRole.company
                ? 'Apex Security'
                : role == UserRole.guard
                    ? 'Vikram Singh'
                    : 'Alex Morgan',
            role: role,
          );
      emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.authenticated,
          status: targetStatus,
          operationState: ApiState.success(currentUser),
        ),
      );
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
            operationState: const ApiState.success(UserModel(id: '', name: '')),
          ),
        );
      } catch (e, st) {
        SupabaseLogger.error('AuthBloc._onSendPasswordResetRequested', e, st);
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
    } else {
      emit(
        state.copyWith(
          email: event.email,
          operationState:
              const ApiState.success(UserModel(id: 'mock', name: 'Mock')),
        ),
      );
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

        emit(
          const AuthState.unauthenticated(
            operationState: ApiState.success(UserModel(id: '', name: '')),
          ),
        );
      } catch (e, st) {
        SupabaseLogger.error('AuthBloc._onResetPasswordRequested', e, st);
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
    } else {
      emit(
        const AuthState.unauthenticated(
          operationState:
              ApiState.success(UserModel(id: 'mock', name: 'Mock')),
        ),
      );
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
    _profileSubscription?.cancel();
    _profileSubscription = null;
    emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    return super.close();
  }
}
