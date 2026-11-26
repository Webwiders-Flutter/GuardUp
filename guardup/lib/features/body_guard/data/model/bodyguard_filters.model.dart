import 'package:equatable/equatable.dart';

import '/features/auth/data/enum/gender_type.enum.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '../enum/bodyguard_availability_status.enum.dart';
import '../enum/bodyguard_ownership.enum.dart';

const _sentinel = Object();

/// Filters for bodyguard listings (`BodyguardRepository.getPaginated`).
///
/// Every field is optional; `null` (or an empty list) means "no filter".
/// `copyWith` uses a sentinel so a filter can be cleared back to `null`.
class BodyguardFilters extends Equatable {
  const BodyguardFilters({
    this.statuses,
    this.ownership,
    this.companyId,
    this.availability,
    this.minHourlyRate,
    this.maxHourlyRate,
    this.minRating,
    this.serviceIds,
    this.address,
    this.gender,
  });

  /// What customers browse: ACTIVE solo guards (registered without a company).
  /// Company-managed guards are reached through their company.
  static const customerDefault = BodyguardFilters(
    statuses: [UserStatus.active],
    // availability: BodyguardAvailabilityStatus.available,
  );

  /// Only these verification statuses (`bodyguards.status`).
  final List<UserStatus>? statuses;

  /// Solo (`company_id IS NULL`) or company-managed (`user_id IS NULL`).
  final BodyguardOwnership? ownership;

  /// Only bodyguards of this company (`bodyguards.company_id`).
  final String? companyId;

  /// Only bodyguards with this availability today (`user_availabilities`).
  final BodyguardAvailabilityStatus? availability;

  /// `bodyguards.hourly_rate >= minHourlyRate`.
  final double? minHourlyRate;

  /// `bodyguards.hourly_rate <= maxHourlyRate`.
  final double? maxHourlyRate;

  /// `bodyguards.rating >= minRating`.
  final double? minRating;

  /// Bodyguards offering at least one of these services (`services.id`).
  final List<String>? serviceIds;

  /// Bodyguards whose address contains this string (`bodyguards.address ILIKE %address%`).
  final String? address;

  /// Bodyguards matching this gender (via `gender(public.bodyguards)` computed field).
  final GenderType? gender;

  bool get hasActiveFilters =>
      (statuses?.isNotEmpty ?? false) ||
      ownership != null ||
      companyId != null ||
      availability != null ||
      minHourlyRate != null ||
      maxHourlyRate != null ||
      minRating != null ||
      (serviceIds?.isNotEmpty ?? false) ||
      (address?.trim().isNotEmpty ?? false) ||
      gender != null;

  /// Whether the user has applied any search/filter criteria beyond the
  /// screen's baseline defaults (used to show the active filter dot).
  bool hasUserFilters({
    bool ignoreCompany = false,
    BodyguardAvailabilityStatus? baselineAvailability,
  }) =>
      (!ignoreCompany && companyId != null) ||
      (availability != null && availability != baselineAvailability) ||
      minHourlyRate != null ||
      maxHourlyRate != null ||
      minRating != null ||
      (serviceIds?.isNotEmpty ?? false) ||
      (address?.trim().isNotEmpty ?? false) ||
      gender != null;

  BodyguardFilters copyWith({
    Object? statuses = _sentinel,
    Object? ownership = _sentinel,
    Object? companyId = _sentinel,
    Object? availability = _sentinel,
    Object? minHourlyRate = _sentinel,
    Object? maxHourlyRate = _sentinel,
    Object? minRating = _sentinel,
    Object? serviceIds = _sentinel,
    Object? address = _sentinel,
    Object? gender = _sentinel,
  }) {
    return BodyguardFilters(
      statuses: identical(statuses, _sentinel)
          ? this.statuses
          : statuses as List<UserStatus>?,
      ownership: identical(ownership, _sentinel)
          ? this.ownership
          : ownership as BodyguardOwnership?,
      companyId: identical(companyId, _sentinel)
          ? this.companyId
          : companyId as String?,
      availability: identical(availability, _sentinel)
          ? this.availability
          : availability as BodyguardAvailabilityStatus?,
      minHourlyRate: identical(minHourlyRate, _sentinel)
          ? this.minHourlyRate
          : minHourlyRate as double?,
      maxHourlyRate: identical(maxHourlyRate, _sentinel)
          ? this.maxHourlyRate
          : maxHourlyRate as double?,
      minRating: identical(minRating, _sentinel)
          ? this.minRating
          : minRating as double?,
      serviceIds: identical(serviceIds, _sentinel)
          ? this.serviceIds
          : serviceIds as List<String>?,
      address: identical(address, _sentinel)
          ? this.address
          : address as String?,
      gender: identical(gender, _sentinel)
          ? this.gender
          : gender as GenderType?,
    );
  }

  @override
  List<Object?> get props => [
    statuses,
    ownership,
    companyId,
    availability,
    minHourlyRate,
    maxHourlyRate,
    minRating,
    serviceIds,
    address,
    gender,
  ];
}
