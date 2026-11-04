import '/features/auth/auth.dart';
import '/gen/assets.gen.dart';
import '../enum/guard_service.enum.dart';
import 'availability.model.dart';
import 'document.model.dart';
import 'license_and_badge.model.dart';

/// Comprehensive operational profile for an elite bodyguard.
class BodyGuardModel {
  final String id;
  final UserModel user;
  final List<LicenseAndBadgeModel> licensesAndBadges;
  final List<AvailabilityModel> availabilities;
  final List<DocumentModel> documents;
  final double hourlyRate;
  final String currency;
  final List<GuardService> serviceTypes;
  final String bio;
  final int experienceYears;
  final double rating;
  final int reviewCount;
  final String? clearanceLevel;
  final bool isVerified;
  final int totalCompletedMissions;

  const BodyGuardModel({
    required this.id,
    required this.user,
    this.licensesAndBadges = const [],
    this.availabilities = const [],
    this.documents = const [],
    required this.hourlyRate,
    this.currency = 'USD',
    this.serviceTypes = const [],
    required this.bio,
    this.experienceYears = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.clearanceLevel,
    this.isVerified = false,
    this.totalCompletedMissions = 0,
  });

  /// Formatted hourly rate string (e.g. "$120 / hr").
  String get formattedHourlyRate {
    final isInt = hourlyRate.truncateToDouble() == hourlyRate;
    final rateStr = isInt ? hourlyRate.toInt().toString() : hourlyRate.toStringAsFixed(2);
    return '\$$rateStr $currency / hr';
  }

  /// Display rating string (e.g. "4.9 (128 reviews)").
  String get formattedRating => '${rating.toStringAsFixed(1)} ($reviewCount reviews)';

  BodyGuardModel copyWith({
    String? id,
    UserModel? user,
    List<LicenseAndBadgeModel>? licensesAndBadges,
    List<AvailabilityModel>? availabilities,
    List<DocumentModel>? documents,
    double? hourlyRate,
    String? currency,
    List<GuardService>? serviceTypes,
    String? bio,
    int? experienceYears,
    double? rating,
    int? reviewCount,
    String? clearanceLevel,
    bool? isVerified,
    int? totalCompletedMissions,
  }) {
    return BodyGuardModel(
      id: id ?? this.id,
      user: user ?? this.user,
      licensesAndBadges: licensesAndBadges ?? this.licensesAndBadges,
      availabilities: availabilities ?? this.availabilities,
      documents: documents ?? this.documents,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      currency: currency ?? this.currency,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      bio: bio ?? this.bio,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      clearanceLevel: clearanceLevel ?? this.clearanceLevel,
      isVerified: isVerified ?? this.isVerified,
      totalCompletedMissions: totalCompletedMissions ?? this.totalCompletedMissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'licensesAndBadges': licensesAndBadges.map((e) => e.toJson()).toList(),
      'availabilities': availabilities.map((e) => e.toJson()).toList(),
      'documents': documents.map((e) => e.toJson()).toList(),
      'hourlyRate': hourlyRate,
      'currency': currency,
      'serviceTypes': serviceTypes.map((e) => e.apiValue).toList(),
      'bio': bio,
      'experienceYears': experienceYears,
      'rating': rating,
      'reviewCount': reviewCount,
      if (clearanceLevel != null) 'clearanceLevel': clearanceLevel,
      'isVerified': isVerified,
      'totalCompletedMissions': totalCompletedMissions,
    };
  }

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) {
    return BodyGuardModel(
      id: json['id'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      licensesAndBadges: (json['licensesAndBadges'] as List<dynamic>?)
              ?.map((e) => LicenseAndBadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      availabilities: (json['availabilities'] as List<dynamic>?)
              ?.map((e) => AvailabilityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      serviceTypes: (json['serviceTypes'] as List<dynamic>?)
              ?.map((e) => GuardService.fromApiValue(e as String?))
              .toList() ??
          const [],
      bio: json['bio'] as String? ?? '',
      experienceYears: json['experienceYears'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      clearanceLevel: json['clearanceLevel'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      totalCompletedMissions: json['totalCompletedMissions'] as int? ?? 0,
    );
  }

  /// Single fake bodyguard instance (Vikram Singh).
  static BodyGuardModel get fakeBodyGuard => BodyGuardModel(
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
  );

  /// Multiple fake bodyguard profiles for lists, search, and rosters.
  static List<BodyGuardModel> get fakeData => [
    fakeBodyGuard,
    BodyGuardModel(
      id: 'guard_david_sterling',
      user: UserModel(
        id: 'usr_david',
        name: 'David Sterling',
        profileImageUrl: Assets.images.profilePicture.path,
        role: UserRole.guard,
      ),
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges.take(3).toList(),
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
      licensesAndBadges: LicenseAndBadgeModel.fakeLicensesAndBadges.take(2).toList(),
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

