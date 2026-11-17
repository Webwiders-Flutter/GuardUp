import 'package:flutter/foundation.dart';

import '/features/users/data/enums/user_role.enum.dart';

const _sentinel = Object();

@immutable
class DocumentTypeFilters {
  final UserRoleType? targetRole;
  final bool? isActive;

  const DocumentTypeFilters({this.targetRole, this.isActive});

  bool get hasActiveFilters => targetRole != null || isActive != null;

  DocumentTypeFilters copyWith({
    Object? targetRole = _sentinel,
    Object? isActive = _sentinel,
  }) {
    return DocumentTypeFilters(
      targetRole: identical(targetRole, _sentinel)
          ? this.targetRole
          : targetRole as UserRoleType?,
      isActive: identical(isActive, _sentinel)
          ? this.isActive
          : isActive as bool?,
    );
  }

  /// Whether [targetRole] and [isActive] of a record match these filters.
  bool matches({required UserRoleType targetRole, required bool isActive}) {
    if (this.targetRole != null && this.targetRole != targetRole) return false;
    if (this.isActive != null && this.isActive != isActive) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTypeFilters &&
          runtimeType == other.runtimeType &&
          targetRole == other.targetRole &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(targetRole, isActive);
}
