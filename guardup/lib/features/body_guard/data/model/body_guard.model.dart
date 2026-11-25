import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '/features/company/company.dart';
import '../enum/bodyguard_availability_status.enum.dart';
import '../enum/guard_service.enum.dart';
import '../enum/week_day.enum.dart';
import '../../domain/helpers/bodyguard_availability.helper.dart';
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

List<UserDocumentModel>? _userDocumentsFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final item in json)
      if (item is UserDocumentModel)
        item
      else if (item is Map<String, dynamic>)
        UserDocumentModel.fromJson(item),
  ];
}

/// Bodyguard profile (`public.bodyguards`).
///
/// - Self-registered: [userId] is the GUARD account; name, photo, gender, and
///   [status] are copied from that account.
/// - Company-managed: [userId] is null, [companyId] is the managing company.
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
    @Default(0.0) double rating,
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
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Embedded relations
    @JsonKey(fromJson: _servicesFromJson, includeToJson: false)
    List<ServiceItemModel>? services,
    @JsonKey(fromJson: _userDocumentsFromJson, includeToJson: false)
    List<UserDocumentModel>? documents,
    @JsonKey(name: 'user_availabilities', fromJson: _userAvailabilitiesFromJson, includeToJson: false)
    List<UserAvailabilityModel>? userAvailabilities,
  }) = _BodyGuardModel;

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyGuardModelFromJson(json);

  String get displayName =>
      name.isNotEmpty ? name : (user.name.isNotEmpty ? user.name : 'Bodyguard');
  String get displayAvatar => profileImageUrl ?? user.profileImageUrl ?? '';
  String get location =>
      (address?.isNotEmpty == true) ? address! : 'Location not set';

  /// Evaluates dynamic operational availability from [userAvailabilities].
  BodyguardAvailabilityStatus get availabilityStatus =>
      userAvailabilities.evaluateAvailabilityStatus();

  // Backward-compatibility getters for presentation (ensuring zero regressions)
  UserStatus get verificationStatus => status;
  List<UserDocumentModel>? get userDocuments => documents;
  int get reviewCount => 0;
  bool get isVerified => status == UserStatus.active;
  int get totalCompletedMissions => 0;
  String get currency => 'USD';
  BodyguardAvailabilityStatus get operationalStatus => availabilityStatus;
  List<GuardService> get serviceTypes => const [];

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
      userAvailabilities: defaultUserAvailabilities,
      hourlyRate: 60.0,
      bio:
          'Former Special Forces operative with 5+ years of high-threat dignitary protection, tactical motorcade operations, and counter-surveillance across global metropolitan centers.',
      experienceYears: 0,
      rating: 0.0,
      qualifications: 'Certified Close Protection Spec',
      status: UserStatus.active,
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
      userAvailabilities: defaultUserAvailabilities,
      hourlyRate: 85.0,
      bio:
          'High-value bullion and luxury asset courier protection specialist with extensive urban combat and emergency route-clearing background.',
      experienceYears: 0,
      rating: 0.0,
      qualifications: 'Tactical Defensive Driving Spec',
      status: UserStatus.active,
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
      userAvailabilities: defaultUserAvailabilities,
      hourlyRate: 75.0,
      bio:
          'Former intelligence tactical trainer specializing in high-profile celebrity, diplomat, and executive close-quarter protection details.',
      experienceYears: 0,
      rating: 0.0,
      qualifications: 'Executive Protection & Threat Recon',
      status: UserStatus.active,
    ),
  ];
}
