import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:guardup/core/error/api_exception.dart';
import 'package:guardup/core/state/api_state.dart';
import 'package:guardup/features/auth/data/enum/user_role.enum.dart';
import 'package:guardup/features/auth/domain/repositories/user_repository.dart';
import 'package:guardup/features/payments/bloc/registration_fee/registration_fee_bloc.dart';
import 'package:guardup/features/payments/data/enum/transaction_type.enum.dart';
import 'package:guardup/features/settings/bloc/admin_settings_cubit.dart';

class _MockAdminSettingsCubit extends Mock implements AdminSettingsCubit {}

class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  late _MockAdminSettingsCubit adminSettingsCubit;
  late _MockUserRepository userRepository;

  setUp(() {
    adminSettingsCubit = _MockAdminSettingsCubit();
    userRepository = _MockUserRepository();
  });

  RegistrationFeeBloc buildBloc({
    UserRole role = UserRole.guard,
    String? currentUserId = 'user-1',
    void Function()? onPaymentRecorded,
  }) => RegistrationFeeBloc(
    adminSettingsCubit: adminSettingsCubit,
    userRepository: userRepository,
    role: role,
    getCurrentUserId: () => currentUserId,
    onPaymentRecorded: onPaymentRecorded,
  );

  group('RegistrationFeeBloc', () {
    blocTest<RegistrationFeeBloc, RegistrationFeeState>(
      'Submitted emits failure when no current user is available',
      build: () => buildBloc(currentUserId: null),
      act: (bloc) => bloc.add(const RegistrationFeeSubmitted()),
      expect: () => [
        predicate<RegistrationFeeState>(
          (s) =>
              s.paymentStatus.isFailure &&
              s.paymentStatus.errorMessageOrNull ==
                  'Your session has expired. Please sign in again.',
        ),
      ],
    );

    test(
      'Submitted uses AdminSettingsCubit role fee, records payment, invokes callback, and returns TransactionModel',
      () async {
        var callbackCount = 0;
        when(
          () => adminSettingsCubit.getRegistrationFee(UserRole.company),
        ).thenReturn(199.0);
        when(
          () => userRepository.recordRegistrationPayment(
            userId: 'user-1',
            paymentId: any(named: 'paymentId'),
            referenceId: any(named: 'referenceId'),
            amount: 199.0,
            currency: 'USD',
            paidAt: any(named: 'paidAt'),
          ),
        ).thenAnswer((_) async {});

        final bloc = buildBloc(
          role: UserRole.company,
          onPaymentRecorded: () => callbackCount++,
        );

        bloc.add(
          const RegistrationFeeSubmitted(discountNote: 'Discount included'),
        );

        await expectLater(
          bloc.stream,
          emitsThrough(
            predicate<RegistrationFeeState>(
              (s) => s.paymentStatus.isSuccess,
            ),
          ),
        );

        final tx = bloc.state.paymentStatus.dataOrNull!;
        expect(tx.amount, 199.0);
        expect(tx.currency, 'USD');
        expect(tx.type, TransactionType.debit);
        expect(tx.discountNote, 'Discount included');
        expect(tx.referenceId, startsWith('#GD-'));
        expect(callbackCount, 1);

        await bloc.close();
      },
    );

    blocTest<RegistrationFeeBloc, RegistrationFeeState>(
      'Submitted emits failure carrying ApiException when repository throws',
      build: () {
        when(
          () => adminSettingsCubit.getRegistrationFee(UserRole.guard),
        ).thenReturn(49.0);
        when(
          () => userRepository.recordRegistrationPayment(
            userId: 'user-1',
            paymentId: any(named: 'paymentId'),
            referenceId: any(named: 'referenceId'),
            amount: 49.0,
            currency: 'USD',
            paidAt: any(named: 'paidAt'),
          ),
        ).thenThrow(ApiException('Payment write failed'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const RegistrationFeeSubmitted()),
      expect: () => [
        const RegistrationFeeState(paymentStatus: ApiState.loading()),
        predicate<RegistrationFeeState>(
          (s) =>
              s.paymentStatus.isFailure &&
              (s.paymentStatus.errorOrNull as ApiException?)?.message ==
                  'Payment write failed',
        ),
      ],
    );
  });
}

