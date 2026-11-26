import 'package:equatable/equatable.dart';

import '/features/auth/data/enum/user_status.enum.dart';

const _sentinel = Object();

/// Filters for company listings (`CompanyRepository.getPaginated`).
class CompanyFilters extends Equatable {
  const CompanyFilters({this.statuses});

  /// Customers only see companies whose account is ACTIVE.
  static const customerDefault = CompanyFilters(statuses: [UserStatus.active]);

  /// Only companies whose account (`users.status`) has one of these statuses.
  /// Applied through the `account_status` computed field, because customers
  /// cannot read `users` directly.
  final List<UserStatus>? statuses;

  bool get hasActiveFilters => statuses?.isNotEmpty ?? false;

  CompanyFilters copyWith({Object? statuses = _sentinel}) {
    return CompanyFilters(
      statuses: identical(statuses, _sentinel)
          ? this.statuses
          : statuses as List<UserStatus>?,
    );
  }

  @override
  List<Object?> get props => [statuses];
}
