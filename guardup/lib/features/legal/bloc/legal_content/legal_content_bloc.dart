import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/di/injection_container.dart';
import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../../data/model/legal_content.model.dart';
import '../../data/repositories/legal_content.repository.dart';
import 'legal_content_event.dart';
import 'legal_content_state.dart';

class LegalContentBloc extends Bloc<LegalContentEvent, LegalContentState> {
  LegalContentBloc({
    LegalContentRepository? repository,
    this.getCurrentRole,
  })  : _repository = repository ?? sl<LegalContentRepository>(),
        super(const LegalContentState()) {
    on<LegalContentRequested>(_onLegalContentRequested);
  }

  final LegalContentRepository _repository;
  final UserRole Function()? getCurrentRole;

  Future<void> _onLegalContentRequested(
    LegalContentRequested event,
    Emitter<LegalContentState> emit,
  ) async {
    // 1. Emit loading with static fake data for Skeletonizer
    final fallbackData = LegalContentModel.staticContent(event.contentType);
    emit(
      state.copyWith(
        contentState: ApiState.loading(previousData: fallbackData),
      ),
    );

    try {
      // 2. Resolve target role: from event, or from constructor callback, or default to CUSTOMER
      final targetRole =
          event.role ?? getCurrentRole?.call() ?? UserRole.customer;

      // 3. Query repository
      final model = await _repository.getLatest(
        role: targetRole,
        type: event.contentType,
        language: event.language,
      );

      if (model != null && model.contentHtml.isNotEmpty) {
        emit(state.copyWith(contentState: ApiState.success(model)));
      } else {
        // Fallback to static content if no database record exists
        emit(state.copyWith(contentState: ApiState.success(fallbackData)));
      }
    } catch (e, st) {
      AppLogger.d(
        'Error fetching legal content: $e',
        tag: 'LegalContentBloc',
        error: e,
        stackTrace: st,
      );
      emit(state.copyWith(contentState: ApiState.success(fallbackData)));
    }
  }
}
