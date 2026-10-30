import 'package:guardup/core/utils/extensions/datetime_extensions.dart';

class UserEntity {
  final String id;
  final String email;
  final String? name;
  final String? profileImage;
  final String? phone;
  final String? phoneCode;
  final String? countryCode;
  final String? bio;
  final bool isVerified;
  final bool isPhoneVerified;
  final String? createdAt;
  final List<String> interests;
  final List<String> preferredDestinations;

  // Study Profile Fields – text (display / fallback)
  final String? degree;
  final String? preferredCountry;
  final String? preferredField;
  final String? preferredSpecialisation;
  final String? targetIntake;
  final String? studyGoals;
  final List<String> otherPreferredCountries;

  // Study Profile Fields – Bilingual
  final String? degreeEn;
  final String? degreeAr;
  final String? preferredCountryEn;
  final String? preferredCountryAr;
  final String? preferredFieldEn;
  final String? preferredFieldAr;
  final String? preferredSpecialisationEn;
  final String? preferredSpecialisationAr;
  final String? targetIntakeEn;
  final String? targetIntakeAr;
  final List<String> otherPreferredCountriesEn;
  final List<String> otherPreferredCountriesAr;

  // Study Profile Fields – IDs (structured)
  final int? degreeId; // FK → program_categories.id
  final int? preferredCountryId; // FK → countries.id
  final List<int> otherPreferredCountryIds; // FK[] → countries.id

  // Social Metrics
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.profileImage,
    this.phone,
    this.phoneCode,
    this.countryCode,
    this.bio,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.interests = const [],
    this.preferredDestinations = const [],
    this.degree,
    this.preferredCountry,
    this.preferredField,
    this.preferredSpecialisation,
    this.targetIntake,
    this.studyGoals,
    this.otherPreferredCountries = const [],
    this.degreeEn,
    this.degreeAr,
    this.preferredCountryEn,
    this.preferredCountryAr,
    this.preferredFieldEn,
    this.preferredFieldAr,
    this.preferredSpecialisationEn,
    this.preferredSpecialisationAr,
    this.targetIntakeEn,
    this.targetIntakeAr,
    this.otherPreferredCountriesEn = const [],
    this.otherPreferredCountriesAr = const [],
    this.degreeId,
    this.preferredCountryId,
    this.otherPreferredCountryIds = const [],
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? profileImage,
    String? phone,
    String? phoneCode,
    String? countryCode,
    String? bio,
    bool? isVerified,
    bool? isPhoneVerified,
    String? createdAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<String>? interests,
    List<String>? preferredDestinations,
    String? degree,
    String? preferredCountry,
    String? preferredField,
    String? preferredSpecialisation,
    String? targetIntake,
    String? studyGoals,
    List<String>? otherPreferredCountries,
    String? degreeEn,
    String? degreeAr,
    String? preferredCountryEn,
    String? preferredCountryAr,
    String? preferredFieldEn,
    String? preferredFieldAr,
    String? preferredSpecialisationEn,
    String? preferredSpecialisationAr,
    String? targetIntakeEn,
    String? targetIntakeAr,
    List<String>? otherPreferredCountriesEn,
    List<String>? otherPreferredCountriesAr,
    int? degreeId,
    int? preferredCountryId,
    List<int>? otherPreferredCountryIds,
    bool clearDegreeId = false,
    bool clearPreferredCountryId = false,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      phoneCode: phoneCode ?? this.phoneCode,
      countryCode: countryCode ?? this.countryCode,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      interests: interests ?? this.interests,
      preferredDestinations:
          preferredDestinations ?? this.preferredDestinations,
      degree: degree ?? this.degree,
      preferredCountry: preferredCountry ?? this.preferredCountry,
      preferredField: preferredField ?? this.preferredField,
      preferredSpecialisation:
          preferredSpecialisation ?? this.preferredSpecialisation,
      targetIntake: targetIntake ?? this.targetIntake,
      studyGoals: studyGoals ?? this.studyGoals,
      otherPreferredCountries:
          otherPreferredCountries ?? this.otherPreferredCountries,
      degreeEn: degreeEn ?? this.degreeEn,
      degreeAr: degreeAr ?? this.degreeAr,
      preferredCountryEn: preferredCountryEn ?? this.preferredCountryEn,
      preferredCountryAr: preferredCountryAr ?? this.preferredCountryAr,
      preferredFieldEn: preferredFieldEn ?? this.preferredFieldEn,
      preferredFieldAr: preferredFieldAr ?? this.preferredFieldAr,
      preferredSpecialisationEn:
          preferredSpecialisationEn ?? this.preferredSpecialisationEn,
      preferredSpecialisationAr:
          preferredSpecialisationAr ?? this.preferredSpecialisationAr,
      targetIntakeEn: targetIntakeEn ?? this.targetIntakeEn,
      targetIntakeAr: targetIntakeAr ?? this.targetIntakeAr,
      otherPreferredCountriesEn:
          otherPreferredCountriesEn ?? this.otherPreferredCountriesEn,
      otherPreferredCountriesAr:
          otherPreferredCountriesAr ?? this.otherPreferredCountriesAr,
      degreeId: clearDegreeId ? null : (degreeId ?? this.degreeId),
      preferredCountryId: clearPreferredCountryId
          ? null
          : (preferredCountryId ?? this.preferredCountryId),
      otherPreferredCountryIds:
          otherPreferredCountryIds ?? this.otherPreferredCountryIds,
    );
  }

  int get studyProfileCompletionPercentage {
    int filled = 0;
    const total = 7;
    if ((degree != null && degree!.trim().isNotEmpty) ||
        degreeEn != null ||
        degreeAr != null) {
      filled++;
    }
    if ((preferredCountry != null && preferredCountry!.trim().isNotEmpty) ||
        preferredCountryEn != null ||
        preferredCountryAr != null) {
      filled++;
    }
    if ((preferredField != null && preferredField!.trim().isNotEmpty) ||
        preferredFieldEn != null ||
        preferredFieldAr != null) {
      filled++;
    }
    if ((preferredSpecialisation != null &&
            preferredSpecialisation!.trim().isNotEmpty) ||
        preferredSpecialisationEn != null ||
        preferredSpecialisationAr != null) {
      filled++;
    }
    if ((targetIntake != null && targetIntake!.trim().isNotEmpty) ||
        targetIntakeEn != null ||
        targetIntakeAr != null) {
      filled++;
    }
    if (studyGoals != null && studyGoals!.trim().isNotEmpty) filled++;
    if (otherPreferredCountries.isNotEmpty ||
        otherPreferredCountryIds.isNotEmpty ||
        otherPreferredCountriesEn.isNotEmpty) {
      filled++;
    }
    return ((filled / total) * 100).round();
  }

  bool get isStudyProfileComplete => studyProfileCompletionPercentage == 100;

  String get formattedMemberSince {
    try {
      if (createdAt == null) return '';
      final date = DateTime.parse(createdAt!);
      return date.memberSince;
    } catch (_) {
      return '';
    }
  }

  static const empty = UserEntity(id: '', email: '');

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;
}
