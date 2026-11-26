import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
    test(
      'AuthState.authenticated forces customer status to active when status is omitted',
      () {
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
      },
    );
  });

  group('AuthBloc session & realtime parity (§9.1 rows 1–3, 6–8, 15–16)', () {
    test(
      'Row 1 & 7.12: app start with session + profile found authenticates and customer forces active status',
      () async {
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
      },
    );

    test(
      'Row 2: app start with session but missing profile row emits unauthenticated',
      () async {
        when(
          () => userRepository.getProfile('u-missing'),
        ).thenAnswer((_) async => null);

        final bloc = await createSettledBloc(initialUserId: 'u-missing');
        expect(bloc.state.isUnauthenticated, isTrue);
        await bloc.close();
      },
    );

    test('Row 3: app start with no session emits unauthenticated', () async {
      final bloc = await createSettledBloc(initialUserId: null);
      expect(bloc.state.isUnauthenticated, isTrue);
      await bloc.close();
    });

    test(
      'Rows 6, 7 & 8: realtime BLOCKED keeps authenticated; REJECTED updates documents/services; DELETED signs out',
      () async {
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
        watchProfileController.add(
          guardUser.copyWith(status: UserStatus.blocked),
        );
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
        watchProfileController.add(
          guardUser.copyWith(status: UserStatus.deleted),
        );
        await deletedFuture;
        verify(() => authRepository.signOut()).called(1);
        await bloc.close();
      },
    );

    test(
      'Row 15 & Row 16: AuthRoleSelected stores pendingRole and AuthSignOutRequested unauthenticates',
      () async {
        final bloc = await createSettledBloc(initialUserId: null);
        final roleFuture = expectLater(
          bloc.stream,
          emitsThrough(
            predicate<AuthState>(
              (s) =>
                  s.pendingRole == UserRole.guard &&
                  s.sessionRole == UserRole.guard,
            ),
          ),
        );
        bloc.add(const AuthRoleSelected(UserRole.guard));
        await roleFuture;

        when(
          () => userRepository.getProfile('u1'),
        ).thenAnswer((_) async => guardUser);
        when(() => authRepository.signOut()).thenAnswer((_) async {});

        final signedInFuture = expectLater(
          bloc.stream,
          emitsThrough(predicate<AuthState>((s) => s.isAuthenticated)),
        );
        authChangesController.add('u1');
        await signedInFuture;

        final signedOutFuture = expectLater(
          bloc.stream,
          emitsThrough(predicate<AuthState>((s) => s.isUnauthenticated)),
        );
        bloc.add(const AuthSignOutRequested());
        await signedOutFuture;
        verify(() => authRepository.signOut()).called(1);
        await bloc.close();
      },
    );

    test(
      'AuthProfileRefreshRequested reloads user profile via getProfile',
      () async {
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
      },
    );
  });
}
