import 'package:equatable/equatable.dart';

import '../../data/model/membership_plan.model.dart';

abstract class MembershipPlansEvent extends Equatable {
  const MembershipPlansEvent();

  @override
  List<Object?> get props => [];
}

/// Loads active membership plans and selects the default/active plan.
final class MembershipPlansStarted extends MembershipPlansEvent {
  const MembershipPlansStarted({this.activePlanId});

  final String? activePlanId;

  @override
  List<Object?> get props => [activePlanId];
}

/// Selects a membership plan card.
final class MembershipPlanSelected extends MembershipPlansEvent {
  const MembershipPlanSelected(this.plan);

  final MembershipPlanModel plan;

  @override
  List<Object?> get props => [plan];
}
