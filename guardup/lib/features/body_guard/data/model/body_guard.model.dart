import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '../enum/body_guard_status.enum.dart';
import '../enum/guard_service.enum.dart';
import 'availability.model.dart';
import 'document.model.dart';
import 'license_and_badge.model.dart';

part 'body_guard.model.freezed.dart';
part 'body_guard.model.g.dart';

/// Comprehensive operational profile for an elite bodyguard.
@freezed
abstract class BodyGuardModel with _$BodyGuardModel {
  const factory BodyGuardModel({
    required String id,
    required UserModel user,
    @Default([]) List<LicenseAndBadgeModel> licensesAndBadges,
    @Default([]) List<AvailabilityModel> availabilities,
    @Default([]) List<DocumentModel> documents,
    required double hourlyRate,
    @Default('USD') String currency,
    @Default([]) List<GuardService> serviceTypes,
    required String bio,
    @Default(0) int experienceYears,
    @Default(5.0) double rating,
    @Default(0) int reviewCount,
    String? clearanceLevel,
    @Default(false) bool isVerified,
    @Default(0) int totalCompletedMissions,
    @Default(BodyGuardStatus.availableToday) BodyGuardStatus status,

    /// Admin verification (`bodyguards.status`). Only ACTIVE bodyguards are
    /// shown to customers; a company sees the others with their state.
    @Default(UserStatus.active) UserStatus verificationStatus,

    /// Why the admin rejected this bodyguard (`bodyguards.rejection_reason`).
    String? rejectionReason,
  }) = _BodyGuardModel;

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyGuardModelFromJson(json);

  /// Curated fake bodyguard profiles for lists, search, and rosters.
  static List<BodyGuardModel> get fakeData => [
    BodyGuardModel(
      id: 'guard_vikram_singh',
      user: UserModel(
        id: 'usr_vikram',
        name: 'Vikram Singh',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeData,
      availabilities: AvailabilityModel.fakeData,
      documents: DocumentModel.fakeData,
      hourlyRate: 60.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.armedEscort,
        GuardService.tacticalDriver,
        GuardService.vipCloseProtection,
      ],
      bio: 'Former Special Forces operative with 5+ years of high-threat dignitary protection, tactical motorcade operations, and counter-surveillance across global metropolitan centers.',
      experienceYears: 5,
      rating: 4.9,
      reviewCount: 128,
      clearanceLevel: 'Licensed armed, Corporate visits',
      isVerified: true,
      totalCompletedMissions: 318,
      status: BodyGuardStatus.availableToday,
    ),
    BodyGuardModel(
      id: 'guard_marcus_sterling',
      user: UserModel(
        id: 'usr_marcus',
        name: 'Marcus Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeData
          .take(2)
          .toList(),
      availabilities: AvailabilityModel.fakeData,
      documents: DocumentModel.fakeData.take(2).toList(),
      hourlyRate: 85.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.armedEscort,
        GuardService.assetProtection,
      ],
      bio: 'High-value bullion and luxury asset courier protection specialist with extensive urban combat and emergency route-clearing background.',
      experienceYears: 8,
      rating: 4.95,
      reviewCount: 214,
      clearanceLevel: 'Licensed armed, Corporate visits',
      isVerified: true,
      totalCompletedMissions: 210,
      status: BodyGuardStatus.availableNow,
    ),
    BodyGuardModel(
      id: 'guard_elena_rostova',
      user: UserModel(
        id: 'usr_elena',
        name: 'Elena Rostova',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeData,
      availabilities: AvailabilityModel.fakeData,
      documents: DocumentModel.fakeData,
      hourlyRate: 75.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.vipCloseProtection,
        GuardService.crisisManagement,
      ],
      bio: 'Diplomatic security specialist experienced with red-carpet gala security and armored convoy protection.',
      experienceYears: 6,
      rating: 4.92,
      reviewCount: 95,
      clearanceLevel: 'Licensed armed, Corporate visits',
      isVerified: true,
      totalCompletedMissions: 165,
      status: BodyGuardStatus.availableToday,
    ),
    BodyGuardModel(
      id: 'guard_david_vance',
      user: UserModel(
        id: 'usr_david_vance',
        name: 'David Vance',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeData
          .take(3)
          .toList(),
      availabilities: AvailabilityModel.fakeData,
      documents: DocumentModel.fakeData.take(3).toList(),
      hourlyRate: 65.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.vipCloseProtection,
        GuardService.residentialProtection,
      ],
      bio: 'Executive security specialist focusing on high-net-worth estate security, airport tarmac escorts, and private jet coordination.',
      experienceYears: 4,
      rating: 4.88,
      reviewCount: 76,
      clearanceLevel: 'Licensed armed, Corporate visits',
      isVerified: true,
      totalCompletedMissions: 98,
      status: BodyGuardStatus.availableTomorrow,
    ),
  ];
}
