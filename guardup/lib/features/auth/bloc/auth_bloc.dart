import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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
        super(const AuthState.initial()) {
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthProfileChanged>(_onProfileChanged);
    on<AuthErrorOccurred>(_onErrorOccurred);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthUpdateProfileRequested>(_onUpdateProfileRequested);
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
    emit(AuthState.error(event.message, previousUser: state.user));
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
      emit(const AuthState.loading());
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
        emit(AuthState.error(e.toString()));
      }
    } else {
      emit(const AuthState.unauthenticated());
    }
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
      emit(const AuthState.error('AuthRepository not configured.'));
      return;
    }

    emit(const AuthState.loading());
    try {
      final userId = await authRepo.signInWithEmail(
        email: event.email,
        password: event.password,
      );
      if (_userRepo != null) {
        final profile = await _userRepo.getUserProfile(userId);
        if (profile != null) {
          emit(AuthState.authenticated(profile));
          return;
        }
      }
      emit(AuthState.authenticated(UserModel(id: userId, name: event.email)));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final authRepo = _authRepo;
    if (authRepo == null) {
      emit(const AuthState.error('AuthRepository not configured.'));
      return;
    }

    emit(const AuthState.loading());
    try {
      final userId = await authRepo.signUpWithEmail(
        email: event.email,
        password: event.password,
        metadata: event.name != null ? {'name': event.name} : null,
      );
      final user = UserModel(id: userId, name: event.name ?? event.email);
      if (_userRepo != null) {
        await _userRepo.createUserProfile(user: user);
      }
      emit(AuthState.authenticated(user));
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  Future<void> _onUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final current = state.user;
    if (current == null) return;

    emit(AuthState.loading(previousUser: current));
    try {
      final updated = current.copyWith(
        name: event.name ?? current.name,
        profileImageUrl: event.profileImageUrl ?? current.profileImageUrl,
      );
      if (_userRepo != null) {
        await _userRepo.updateUserProfile(user: updated);
      }
      emit(AuthState.authenticated(updated));
    } catch (e) {
      emit(AuthState.error(e.toString(), previousUser: current));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      _cancelSubscriptions();
      await _authRepo?.signOut();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void _cancelSubscriptions() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _profileSubscription?.cancel();
    _profileSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
