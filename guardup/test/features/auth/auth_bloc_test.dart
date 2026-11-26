import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/body_guard/data/enum/document_status.enum.dart';
import 'package:guardup/features/body_guard/data/model/user_document.model.dart';
import 'package:guardup/features/services/data/models/service.model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockUserRepository userRepository;
  late StreamController<String?> authChangesController;
  late StreamController<Map<String, dynamic>?> watchDataController;

  setUpAll(() {
    registerFallbackValue(OtpType.email);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    userRepository = _MockUserRepository();
    authChangesController = StreamController<String?>.broadcast();
    watchDataController = StreamController<Map<String, dynamic>?>.broadcast();

    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => authChangesController.stream);
    when(
      () => userRepository.watchUserData(any()),
    ).thenAnswer((_) => watchDataController.stream);
    when(
      () => userRepository.watchProfile(any()),
    ).thenAnswer((_) => const Stream<UserModel?>.empty());
  });

  tearDown(() async {
    await authChangesController.close();
    await watchDataController.close();
  });

  Future<AuthBloc> createSettledBloc({String? initialUserId}) async {
    when(() => authRepository.currentUserId).thenReturn(initialUserId);
    final bloc = AuthBloc(
      authRepository: authRepository,
      userRepository: userRepository,
    );
    await pumpEventQueue();
    return bloc;
  }

  const guardUser = UserModel(
    id: 'u1',
    name: 'Alex Guard',
    email: 'alex@guard.io',
    role: UserRole.guard,
    status: UserStatus.incomplete,
    serviceListData: [ServiceModel(id: 's1', name: 'VIP')],
    documents: [
      UserDocumentModel(
        id: 'd1',
        documentTypeId: 'dt1',
        fileUrl: 'https://example.com/doc.pdf',
        status: DocumentStatus.pending,
      ),
    ],
  );

  group('AuthState parity (Trap 7.12)', () {
    test('AuthState.authenticated forces customer status to active when status is omitted', () {
      const customerWithIncomplete = UserModel(
        id: 'c1',
        name: 'Customer',
        email: 'c@test.io',
        role: UserRole.customer,
        status: UserStatus.incomplete,
      );
      final state = AuthState.authenticated(customerWithIncomplete);
      expect(state.isAuthenticated, isTrue);
      expect(state.status, UserStatus.active);
    });
  });

  group('AuthBloc §9.1 characterization', () {
    test('Row 1: app start with session + profile found authenticates with DB status', () async {
      const customerActive = UserModel(
        id: 'c1',
        name: 'Customer',
        email: 'c@test.io',
        role: UserRole.customer,
        status: UserStatus.active,
      );
      when(
        () => userRepository.getUserProfile('c1'),
      ).thenAnswer((_) async => customerActive);

      final bloc = await createSettledBloc(initialUserId: 'c1');
      expect(bloc.state.isAuthenticated, isTrue);
      expect(bloc.state.user?.id, 'c1');
      expect(bloc.state.status, UserStatus.active);
      await bloc.close();
    });

    test('Row 2: app start with session but missing profile row emits unauthenticated', () async {
      when(
        () => userRepository.getUserProfile('u-missing'),
      ).thenAnswer((_) async => null);

      final bloc = await createSettledBloc(initialUserId: 'u-missing');
      expect(bloc.state.isUnauthenticated, isTrue);
      await bloc.close();
    });

    test('Row 3: app start with no session emits unauthenticated', () async {
      final bloc = await createSettledBloc(initialUserId: null);
      expect(bloc.state.isUnauthenticated, isTrue);
      await bloc.close();
    });

    test('Row 4: login OK with active/non-deleted user authenticates', () async {
      when(
        () => authRepository.signInWithEmail(
          email: 'alex@guard.io',
          password: 'secret',
        ),
      ).thenAnswer((_) async => 'u1');
      when(
        () => userRepository.getUserProfile('u1'),
      ).thenAnswer((_) async => guardUser);

      final bloc = await createSettledBloc(initialUserId: null);
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>((s) => s.isAuthenticated && s.user?.id == 'u1'),
        ),
      );

      bloc.add(
        const AuthLoginRequested(email: 'alex@guard.io', password: 'secret'),
      );
      await future;
      await bloc.close();
    });

    test('Row 5: login OK with DELETED user signs out and shows invalid credentials error', () async {
      const deletedUser = UserModel(
        id: 'u-del',
        name: 'Deleted',
        email: 'del@guard.io',
        role: UserRole.guard,
        status: UserStatus.deleted,
      );
      when(
        () => authRepository.signInWithEmail(
          email: 'del@guard.io',
          password: 'secret',
        ),
      ).thenAnswer((_) async => 'u-del');
      when(
        () => userRepository.getUserProfile('u-del'),
      ).thenAnswer((_) async => deletedUser);
      when(() => authRepository.signOut()).thenAnswer((_) async {});

      final bloc = await createSettledBloc(initialUserId: null);
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.isUnauthenticated &&
                s.hasError &&
                s.errorMessage ==
                    'Invalid email or password. Please try again.',
          ),
        ),
      );

      bloc.add(
        const AuthLoginRequested(email: 'del@guard.io', password: 'secret'),
      );
      await future;
      verify(() => authRepository.signOut()).called(1);
      await bloc.close();
    });

    test('Row 6 & Row 7: realtime admin BLOCKED keeps authenticated+blocked; DELETED signs out', () async {
      when(
        () => userRepository.getUserProfile('u1'),
      ).thenAnswer((_) async => guardUser);
      when(() => authRepository.signOut()).thenAnswer((_) async {});

      final bloc = await createSettledBloc(initialUserId: 'u1');
      expect(bloc.state.isAuthenticated, isTrue);

      final blockedFuture = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>((s) => s.isAuthenticated && s.isBlocked),
        ),
      );
      watchDataController.add({
        'id': 'u1',
        'name': 'Alex Guard',
        'email': 'alex@guard.io',
        'role': 'GUARD',
        'status': 'BLOCKED',
      });
      await blockedFuture;

      final deletedFuture = expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.isUnauthenticated)),
      );
      watchDataController.add({
        'id': 'u1',
        'name': 'Alex Guard',
        'email': 'alex@guard.io',
        'role': 'GUARD',
        'status': 'DELETED',
      });
      await deletedFuture;
      verify(() => authRepository.signOut()).called(1);
      await bloc.close();
    });

    test('Row 9: login with unconfirmed email resends OTP and exposes email + unconfirmed failure', () async {
      when(
        () => authRepository.signInWithEmail(
          email: 'unconfirmed@guard.io',
          password: 'secret',
        ),
      ).thenThrow(
        const AuthException(
          'Email not confirmed',
          code: 'email_not_confirmed',
        ),
      );
      when(
        () => authRepository.resendOtp(
          target: 'unconfirmed@guard.io',
          type: OtpType.email,
        ),
      ).thenAnswer((_) async {});

      final bloc = await createSettledBloc(initialUserId: null);
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.email == 'unconfirmed@guard.io' &&
                s.errorMessage == 'EMAIL_NOT_CONFIRMED',
          ),
        ),
      );

      bloc.add(
        const AuthLoginRequested(
          email: 'unconfirmed@guard.io',
          password: 'secret',
        ),
      );
      await future;
      verify(
        () => authRepository.resendOtp(
          target: 'unconfirmed@guard.io',
          type: OtpType.email,
        ),
      ).called(1);
      await bloc.close();
    });

    test('Row 10 & Row 15: role selection preserved for sign up metadata and stays unauthenticated with email', () async {
      when(
        () => authRepository.signUpWithEmail(
          email: 'new@guard.io',
          password: 'secret',
          metadata: any(named: 'metadata'),
        ),
      ).thenAnswer((_) async => 'u-new');

      final bloc = await createSettledBloc(initialUserId: null);
      final roleFuture = expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.sessionRole == UserRole.guard)),
      );
      bloc.add(const AuthSetSessionRoleRequested(UserRole.guard));
      await roleFuture;

      final signUpFuture = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.isUnauthenticated && s.email == 'new@guard.io',
          ),
        ),
      );
      bloc.add(
        const AuthSignUpRequested(
          email: 'new@guard.io',
          password: 'secret',
          role: UserRole.guard,
          name: 'New Guard',
          phone: '9999999999',
          phoneCode: '+91',
        ),
      );
      await signUpFuture;

      final capturedMeta =
          verify(
            () => authRepository.signUpWithEmail(
              email: 'new@guard.io',
              password: 'secret',
              metadata: captureAny(named: 'metadata'),
            ),
          ).captured.single as Map<String, dynamic>?;
      expect(capturedMeta, {
        'role': 'GUARD',
        'name': 'New Guard',
        'phone': '9999999999',
        'phone_code': '+91',
      });
      await bloc.close();
    });

    test('Row 11 & 12: verifyOtp recovery preserves DB status', () async {
      when(
        () => authRepository.verifyOtp(
          target: 'u@test.io',
          token: '123456',
          type: OtpType.recovery,
        ),
      ).thenAnswer((_) async => 'u1');
      when(() => userRepository.getUserData('u1')).thenAnswer(
        (_) async => {
          'id': 'u1',
          'name': 'Alex',
          'email': 'u@test.io',
          'role': 'GUARD',
          'status': 'ACTIVE',
        },
      );

      final bloc = await createSettledBloc(initialUserId: null);
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.isAuthenticated && s.status == UserStatus.active,
          ),
        ),
      );

      bloc.add(
        const AuthVerifyOtpRequested(
          email: 'u@test.io',
          token: '123456',
          type: OtpType.recovery,
        ),
      );
      await future;
      await bloc.close();
    });

    test('Row 13: resetPassword changes password and signs out', () async {
      when(
        () => authRepository.changePassword(newPassword: 'new-password'),
      ).thenAnswer((_) async {});
      when(() => authRepository.signOut()).thenAnswer((_) async {});

      final bloc = await createSettledBloc(initialUserId: null);
      final future = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) => s.isUnauthenticated && s.operationState.isSuccess,
          ),
        ),
      );

      bloc.add(const AuthResetPasswordRequested(newPassword: 'new-password'));
      await future;
      verify(() => authRepository.changePassword(newPassword: 'new-password'))
          .called(1);
      verify(() => authRepository.signOut()).called(1);
      await bloc.close();
    });

    test('Row 14 & 16: deleteAccount unauthenticates on success and keeps session + error on failure', () async {
      when(
        () => userRepository.getUserProfile('u1'),
      ).thenAnswer((_) async => guardUser);
      when(
        () => authRepository.deleteAccount(),
      ).thenThrow(Exception('network'));
      when(() => authRepository.signOut()).thenAnswer((_) async {});

      final bloc = await createSettledBloc(initialUserId: 'u1');
      expect(bloc.state.isAuthenticated, isTrue);

      final failFuture = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.isAuthenticated &&
                s.errorMessage ==
                    'Failed to delete account. Please try again.',
          ),
        ),
      );
      bloc.add(const AuthDeleteAccountRequested());
      await failFuture;

      when(() => authRepository.deleteAccount()).thenAnswer((_) async {});
      final successFuture = expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.isUnauthenticated)),
      );
      bloc.add(const AuthDeleteAccountRequested());
      await successFuture;

      await bloc.close();
    });
  });
}
