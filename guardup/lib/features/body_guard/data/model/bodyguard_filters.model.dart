import 'package:equatable/equatable.dart';

import '/features/auth/data/enum/user_status.enum.dart';
import '../enum/bodyguard_availability_status.enum.dart';

const _sentinel = Object();

/// Filters for bodyguard listings (`BodyguardRepository.getPaginated`).
///
/// `copyWith` uses a sentinel so a filter can be cleared back to `null`.
class BodyguardFilters extends Equatable {
  const BodyguardFilters({this.companyId, this.statuses, this.availability});

  /// Only bodyguards of this company (`bodyguards.company_id`).
  final String? companyId;

  /// Only these verification statuses (`bodyguards.status`).
  final List<UserStatus>? statuses;

  /// Only bodyguards with this availability today.
  final BodyguardAvailabilityStatus? availability;

  bool get hasActiveFilters =>
      companyId != null ||
      (statuses?.isNotEmpty ?? false) ||
      availability != null;

  BodyguardFilters copyWith({
    Object? companyId = _sentinel,
    Object? statuses = _sentinel,
    Object? availability = _sentinel,
  }) {
    return BodyguardFilters(
      companyId: identical(companyId, _sentinel)
          ? this.companyId
          : companyId as String?,
      statuses: identical(statuses, _sentinel)
          ? this.statuses
          : statuses as List<UserStatus>?,
      availability: identical(availability, _sentinel)
          ? this.availability
          : availability as BodyguardAvailabilityStatus?,
    );
  }

  @override
  List<Object?> get props => [companyId, statuses, availability];
}
