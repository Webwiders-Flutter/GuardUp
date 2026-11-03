import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/state/api_state.dart';
import '../data/model/user.model.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository? _authRepo;
  final UserRepository? _userRepo;

  StreamSubscription<String?>? _authSubscription;
  StreamSubscription<UserModel?>? _profileSubscription;

  AuthBloc({
    AuthRepository? authRepository,
    UserRepository? userRepository,
  })  : _authRepo = authRepository,
        _userRepo = userRepository,
        super(const AuthState.unknown()) {
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileChanged>(_onProfileChanged);
    on<AuthErrorOccurred>(_onErrorOccurred);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
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
    _authSubscription = _authRepo?.authStateChanges.listen((userId) {
      add(AuthUserChanged(userId));
    }, onError: (Object error) {
      add(AuthErrorOccurred(error.toString()));
    });
  }

  void _listenToProfile(String userId) {
    if (_userRepo == null) return;
    _profileSubscription?.cancel();
    _profileSubscription = _userRepo.watchUserProfile(userId).listen(
      (profile) {
        add(AuthProfileChanged(profile));
      },
      onError: (Object error) {
        add(AuthErrorOccurred(error.toString()));
      },
    );
  }

  void _onErrorOccurred(
    AuthErrorOccurred event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      operationState: ApiState.failure(
        event.message,
        previousData: state.user,
      ),
    ));
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Artificial 2-second delay for splash bootstrap
    await Future.delayed(const Duration(seconds: 2));

    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(const AuthState.unauthenticated());
      return;
    }

    final currentUid = authRepo.currentUserId;
    if (currentUid != null) {
      try {
        if (_userRepo != null) {
          final profile = await _userRepo.getUserProfile(currentUid);
          if (profile != null) {
            emit(AuthState.authenticated(profile));
            _listenToProfile(currentUid);
            return;
          }
        }
        emit(AuthState.authenticated(UserModel(id: currentUid, name: 'User')));
      } catch (e) {
        emit(AuthState.unauthenticated(
          operationState: ApiState.failure(e.toString()),
        ));
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

    emit(state.copyWith(
      operationState: ApiState.success(updatedUser),
    ));
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
    }
  }

  Future<void> _onProfileChanged(
    AuthProfileChanged event,
    Emitter<AuthState> emit,
  ) async {
    if (event.profile != null) {
      emit(AuthState.authenticated(event.profile!));
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
      emit(state.copyWith(
        operationState:
            const ApiState.failure('AuthRepository not configured.'),
      ));
      return;
    }

    emit(state.copyWith(
      operationState: ApiState.loading(previousData: state.user),
    ));
    try {
      final userId = await authRepo.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      if (_userRepo != null) {
        final profile = await _userRepo.getUserProfile(userId);
        if (profile != null) {
          emit(AuthState.authenticated(profile));
          _listenToProfile(userId);
          return;
        }
      }
      emit(AuthState.authenticated(UserModel(id: userId, name: 'User')));
      _listenToProfile(userId);
    } catch (e) {
      emit(state.copyWith(
        operationState: ApiState.failure(e.toString()),
      ));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(state.copyWith(
        operationState:
            const ApiState.failure('AuthRepository not configured.'),
      ));
      return;
    }

    emit(state.copyWith(
      operationState: ApiState.loading(previousData: state.user),
    ));
    try {
      final userId = await authRepo.signUpWithEmail(
        email: event.email,
        password: event.password,
      );
      final newUser = UserModel(
        id: userId,
        name: event.name ?? 'New User',
        role: state.sessionRole,
      );
      if (_userRepo != null) {
        await _userRepo.createUserProfile(user: newUser);
      }
      emit(AuthState.authenticated(newUser));
      _listenToProfile(userId);
    } catch (e) {
      emit(state.copyWith(
        operationState: ApiState.failure(e.toString()),
      ));
    }
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null || _userRepo == null) return;

    emit(state.copyWith(
      operationState: ApiState.loading(previousData: current),
    ));
    try {
      final updated = current.copyWith(
        name: event.name ?? current.name,
        profileImageUrl: event.profileImageUrl ?? current.profileImageUrl,
      );
      await _userRepo.updateUserProfile(user: updated);
      emit(state.copyWith(
        operationState: ApiState.success(updated),
      ));
    } catch (e) {
      emit(state.copyWith(
        operationState: ApiState.failure(e.toString(), previousData: current),
      ));
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
