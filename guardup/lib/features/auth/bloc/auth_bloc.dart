import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '../data/enum/user_role.enum.dart';
import '../data/enum/user_status.enum.dart';
import '../data/model/user.model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
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
    on<AuthSignOutRequested>(_onSignOutRequested);

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
}

final class _AuthUserIdChanged extends AuthEvent {
  const _AuthUserIdChanged(this.userId);

  final String? userId;

  @override
  List<Object?> get props => [userId];
}
