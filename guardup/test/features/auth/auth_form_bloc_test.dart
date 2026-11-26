import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/bloc/auth_form/auth_form_bloc.dart';
import 'package:guardup/features/auth/data/enum/user_role.enum.dart';
import 'package:guardup/features/auth/data/enum/user_status.enum.dart';
import 'package:guardup/features/auth/data/model/user.model.dart';
import 'package:guardup/features/auth/data/repositories/auth_repository.dart';
import 'package:guardup/features/auth/data/repositories/user_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockUserRepository userRepository;

  setUpAll(() {
    registerFallbackValue(OtpType.email);
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    userRepository = _MockUserRepository();
  });

  AuthFormBloc buildBloc({
    void Function()? onAuthenticated,
    void Function(UserRole role, String email)? onPendingSignUp,
  }) => AuthFormBloc(
    authRepository: authRepository,
    userRepository: userRepository,
    onAuthenticated: onAuthenticated,
    onPendingSignUp: onPendingSignUp,
  );

  group('AuthFormBloc', () {
    blocTest<AuthFormBloc, AuthFormState>(
      'LoginSubmitted signs in non-deleted user, calls onAuthenticated and emits signedIn',
      build: () {
        when(
          () => authRepository.signInWithEmail(
            email: 'alex@guard.io',
            password: 'secret',
          ),
        ).thenAnswer((_) async => 'u1');
        when(() => userRepository.getProfile('u1')).thenAnswer(
          (_) async => const UserModel(
            id: 'u1',
            name: 'Alex',
            role: UserRole.customer,
            status: UserStatus.incomplete,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: ' Alex@Guard.io ', password: 'secret'),
      ),
      expect: () => [
        const AuthFormState(
          status: ApiState.loading(),
          email: 'alex@guard.io',
        ),
        const AuthFormState(
          status: ApiState.success(AuthFormResult.signedIn),
          email: 'alex@guard.io',
          authenticatedUser: UserModel(
            id: 'u1',
            name: 'Alex',
            role: UserRole.customer,
            status: UserStatus.incomplete,
          ),
        ),
      ],
    );

    blocTest<AuthFormBloc, AuthFormState>(
      'LoginSubmitted signs out deleted user and emits invalid credentials failure (Row 5)',
      build: () {
        when(
          () => authRepository.signInWithEmail(
            email: 'del@guard.io',
            password: 'secret',
          ),
        ).thenAnswer((_) async => 'u-del');
        when(() => userRepository.getProfile('u-del')).thenAnswer(
          (_) async => const UserModel(
            id: 'u-del',
            name: 'Del',
            role: UserRole.guard,
            status: UserStatus.deleted,
          ),
        );
        when(() => authRepository.signOut()).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'del@guard.io', password: 'secret'),
      ),
      verify: (_) => verify(() => authRepository.signOut()).called(1),
      expect: () => [
        const AuthFormState(
          status: ApiState.loading(),
          email: 'del@guard.io',
        ),
        predicate<AuthFormState>(
          (s) =>
              s.status.isFailure &&
              s.status.errorMessageOrNull ==
                  'Invalid email or password. Please try again.',
        ),
      ],
    );

    blocTest<AuthFormBloc, AuthFormState>(
      'LoginSubmitted resends OTP and emits emailNotConfirmed when Supabase raises email_not_confirmed (Row 9)',
      build: () {
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
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoginSubmitted(email: 'unconfirmed@guard.io', password: 'secret'),
      ),
      verify: (_) => verify(
        () => authRepository.resendOtp(
          target: 'unconfirmed@guard.io',
          type: OtpType.email,
        ),
      ).called(1),
      expect: () => [
        const AuthFormState(
          status: ApiState.loading(),
          email: 'unconfirmed@guard.io',
        ),
        const AuthFormState(
          status: ApiState.success(AuthFormResult.emailNotConfirmed),
          email: 'unconfirmed@guard.io',
        ),
      ],
    );

    blocTest<AuthFormBloc, AuthFormState>(
      'SignUpSubmitted surfaces registration conflict without calling authRepository.signUpWithEmail',
      build: () {
        when(
          () => userRepository.checkRegistrationConflict(
            email: 'taken@guard.io',
            phone: '9999999999',
            phoneCode: '+91',
          ),
        ).thenAnswer((_) async => 'Email already in use');
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const SignUpSubmitted(
          email: 'taken@guard.io',
          password: 'secret',
          role: UserRole.guard,
          name: 'Alex',
          phone: '9999999999',
          phoneCode: '+91',
        ),
      ),
      verify: (_) => verifyNever(
        () => authRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          metadata: any(named: 'metadata'),
        ),
      ),
      expect: () => [
        const AuthFormState(
          status: ApiState.loading(),
          email: 'taken@guard.io',
        ),
        predicate<AuthFormState>(
          (s) =>
              s.status.isFailure &&
              s.status.errorMessageOrNull == 'Email already in use',
        ),
      ],
    );

    blocTest<AuthFormBloc, AuthFormState>(
      'PasswordResetCodeRequested verifies email existence and sends reset email',
      build: () {
        when(
          () => userRepository.checkEmailExists('alex@guard.io'),
        ).thenAnswer((_) async => (exists: true, errorMessage: null));
        when(
          () => authRepository.sendPasswordResetEmail(email: 'alex@guard.io'),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const PasswordResetCodeRequested(email: 'Alex@Guard.io')),
      expect: () => [
        const AuthFormState(
          status: ApiState.loading(),
          email: 'alex@guard.io',
        ),
        const AuthFormState(
          status: ApiState.success(AuthFormResult.resetCodeSent),
          email: 'alex@guard.io',
        ),
      ],
    );

    blocTest<AuthFormBloc, AuthFormState>(
      'NewPasswordSubmitted updates password and signs out recovery session (Row 13)',
      build: () {
        when(
          () => authRepository.changePassword(newPassword: 'new-password'),
        ).thenAnswer((_) async {});
        when(() => authRepository.signOut()).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const NewPasswordSubmitted(newPassword: 'new-password')),
      verify: (_) => verify(() => authRepository.signOut()).called(1),
      expect: () => [
        const AuthFormState(status: ApiState.loading()),
        const AuthFormState(
          status: ApiState.success(AuthFormResult.passwordChanged),
        ),
      ],
    );
  });
}
