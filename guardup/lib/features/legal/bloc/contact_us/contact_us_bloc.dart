import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/state/api_state.dart';
import 'contact_us_event.dart';
import 'contact_us_state.dart';

class ContactUsBloc extends Bloc<ContactUsEvent, ContactUsState> {
  ContactUsBloc() : super(const ContactUsState()) {
    on<SubmitContactUsRequested>(_onSubmitContactUsRequested);
  }

  Future<void> _onSubmitContactUsRequested(
    SubmitContactUsRequested event,
    Emitter<ContactUsState> emit,
  ) async {
    emit(state.copyWith(submissionState: const ApiState.loading()));

    // Simulate network delay with static success
    await Future<void>.delayed(const Duration(milliseconds: 500));

    emit(
      state.copyWith(
        submissionState: const ApiState.success(
          'Your inquiry has been submitted. Our security desk will contact you shortly.',
        ),
      ),
    );
  }
}

