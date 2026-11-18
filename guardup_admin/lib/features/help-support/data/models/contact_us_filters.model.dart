import 'package:flutter/foundation.dart';

import '/features/help-support/data/enums/contact_us_status.enum.dart';
import '/features/users/data/enums/user_role.enum.dart';

const _sentinel = Object();

@immutable
class ContactUsFilters {
  final ContactUsStatus? status;
  final UserRoleType? role;

  const ContactUsFilters({this.status, this.role});

  bool get hasActiveFilters => status != null || role != null;

  ContactUsFilters copyWith({
    Object? status = _sentinel,
    Object? role = _sentinel,
  }) {
    return ContactUsFilters(
      status: identical(status, _sentinel)
          ? this.status
          : status as ContactUsStatus?,
      role: identical(role, _sentinel) ? this.role : role as UserRoleType?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactUsFilters &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          role == other.role;

  @override
  int get hashCode => Object.hash(status, role);
}
