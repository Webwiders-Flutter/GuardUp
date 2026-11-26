import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/repositories/bodyguard.repository.dart';
import 'bodyguard_details_event.dart';
import 'bodyguard_details_state.dart';

export 'bodyguard_details_event.dart';
export 'bodyguard_details_state.dart';

/// Loads full details (company, services, documents, availabilities) for a
/// bodyguard by [bodyguardId], optionally seeded with a [preview] model.
class BodyguardDetailsBloc
    extends Bloc<BodyguardDetailsEvent, BodyguardDetailsState> {
  BodyguardDetailsBloc(
    this._repository, {
    required this.bodyguardId,
    BodyGuardModel? preview,
  }) : super(BodyguardDetailsState(guard: preview)) {
    on<BodyguardDetailsStarted>(
      (_, emit) => _load(emit),
      transformer: restartable(),
    );
    on<BodyguardDetailsRefreshed>(
      (_, emit) => _load(emit),
      transformer: restartable(),
    );
  }

  final BodyguardRepository _repository;
  final String bodyguardId;

  Future<void> _load(Emitter<BodyguardDetailsState> emit) async {
    if (bodyguardId.isEmpty) {
      if (state.guard == null) {
        emit(
          state.copyWith(
            status: const ApiState.failure('Bodyguard not found.'),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ApiState.success(state.guard!),
          ),
        );
      }
      return;
    }

    emit(
      state.copyWith(
        status: ApiState.loading(previousData: state.guard),
      ),
    );

    try {
      final detailed = await asyncHandler(
        () => _repository.getDetails(bodyguardId),
      );
      emit(
        BodyguardDetailsState(
          guard: detailed,
          status: ApiState.success(detailed),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ApiState.failure(
            e.message,
            error: e,
            previousData: state.guard,
          ),
        ),
      );
    }
  }
}
