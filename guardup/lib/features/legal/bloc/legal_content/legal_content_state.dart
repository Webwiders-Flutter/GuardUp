import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/legal_content.model.dart';

/// State representation for legal content operations.
class LegalContentState extends Equatable {
  final ApiState<LegalContentModel> contentState;

  const LegalContentState({
    this.contentState = const ApiState.initial(),
  });

  LegalContentState copyWith({
    ApiState<LegalContentModel>? contentState,
  }) {
    return LegalContentState(
      contentState: contentState ?? this.contentState,
    );
  }

  @override
  List<Object?> get props => [contentState];
}

