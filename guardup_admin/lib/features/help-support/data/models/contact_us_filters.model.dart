import 'package:flutter/foundation.dart';

import '../../../users/data/enums/user_role.enum.dart';

const _sentinel = Object();

@immutable
class ContactUsFilters {
  final bool? isResolved;
  final UserRoleType? role;

  const ContactUsFilters({this.isResolved, this.role});

  bool get hasActiveFilters => isResolved != null || role != null;

  ContactUsFilters copyWith({
    Object? isResolved = _sentinel,
    Object? role = _sentinel,
  }) {
    return ContactUsFilters(
      isResolved: identical(isResolved, _sentinel)
          ? this.isResolved
          : isResolved as bool?,
      role: identical(role, _sentinel) ? this.role : role as UserRoleType?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactUsFilters &&
          runtimeType == other.runtimeType &&
          isResolved == other.isResolved &&
          role == other.role;

  @override
  int get hashCode => Object.hash(isResolved, role);
}
