import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/state/api_state.dart';
import '../../data/model/legal_content.model.dart';
import 'legal_content_event.dart';
import 'legal_content_state.dart';

class LegalContentBloc extends Bloc<LegalContentEvent, LegalContentState> {
  LegalContentBloc() : super(const LegalContentState()) {
    on<LegalContentRequested>(_onLegalContentRequested);
  }

  Future<void> _onLegalContentRequested(
    LegalContentRequested event,
    Emitter<LegalContentState> emit,
  ) async {
    // 1. Emit loading with static fake data for Skeletonizer
    final fakeData = LegalContentModel.staticContent(event.contentType);
    emit(state.copyWith(contentState: ApiState.loading(previousData: fakeData)));

    // 2. Simulate short delay for realistic skeleton effect
    await Future<void>.delayed(const Duration(milliseconds: 600));

    // 3. Emit success with static data
    final content = LegalContentModel.staticContent(event.contentType);
    emit(state.copyWith(contentState: ApiState.success(content)));
  }
}

