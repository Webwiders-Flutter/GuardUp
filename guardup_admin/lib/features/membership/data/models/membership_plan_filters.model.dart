import 'package:flutter/foundation.dart';

const _sentinel = Object();

@immutable
class MembershipPlanFilters {
  final bool? isActive;

  const MembershipPlanFilters({this.isActive});

  bool get hasActiveFilters => isActive != null;

  MembershipPlanFilters copyWith({Object? isActive = _sentinel}) {
    return MembershipPlanFilters(
      isActive: identical(isActive, _sentinel)
          ? this.isActive
          : isActive as bool?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MembershipPlanFilters &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive;

  @override
  int get hashCode => isActive.hashCode;
}
