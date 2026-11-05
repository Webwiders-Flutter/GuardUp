import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
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
  }) = _BodyGuardModel;

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyGuardModelFromJson(json);

  /// Single fake bodyguard instance (Vikram Singh).

  /// Multiple fake bodyguard profiles for lists, search, and rosters.
  static List<BodyGuardModel> get fakeData => [
    BodyGuardModel(
      id: 'guard_vikram_singh',
      user: UserModel(
        id: 'usr_vikram',
        name: 'Vikram Singh',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges,
      availabilities: AvailabilityModel.fakeWeeklySchedule,
      documents: DocumentModel.fakeDocuments,
      hourlyRate: 150.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.vipCloseProtection,
        GuardService.armedEscort,
        GuardService.tacticalDriver,
        GuardService.surveillanceRecon,
      ],
      bio: 'Former Special Forces operative with 12+ years of high-threat dignitary protection, tactical motorcade operations, and counter-surveillance across global metropolitan centers.',
      experienceYears: 12,
      rating: 4.95,
      reviewCount: 142,
      clearanceLevel: 'LEVEL 4 TACTICAL CLEARANCE',
      isVerified: true,
      totalCompletedMissions: 318,
    ),
    BodyGuardModel(
      id: 'guard_david_sterling',
      user: UserModel(
        id: 'usr_david',
        name: 'David Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges
          .take(3)
          .toList(),
      availabilities: AvailabilityModel.fakeWeeklySchedule,
      documents: DocumentModel.fakeDocuments.take(3).toList(),
      hourlyRate: 135.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.vipCloseProtection,
        GuardService.residentialProtection,
        GuardService.eventSecurity,
      ],
      bio: 'Executive security specialist focusing on high-net-worth estate security, airport tarmac escorts, and private jet coordination.',
      experienceYears: 9,
      rating: 4.88,
      reviewCount: 96,
      clearanceLevel: 'LEVEL 3 EXECUTIVE CLEARANCE',
      isVerified: true,
      totalCompletedMissions: 210,
    ),
    BodyGuardModel(
      id: 'guard_marcus_sterling',
      user: UserModel(
        id: 'usr_marcus',
        name: 'Marcus Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges
          .take(2)
          .toList(),
      availabilities: AvailabilityModel.fakeWeeklySchedule,
      documents: DocumentModel.fakeDocuments.take(2).toList(),
      hourlyRate: 120.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.armedEscort,
        GuardService.assetProtection,
        GuardService.crisisManagement,
      ],
      bio: 'High-value bullion and luxury asset courier protection specialist with extensive urban combat and emergency route-clearing background.',
      experienceYears: 7,
      rating: 4.82,
      reviewCount: 74,
      clearanceLevel: 'LEVEL 3 TACTICAL CLEARANCE',
      isVerified: true,
      totalCompletedMissions: 165,
    ),
    BodyGuardModel(
      id: 'guard_carlos_sterling',
      user: UserModel(
        id: 'usr_carlos',
        name: 'Carlos Sterling',
        profileImageUrl: Assets.images.profilePicture2.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges,
      availabilities: AvailabilityModel.fakeWeeklySchedule,
      documents: DocumentModel.fakeDocuments,
      hourlyRate: 160.0,
      currency: 'USD',
      serviceTypes: [
        GuardService.vipCloseProtection,
        GuardService.tacticalDriver,
        GuardService.crisisManagement,
        GuardService.eventSecurity,
      ],
      bio: 'Certified defensive driving instructor and diplomatic security specialist experienced with red-carpet gala security and armored convoy protection.',
      experienceYears: 14,
      rating: 4.97,
      reviewCount: 189,
      clearanceLevel: 'LEVEL 5 STRATEGIC CLEARANCE',
      isVerified: true,
      totalCompletedMissions: 420,
    ),
  ];
}
