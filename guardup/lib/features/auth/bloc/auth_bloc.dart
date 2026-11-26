import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState, OtpType;

import '/core/constants/api/database_tables.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/services/data/models/service.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '/core/utils/json_converters/enum.jsonconverter.dart';

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
    on<AuthDeleteAccountRequested>(_onDeleteAccountRequested);
    on<AuthReloadRoleDataRequested>(_onReloadRoleDataRequested);
    on<AuthUpdateUserServices>(_onUpdateUserServices);
    on<AuthUpdateUserDocuments>(_onUpdateUserDocuments);

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
        AppLogger.w('Auth state changes stream error: $error', tag: 'AuthBloc');
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
            final status = UserStatus.values.fromValue(data['status']);
            add(
              AuthProfileChanged(
                profile,
                status: status,
                email: data['email'] as String?,
              ),
            );
          },
          onError: (Object error) {
            AppLogger.w('Realtime profile subscription error for userId=$userId: $error', tag: 'AuthBloc');
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

        UserModel? profile;
        if (_userRepo != null) {
          profile = await _userRepo.getUserProfile(currentUid);
        }

        if (profile != null) {
          final status = profile.status;
          final role = profile.role;

          List<ServiceModel> userServices = profile.serviceListData ?? const [];
          List<UserDocumentModel> userDocuments = profile.documents ?? const [];

          if ((userServices.isEmpty || userDocuments.isEmpty) && (role == UserRole.guard || role == UserRole.company)) {
            try {
              final results = await Future.wait([
                if (userServices.isEmpty) _fetchUserServices(currentUid) else Future.value(userServices),
                if (userDocuments.isEmpty) _fetchUserDocuments(currentUid) else Future.value(userDocuments),
              ]);
              userServices = results[0] as List<ServiceModel>;
              userDocuments = results[1] as List<UserDocumentModel>;
            } catch (e) {
              AppLogger.w('Error preloading role data: $e', tag: 'AuthBloc');
            }
          }

          emit(
            AuthState.authenticated(
              profile,
              status: status,
              email: profile.email,
              phoneCode: profile.phoneCode,
              phoneNumber: profile.phoneNumber,
              userServices: userServices,
              userDocuments: userDocuments,
            ),
          );
        } else {
          // Profile record not found or still being created
          emit(const AuthState.unauthenticated());
        }
      } catch (e, st) {
        AppLogger.e('AuthBloc._onCheckStatusRequested error', tag: 'AuthBloc', error: e, stackTrace: st);
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
      unawaited(_profileSubscription?.cancel());
      _profileSubscription = null;
      emit(const AuthState.unauthenticated());
    } else {
      _listenToProfile(event.userId!);
      UserModel? profile;
      if (_userRepo != null) {
        profile = await _userRepo.getUserProfile(event.userId!);
      }
      if (profile != null) {
        final status = profile.status;
        final role = profile.role;

        List<ServiceModel> userServices = profile.serviceListData ?? const [];
        List<UserDocumentModel> userDocuments = profile.documents ?? const [];

        if ((userServices.isEmpty || userDocuments.isEmpty) && (role == UserRole.guard || role == UserRole.company)) {
          try {
            final results = await Future.wait([
              if (userServices.isEmpty) _fetchUserServices(event.userId!) else Future.value(userServices),
              if (userDocuments.isEmpty) _fetchUserDocuments(event.userId!) else Future.value(userDocuments),
            ]);
            userServices = results[0] as List<ServiceModel>;
            userDocuments = results[1] as List<UserDocumentModel>;
          } catch (e) {
            AppLogger.w('Error preloading role data on user changed: $e', tag: 'AuthBloc');
          }
        }

        emit(
          AuthState.authenticated(
            profile,
            status: status,
            email: profile.email,
            phoneCode: profile.phoneCode,
            phoneNumber: profile.phoneNumber,
            userServices: userServices,
            userDocuments: userDocuments,
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
          ),
        );
        return;
      }

      // Realtime Admin Action: If admin deleted the user
      if (newStatus == UserStatus.deleted) {
        add(const AuthSignOutRequested());
        return;
      }

      // Realtime Admin Action: Approved / Active / Pending Approval / Rejected
      emit(
        state.copyWith(
          sessionStatus: AuthSessionStatus.authenticated,
          status: newStatus,
          email: event.email ?? state.email,
          operationState: ApiState.success(user),
        ),
      );

      // Realtime sync: reload documents and services when status changes to rejected or pending
      if (newStatus == UserStatus.rejected ||
          newStatus == UserStatus.pendingApproval) {
        add(const AuthReloadRoleDataRequested());
      }
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
        final profile = await _userRepo.getUserProfile(userId);
        if (profile != null) {
          // If account is deleted: sign out immediately and show invalid credentials
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

          emit(
            AuthState.authenticated(
              profile,
              status: profile.status,
              email: profile.email,
              phoneCode: profile.phoneCode,
              phoneNumber: profile.phoneNumber,
            ),
          );
          _listenToProfile(userId);
          return;
        }
      }
      emit(AuthState.authenticated(UserModel(id: userId, name: 'User')));
      _listenToProfile(userId);
    } catch (e, st) {
      AppLogger.e('AuthBloc._onLoginRequested error', tag: 'AuthBloc', error: e, stackTrace: st);
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
              dbStatus = UserStatus.values.fromValue(raw['status']);
            }
          } catch (_) {}
        }

        // Realtime: Listen immediately to changes in public.users (admin approve/block/delete)
        _listenToProfile(uid);

        final currentUser =
            profile ??
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
        AppLogger.w('OTP verification failed: $e', tag: 'AuthBloc');

        String cleanMessage = 'Verification failed. Please try again.';
        final errStr = e.toString().toLowerCase();

        if (errStr.contains('expired')) {
          cleanMessage =
              'The verification code has expired. Please request a new code.';
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
        AppLogger.e('AuthBloc._onSendPasswordResetRequested error', tag: 'AuthBloc', error: e, stackTrace: st);
        String cleanMessage =
            'Failed to send password reset code. Please check your email and try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('rate') || errStr.contains('too many requests')) {
          cleanMessage = 'Too many requests. Please wait a few moments before trying again.';
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
          operationState: const ApiState.success(
            UserModel(id: 'mock', name: 'Mock'),
          ),
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
        AppLogger.e('AuthBloc._onResetPasswordRequested error', tag: 'AuthBloc', error: e, stackTrace: st);
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
          operationState: ApiState.success(UserModel(id: 'mock', name: 'Mock')),
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
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onDeleteAccountRequested(
    AuthDeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(operationState: const ApiState.loading()));
    final authRepo = _authRepo;
    if (authRepo != null) {
      try {
        await authRepo.deleteAccount();
      } catch (e, st) {
        AppLogger.e('AuthBloc._onDeleteAccountRequested error', tag: 'AuthBloc', error: e, stackTrace: st);
        emit(
          state.copyWith(
            operationState: ApiState.failure(
              'Failed to delete account. Please try again.',
            ),
          ),
        );
        return;
      }
    }
    unawaited(_profileSubscription?.cancel());
    _profileSubscription = null;
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onReloadRoleDataRequested(
    AuthReloadRoleDataRequested event,
    Emitter<AuthState> emit,
  ) async {
    final uid = state.user?.id ?? _authRepo?.currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final results = await Future.wait([
        _fetchUserServices(uid),
        _fetchUserDocuments(uid),
      ]);
      emit(
        state.copyWith(
          userServices: results[0] as List<ServiceModel>,
          userDocuments: results[1] as List<UserDocumentModel>,
        ),
      );
    } catch (e) {
      AppLogger.w('Error reloading role data for $uid: $e', tag: 'AuthBloc');
    }
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

  Future<List<ServiceModel>> _fetchUserServices(String userId) async {
    try {
      final userServicesRows = await Supabase.instance.client
          .from(DatabaseTables.userServices)
          .select('service_id')
          .eq('user_id', userId);

      final serviceIds = (userServicesRows as List<dynamic>)
          .map((r) => r['service_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      if (serviceIds.isEmpty) return const [];

      final serviceRows = await Supabase.instance.client
          .from(DatabaseTables.services)
          .select()
          .order('display_order', ascending: true);

      return (serviceRows as List<dynamic>)
          .map((r) => ServiceModel.fromJson(r as Map<String, dynamic>))
          .where((s) => serviceIds.contains(s.id))
          .toList();
    } catch (e) {
      AppLogger.w('Error loading user services for $userId: $e', tag: 'AuthBloc');
      return const [];
    }
  }

  Future<List<UserDocumentModel>> _fetchUserDocuments(String userId) async {
    try {
      final docRows = await Supabase.instance.client
          .from(DatabaseTables.userDocuments)
          .select()
          .eq('user_id', userId);

      return (docRows as List<dynamic>)
          .map((r) => UserDocumentModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.w('Error loading user documents for $userId: $e', tag: 'AuthBloc');
      return const [];
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    return super.close();
  }
}
