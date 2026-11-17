import 'package:flutter/foundation.dart';

import '../../../users/data/enums/user_role.enum.dart';

const _sentinel = Object();

@immutable
class FaqFilters {
  final bool? isActive;
  final UserRoleType? role;

  const FaqFilters({this.isActive, this.role});

  bool get hasActiveFilters => isActive != null || role != null;

  FaqFilters copyWith({
    Object? isActive = _sentinel,
    Object? role = _sentinel,
  }) {
    return FaqFilters(
      isActive: identical(isActive, _sentinel)
          ? this.isActive
          : isActive as bool?,
      role: identical(role, _sentinel) ? this.role : role as UserRoleType?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaqFilters &&
          runtimeType == other.runtimeType &&
          isActive == other.isActive &&
          role == other.role;

  @override
  int get hashCode => Object.hash(isActive, role);
}
