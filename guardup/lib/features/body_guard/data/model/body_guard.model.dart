import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '/features/company/company.dart';
import '../enum/body_guard_status.enum.dart';
import '../enum/bodyguard_availability_status.enum.dart';
import '../enum/guard_service.enum.dart';
import '../enum/week_day.enum.dart';
import 'availability.model.dart';
import 'document.model.dart';
import 'license_and_badge.model.dart';
import 'service_item.model.dart';
import 'user_availability.model.dart';
import 'user_document.model.dart';

part 'body_guard.model.freezed.dart';
part 'body_guard.model.g.dart';

List<ServiceItemModel>? _servicesFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final row in json)
      if (row is Map<String, dynamic>)
        if (row['service'] is Map<String, dynamic>)
          ServiceItemModel.fromJson(row['service'] as Map<String, dynamic>)
        else
          ServiceItemModel.fromJson(row),
  ];
}

UserModel _userFromJson(dynamic json) {
  if (json is UserModel) return json;
  if (json is Map<String, dynamic>) return UserModel.fromJson(json);
  return const UserModel(id: '', name: '');
}

List<UserAvailabilityModel>? _userAvailabilitiesFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final item in json)
      if (item is UserAvailabilityModel)
        item
      else if (item is Map<String, dynamic>)
        UserAvailabilityModel.fromJson(item),
  ];
}

@freezed
abstract class BodyGuardModel with _$BodyGuardModel {
  const BodyGuardModel._();

  const factory BodyGuardModel({
    required String id,
    String? userId,
    String? companyId,
    @Default('') String name,
    String? profileImageUrl,
    @JsonKey(fromJson: _userFromJson, includeToJson: false)
    @Default(UserModel(id: '', name: ''))
    UserModel user,
    @JsonKey(includeToJson: false) CompanyModel? company,
    @Default(0.0) double hourlyRate,
    @Default(5.0) double rating,
    @Default(0) int experienceYears,
    @Default('') String bio,
    String? languages,
    String? certifications,
    String? qualifications,
    String? serviceArea,
    String? address,
    double? latitude,
    double? longitude,
    @Default(true) bool isActive,
    @Default(BodyGuardStatus.availableToday)
    @JsonKey(unknownEnumValue: BodyGuardStatus.availableToday)
    BodyGuardStatus status,
    @Default(UserStatus.active)
    @JsonKey(unknownEnumValue: UserStatus.active)
    UserStatus verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Embedded relations
    @JsonKey(fromJson: _servicesFromJson, includeToJson: false)
    List<ServiceItemModel>? services,
    @JsonKey(includeToJson: false) List<UserDocumentModel>? userDocuments,
    @JsonKey(name: 'user_availabilities', fromJson: _userAvailabilitiesFromJson, includeToJson: false)
    List<UserAvailabilityModel>? userAvailabilities,

    // Backwards-compatibility fields for UI components
    @JsonKey(includeToJson: false)
    @Default([]) List<LicenseAndBadgeModel> licensesAndBadges,
    @JsonKey(includeToJson: false)
    @Default([]) List<AvailabilityModel> availabilities,
    @JsonKey(includeToJson: false)
    @Default([]) List<DocumentModel> documents,
    @Default('USD') String currency,
    @JsonKey(includeToJson: false)
    @Default([]) List<GuardService> serviceTypes,
    @Default(0) int reviewCount,
    @Default(false) bool isVerified,
    @Default(0) int totalCompletedMissions,
    @Default(BodyGuardStatus.availableToday)
    @JsonKey(unknownEnumValue: BodyGuardStatus.availableToday)
    BodyGuardStatus operationalStatus,
  }) = _BodyGuardModel;

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyGuardModelFromJson(json);

  String get displayName => name.isNotEmpty ? name : (user.name.isNotEmpty ? user.name : 'Bodyguard');
  String get displayAvatar => profileImageUrl ?? user.profileImageUrl ?? '';
  String get location => (address?.isNotEmpty == true) ? address! : 'Location not set';

  /// Evaluates dynamic operational availability from [userAvailabilities].
  BodyguardAvailabilityStatus get availabilityStatus {
    final slots = userAvailabilities;
    if (slots == null || slots.isEmpty) {
      return BodyguardAvailabilityStatus.notSet;
    }

    final now = DateTime.now();
    final todaySlot = slots
        .where((s) => s.dayOfWeek?.weekdayNumber == now.weekday)
        .firstOrNull;

    if (todaySlot == null || !todaySlot.isAvailable) {
      return BodyguardAvailabilityStatus.notAvailable;
    }

    return todaySlot.isAvailableAt(now)
        ? BodyguardAvailabilityStatus.available
        : BodyguardAvailabilityStatus.notAvailable;
  }

  /// Default 7-day schedule for previews and fake models.
  static List<UserAvailabilityModel> get defaultUserAvailabilities => [
    for (final day in WeekDay.values)
      UserAvailabilityModel(
        id: 'avail_${day.name}',
        dayOfWeek: day,
        isAvailable: true,
        fromTime: '08:00 AM',
        toTime: '10:00 PM',
      ),
  ];

  /// Curated fake bodyguard profiles for lists, search, and rosters.
  static List<BodyGuardModel> get fakeData => [
    BodyGuardModel(
      id: 'guard_vikram_singh',
      name: 'Vikram Singh',
      user: const UserModel(
        id: 'usr_vikram',
        name: 'Vikram Singh',
        role: UserRole.guard,
      ),
      company: CompanyModel.fakeData.first,
      licensesAndBadges: LicenseAndBadgeModel.fakeData,
      availabilities: AvailabilityModel.fakeData,
      userAvailabilities: defaultUserAvailabilities,
      documents: DocumentModel.fakeData,
      hourlyRate: 60.0,
      currency: 'USD',
      serviceTypes: const [
        GuardService.armedEscort,
        GuardService.tacticalDriver,
        GuardService.vipCloseProtection,
      ],
      bio: 'Former Special Forces operative with 5+ years of high-threat dignitary protection, tactical motorcade operations, and counter-surveillance across global metropolitan centers.',
      experienceYears: 5,
      rating: 4.9,
      reviewCount: 128,
      qualifications: 'Certified Close Protection Spec',
      isVerified: true,
      totalCompletedMissions: 318,
      status: BodyGuardStatus.availableToday,
      verificationStatus: UserStatus.active,
    ),
    BodyGuardModel(
      id: 'guard_marcus_sterling',
      name: 'Marcus Sterling',
      user: const UserModel(
        id: 'usr_marcus',
        name: 'Marcus Sterling',
        role: UserRole.guard,
      ),
      company: CompanyModel.fakeData[1],
      licensesAndBadges: LicenseAndBadgeModel.fakeData.take(2).toList(),
      availabilities: AvailabilityModel.fakeData,
      userAvailabilities: defaultUserAvailabilities,
      documents: DocumentModel.fakeData.take(2).toList(),
      hourlyRate: 85.0,
      currency: 'USD',
      serviceTypes: const [GuardService.armedEscort, GuardService.assetProtection],
      bio: 'High-value bullion and luxury asset courier protection specialist with extensive urban combat and emergency route-clearing background.',
      experienceYears: 8,
      rating: 4.95,
      reviewCount: 214,
      qualifications: 'Tactical Defensive Driving Spec',
      isVerified: true,
      totalCompletedMissions: 210,
      status: BodyGuardStatus.availableToday,
      verificationStatus: UserStatus.active,
    ),
    BodyGuardModel(
      id: 'guard_elena_rostova',
      name: 'Elena Rostova',
      user: const UserModel(
        id: 'usr_elena',
        name: 'Elena Rostova',
        role: UserRole.guard,
      ),
      company: CompanyModel.fakeData[2],
      licensesAndBadges: LicenseAndBadgeModel.fakeData,
      availabilities: AvailabilityModel.fakeData,
      userAvailabilities: defaultUserAvailabilities,
      documents: DocumentModel.fakeData,
      hourlyRate: 75.0,
      currency: 'USD',
      serviceTypes: const [
        GuardService.vipCloseProtection,
        GuardService.eventSecurity,
      ],
      bio: 'Former intelligence tactical trainer specializing in high-profile celebrity, diplomat, and executive close-quarter protection details.',
      experienceYears: 6,
      rating: 4.88,
      reviewCount: 176,
      qualifications: 'Executive Protection & Threat Recon',
      isVerified: true,
      totalCompletedMissions: 195,
      status: BodyGuardStatus.availableToday,
      verificationStatus: UserStatus.active,
    ),
  ];
}
