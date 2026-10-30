import 'package:guardup/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.profileImage,
    super.phone,
    super.phoneCode,
    super.countryCode,
    super.bio,
    super.isVerified,
    super.isPhoneVerified,
    super.createdAt,
    super.followersCount,
    super.followingCount,
    super.postsCount,
    super.interests,
    super.preferredDestinations,
    super.degree,
    super.preferredCountry,
    super.preferredField,
    super.preferredSpecialisation,
    super.targetIntake,
    super.studyGoals,
    super.otherPreferredCountries,
    super.degreeEn,
    super.degreeAr,
    super.preferredCountryEn,
    super.preferredCountryAr,
    super.preferredFieldEn,
    super.preferredFieldAr,
    super.preferredSpecialisationEn,
    super.preferredSpecialisationAr,
    super.targetIntakeEn,
    super.targetIntakeAr,
    super.otherPreferredCountriesEn,
    super.otherPreferredCountriesAr,
    super.degreeId,
    super.preferredCountryId,
    super.otherPreferredCountryIds,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name'] as String?,
      profileImage: json['profile_image'] as String?,
      phone: json['phone'] as String?,
      phoneCode: json['phone_code'] as String?,
      countryCode: json['country_code'] as String?,
      isPhoneVerified:
          json['phone'] != null && json['phone'].toString().isNotEmpty,
      bio: json['bio'] as String?,
      isVerified: json['status'] == 1,
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString(),
      followersCount: _parseSocialProfileMetric(json, 'followers_count'),
      followingCount: _parseSocialProfileMetric(json, 'following_count'),
      postsCount: _parseSocialProfileMetric(json, 'posts_count'),
      interests: _parseSocialProfileListString(json, 'interests'),
      preferredDestinations: _parseSocialProfileListString(
        json,
        'preferred_destinations',
      ),
      // Text fields (legacy / display fallback)
      degree: _parseSocialProfileString(json, 'degree'),
      preferredCountry: _parseSocialProfileString(json, 'preferred_country'),
      preferredField: _parseSocialProfileString(json, 'preferred_field'),
      preferredSpecialisation: _parseSocialProfileString(
        json,
        'preferred_specialisation',
      ),
      targetIntake: _parseSocialProfileString(json, 'target_intake'),
      studyGoals: _parseSocialProfileString(json, 'study_goals'),
      otherPreferredCountries: _parseSocialProfileListString(
        json,
        'other_preferred_countries',
      ),
      // Bilingual fields
      degreeEn: _parseSocialProfileString(json, 'degree_en'),
      degreeAr: _parseSocialProfileString(json, 'degree_ar'),
      preferredCountryEn: _parseSocialProfileString(
        json,
        'preferred_country_en',
      ),
      preferredCountryAr: _parseSocialProfileString(
        json,
        'preferred_country_ar',
      ),
      preferredFieldEn: _parseSocialProfileString(json, 'preferred_field_en'),
      preferredFieldAr: _parseSocialProfileString(json, 'preferred_field_ar'),
      preferredSpecialisationEn: _parseSocialProfileString(
        json,
        'preferred_specialisation_en',
      ),
      preferredSpecialisationAr: _parseSocialProfileString(
        json,
        'preferred_specialisation_ar',
      ),
      targetIntakeEn: _parseSocialProfileString(json, 'target_intake_en'),
      targetIntakeAr: _parseSocialProfileString(json, 'target_intake_ar'),
      otherPreferredCountriesEn: _parseSocialProfileListString(
        json,
        'other_preferred_countries_en',
      ),
      otherPreferredCountriesAr: _parseSocialProfileListString(
        json,
        'other_preferred_countries_ar',
      ),
      // ID fields (structured)
      degreeId: _parseSocialProfileInt(json, 'degree_id'),
      preferredCountryId: _parseSocialProfileInt(json, 'preferred_country_id'),
      otherPreferredCountryIds: _parseSocialProfileListInt(
        json,
        'other_preferred_country_ids',
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers – read from user_social_profiles nested join or flat JSON
  // ──────────────────────────────────────────────────────────────────

  static String? _parseSocialProfileString(
    Map<String, dynamic> json,
    String key,
  ) {
    final profile = json['user_social_profiles'];
    if (profile is List && profile.isNotEmpty) {
      final val = profile.first[key];
      if (val != null) return val.toString();
    } else if (profile is Map) {
      final val = profile[key];
      if (val != null) return val.toString();
    }
    return json[key]?.toString();
  }

  static int? _parseSocialProfileInt(Map<String, dynamic> json, String key) {
    final profile = json['user_social_profiles'];
    if (profile is List && profile.isNotEmpty) {
      final val = profile.first[key];
      if (val != null) return int.tryParse(val.toString());
    } else if (profile is Map) {
      final val = profile[key];
      if (val != null) return int.tryParse(val.toString());
    }
    final flat = json[key];
    if (flat != null) return int.tryParse(flat.toString());
    return null;
  }

  static int _parseSocialProfileMetric(Map<String, dynamic> json, String key) {
    final profile = json['user_social_profiles'];
    if (profile is List && profile.isNotEmpty) {
      return profile.first[key] as int? ?? 0;
    } else if (profile is Map) {
      return profile[key] as int? ?? 0;
    }
    return json[key] as int? ?? 0;
  }

  static List<String> _parseSocialProfileListString(
    Map<String, dynamic> json,
    String key,
  ) {
    final profile = json['user_social_profiles'];
    if (profile is List && profile.isNotEmpty) {
      final list = profile.first[key];
      if (list is List) return list.map((e) => e.toString()).toList();
    } else if (profile is Map) {
      final list = profile[key];
      if (list is List) return list.map((e) => e.toString()).toList();
    }
    final rawList = json[key];
    if (rawList is List) return rawList.map((e) => e.toString()).toList();
    return [];
  }

  static List<int> _parseSocialProfileListInt(
    Map<String, dynamic> json,
    String key,
  ) {
    final profile = json['user_social_profiles'];
    List<dynamic>? raw;
    if (profile is List && profile.isNotEmpty) {
      raw = profile.first[key] as List<dynamic>?;
    } else if (profile is Map) {
      raw = profile[key] as List<dynamic>?;
    }
    raw ??= json[key] as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((e) => int.tryParse(e.toString())).whereType<int>().toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
      'phone': phone,
      'phone_code': phoneCode,
      'country_code': countryCode,
      'bio': bio,
      'interests': interests,
      'preferred_destinations': preferredDestinations,
      // legacy / fallback text
      'degree': degree,
      'preferred_country': preferredCountry,
      'preferred_field': preferredField,
      'preferred_specialisation': preferredSpecialisation,
      'target_intake': targetIntake,
      'study_goals': studyGoals,
      'other_preferred_countries': otherPreferredCountries,
      // bilingual
      'degree_en': degreeEn,
      'degree_ar': degreeAr,
      'preferred_country_en': preferredCountryEn,
      'preferred_country_ar': preferredCountryAr,
      'preferred_field_en': preferredFieldEn,
      'preferred_field_ar': preferredFieldAr,
      'preferred_specialisation_en': preferredSpecialisationEn,
      'preferred_specialisation_ar': preferredSpecialisationAr,
      'target_intake_en': targetIntakeEn,
      'target_intake_ar': targetIntakeAr,
      'other_preferred_countries_en': otherPreferredCountriesEn,
      'other_preferred_countries_ar': otherPreferredCountriesAr,
      // ids
      'degree_id': degreeId,
      'preferred_country_id': preferredCountryId,
      'other_preferred_country_ids': otherPreferredCountryIds,
    };
  }
}
