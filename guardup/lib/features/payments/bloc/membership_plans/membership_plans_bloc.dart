import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/error/api_exception.dart';
import '/core/state/api_state.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/model/membership_plan.model.dart';
import '../../data/repositories/membership_plan.repository.dart';
import 'membership_plans_event.dart';
import 'membership_plans_state.dart';

export 'membership_plans_event.dart';
export 'membership_plans_state.dart';

/// Loads and manages selection for VIP membership plans (`public.membership_plans`).
class MembershipPlansBloc
    extends Bloc<MembershipPlansEvent, MembershipPlansState> {
  MembershipPlansBloc(this._repository) : super(const MembershipPlansState()) {
    on<MembershipPlansStarted>(_onStarted, transformer: restartable());
    on<MembershipPlanSelected>(_onPlanSelected);
  }

  final MembershipPlanRepository _repository;

  Future<void> _onStarted(
    MembershipPlansStarted event,
    Emitter<MembershipPlansState> emit,
  ) async {
    emit(
      state.copyWith(
        activePlanId: event.activePlanId,
        loadStatus: const ApiState.loading(),
      ),
    );

    try {
      final plans = await asyncHandler(() => _repository.getActive());
      final activeId = event.activePlanId ?? state.activePlanId;
      final selected = _resolveDefaultSelection(plans, activeId);
      emit(
        MembershipPlansState(
          plans: plans,
          selectedPlan: selected,
          activePlanId: activeId,
          loadStatus: const ApiState.success(null),
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          loadStatus: ApiState.failure(e.message, error: e),
        ),
      );
    }
  }

  void _onPlanSelected(
    MembershipPlanSelected event,
    Emitter<MembershipPlansState> emit,
  ) {
    emit(state.copyWith(selectedPlan: event.plan));
  }

  MembershipPlanModel? _resolveDefaultSelection(
    List<MembershipPlanModel> plans,
    String? activeId,
  ) {
    if (plans.isEmpty) return null;
    if (activeId != null && activeId.isNotEmpty) {
      final active = plans.firstWhereOrNull((p) => p.id == activeId);
      if (active != null) return active;
    }
    return plans.firstWhereOrNull((p) => p.isPopular) ?? plans.first;
  }
}

