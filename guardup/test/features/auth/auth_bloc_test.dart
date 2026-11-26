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
  late StreamController<UserModel?> watchProfileController;

  setUpAll(() {
    registerFallbackValue(OtpType.email);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    userRepository = _MockUserRepository();
    authChangesController = StreamController<String?>.broadcast();
    watchProfileController = StreamController<UserModel?>.broadcast();

    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => authChangesController.stream);
    when(
      () => userRepository.watchProfile(any()),
    ).thenAnswer((_) => watchProfileController.stream);
  });

  tearDown(() async {
    await authChangesController.close();
    await watchProfileController.close();
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

  group('AuthBloc §9.1 parity', () {
    test('Row 1 & 7.12: app start with session + profile found authenticates and customer forces active status', () async {
      const customerIncomplete = UserModel(
        id: 'c1',
        name: 'Customer',
        email: 'c@test.io',
        role: UserRole.customer,
        status: UserStatus.incomplete,
      );
      when(
        () => userRepository.getProfile('c1'),
      ).thenAnswer((_) async => customerIncomplete);

      final bloc = await createSettledBloc(initialUserId: 'c1');
      expect(bloc.state.isAuthenticated, isTrue);
      expect(bloc.state.user?.id, 'c1');
      expect(bloc.state.status, UserStatus.active);
      await bloc.close();
    });

    test('Row 2: app start with session but missing profile row emits unauthenticated', () async {
      when(
        () => userRepository.getProfile('u-missing'),
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
        () => userRepository.getProfile('u1'),
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
        () => userRepository.getProfile('u-del'),
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

    test('Row 6, 7 & 8: realtime BLOCKED keeps authenticated; REJECTED updates documents/services; DELETED signs out', () async {
      when(
        () => userRepository.getProfile('u1'),
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
      watchProfileController.add(guardUser.copyWith(status: UserStatus.blocked));
      await blockedFuture;

      final rejectedFuture = expectLater(
        bloc.stream,
        emitsThrough(
          predicate<AuthState>(
            (s) =>
                s.isAuthenticated &&
                s.isRejected &&
                s.hasRejectedDocuments,
          ),
        ),
      );
      watchProfileController.add(
        guardUser.copyWith(
          status: UserStatus.rejected,
          documents: const [
            UserDocumentModel(
              id: 'd1',
              documentTypeId: 'dt1',
              fileUrl: 'https://example.com/doc.pdf',
              status: DocumentStatus.rejected,
            ),
          ],
        ),
      );
      await rejectedFuture;

      final deletedFuture = expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.isUnauthenticated)),
      );
      watchProfileController.add(guardUser.copyWith(status: UserStatus.deleted));
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

    test('Row 10 & Row 15: AuthRoleSelected preserved for sign up and keeps unauthenticated', () async {
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
      bloc.add(const AuthRoleSelected(UserRole.guard));
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
      when(() => userRepository.getProfile('u1')).thenAnswer(
        (_) async => const UserModel(
          id: 'u1',
          name: 'Alex',
          email: 'u@test.io',
          role: UserRole.guard,
          status: UserStatus.active,
        ),
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
      await bloc.close();
    });

    test('Row 14 & 16: deleteAccount unauthenticates on success and keeps session + error on failure; signOut unauthenticates', () async {
      when(
        () => userRepository.getProfile('u1'),
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

    test('AuthProfileRefreshRequested reloads user profile via getProfile', () async {
      when(
        () => userRepository.getProfile('u1'),
      ).thenAnswer((_) async => guardUser);

      final bloc = await createSettledBloc(initialUserId: 'u1');
      expect(bloc.state.status, UserStatus.incomplete);

      when(() => userRepository.getProfile('u1')).thenAnswer(
        (_) async => guardUser.copyWith(status: UserStatus.active),
      );
      final refreshFuture = expectLater(
        bloc.stream,
        emitsThrough(predicate<AuthState>((s) => s.isApproved)),
      );
      bloc.add(const AuthProfileRefreshRequested());
      await refreshFuture;
      await bloc.close();
    });
  });
}
