import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '/core/constants/api/database_tables.dart';
import '/core/di/injection_container.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/bloc/auth_bloc.dart';
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

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final role = sl.isRegistered<AuthBloc>()
          ? sl<AuthBloc>().state.sessionRole.apiValue
          : 'CUSTOMER';

      final payload = {
        'user_id': ?currentUserId,
        'role': role,
        'full_name': event.submission.fullName,
        'email': event.submission.email,
        'message': event.submission.message,
        'status': 'PENDING',
      };

      await Supabase.instance.client
          .from(DatabaseTables.contactUs)
          .insert(payload);

      emit(
        state.copyWith(
          submissionState: const ApiState.success(
            'Your message has been sent successfully. Our support desk will contact you shortly.',
          ),
        ),
      );
    } catch (e, st) {
      AppLogger.d('Error inserting contact_us inquiry: $e', tag: 'ContactUsBloc', error: e, stackTrace: st);
      emit(
        state.copyWith(
          submissionState: ApiState.failure('Failed to submit message: $e'),
        ),
      );
    }
  }
}
