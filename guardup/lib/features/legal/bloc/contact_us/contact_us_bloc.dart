import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/di/injection_container.dart';
import '/core/error/api_exception.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../../data/enum/contact_us_status.enum.dart';
import '../../data/model/contact_us_request.model.dart';
import '../../data/repositories/contact_us.repository.dart';
import 'contact_us_event.dart';
import 'contact_us_state.dart';

class ContactUsBloc extends Bloc<ContactUsEvent, ContactUsState> {
  ContactUsBloc({
    ContactUsRepository? repository,
    this.getCurrentUserId,
    this.getCurrentRole,
  })  : _repository = repository ?? sl<ContactUsRepository>(),
        super(const ContactUsState()) {
    on<SubmitContactUsRequested>(_onSubmitContactUsRequested);
  }

  final ContactUsRepository _repository;
  final String? Function()? getCurrentUserId;
  final UserRole Function()? getCurrentRole;

  Future<void> _onSubmitContactUsRequested(
    SubmitContactUsRequested event,
    Emitter<ContactUsState> emit,
  ) async {
    emit(state.copyWith(submissionState: const ApiState.loading()));

    try {
      final currentUserId = getCurrentUserId?.call();
      final role = getCurrentRole?.call() ?? UserRole.customer;

      final request = ContactUsRequest(
        userId: currentUserId,
        role: role,
        fullName: event.submission.fullName,
        email: event.submission.email,
        message: event.submission.message,
        status: ContactUsStatus.pending,
      );

      await _repository.submit(request);

      emit(
        state.copyWith(
          submissionState: const ApiState.success(
            'Your message has been sent successfully. Our support desk will contact you shortly.',
          ),
        ),
      );
    } on ApiException catch (e) {
      AppLogger.d(
        'Error submitting contact_us inquiry: $e',
        tag: 'ContactUsBloc',
        error: e,
      );
      emit(
        state.copyWith(
          submissionState: ApiState.failure(e.message, error: e),
        ),
      );
    } catch (e, st) {
      AppLogger.d(
        'Error inserting contact_us inquiry: $e',
        tag: 'ContactUsBloc',
        error: e,
        stackTrace: st,
      );
      emit(
        state.copyWith(
          submissionState: ApiState.failure('Failed to submit message: $e'),
        ),
      );
    }
  }
}
