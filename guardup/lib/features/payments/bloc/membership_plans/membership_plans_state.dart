import 'package:equatable/equatable.dart';

import '/core/state/api_state.dart';
import '../../data/model/membership_plan.model.dart';

class MembershipPlansState extends Equatable {
  const MembershipPlansState({
    this.plans = const [],
    this.selectedPlan,
    this.activePlanId,
    this.loadStatus = const ApiState.initial(),
  });

  final List<MembershipPlanModel> plans;
  final MembershipPlanModel? selectedPlan;
  final String? activePlanId;
  final ApiState<void> loadStatus;

  MembershipPlansState copyWith({
    List<MembershipPlanModel>? plans,
    MembershipPlanModel? selectedPlan,
    String? activePlanId,
    ApiState<void>? loadStatus,
  }) {
    return MembershipPlansState(
      plans: plans ?? this.plans,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      activePlanId: activePlanId ?? this.activePlanId,
      loadStatus: loadStatus ?? this.loadStatus,
    );
  }

  @override
  List<Object?> get props => [plans, selectedPlan, activePlanId, loadStatus];
}

