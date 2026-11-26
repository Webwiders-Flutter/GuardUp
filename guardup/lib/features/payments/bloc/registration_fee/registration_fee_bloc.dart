import 'dart:math' as math;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '/features/auth/data/repositories/user_repository.dart';
import '/features/settings/bloc/admin_settings_cubit.dart';
import '../../data/enum/transaction_type.enum.dart';
import '../../data/model/transaction.model.dart';
import 'registration_fee_event.dart';
import 'registration_fee_state.dart';

export 'registration_fee_event.dart';
export 'registration_fee_state.dart';

/// Handles the one-time registration fee payment flow using the configured
/// role fee from [AdminSettingsCubit] and persists payment status via [UserRepository].
class RegistrationFeeBloc
    extends Bloc<RegistrationFeeEvent, RegistrationFeeState> {
  RegistrationFeeBloc({
    required this.adminSettingsCubit,
    required this.userRepository,
    required this.role,
    required this.getCurrentUserId,
    this.onPaymentRecorded,
  }) : super(const RegistrationFeeState()) {
    on<RegistrationFeeSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AdminSettingsCubit adminSettingsCubit;
  final UserRepository userRepository;
  final UserRole role;
  final String? Function() getCurrentUserId;
  final void Function()? onPaymentRecorded;

  double get currentFee => adminSettingsCubit.getRegistrationFee(role);

  Future<void> _onSubmitted(
    RegistrationFeeSubmitted event,
    Emitter<RegistrationFeeState> emit,
  ) async {
    final userId = getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      emit(
        state.copyWith(
          paymentStatus: const ApiState.failure(
            'Your session has expired. Please sign in again.',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(paymentStatus: const ApiState.loading()));

    try {
      final feeAmount = currentFee;
      final randomNum = math.Random().nextInt(900000) + 100000;
      final referenceId = '#GD-$randomNum';
      final now = DateTime.now();
      final paymentId = 'pay_stripe_${now.millisecondsSinceEpoch}';

      await asyncHandler(
        () => userRepository.recordRegistrationPayment(
          userId: userId,
          paymentId: paymentId,
          referenceId: referenceId,
          amount: feeAmount,
          paidAt: now,
        ),
      );

      onPaymentRecorded?.call();

      final transaction = TransactionModel(
        id: paymentId,
        referenceId: referenceId,
        bookingId: referenceId,
        amount: feeAmount,
        currency: 'USD',
        type: TransactionType.debit,
        title: 'Registration Fee',
        gateway: 'Stripe Verified',
        scheduleText: 'Today, 2:00 PM – 4:00 PM',
        dateTime: now,
        discountNote: event.discountNote,
      );

      emit(state.copyWith(paymentStatus: ApiState.success(transaction)));
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          paymentStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }
}

