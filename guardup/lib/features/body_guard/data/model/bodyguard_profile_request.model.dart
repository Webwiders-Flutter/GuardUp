import '/core/constants/api/json_keys.dart';

/// Payload for a `bodyguards` row, used both for a self-registered guard
/// (row keyed by `user_id`) and a company-managed bodyguard (keyed by `id`).
///
/// Strings are trimmed; an empty optional string is written as `null`.
/// Optional fields left `null` are omitted, so they keep their stored value.
class BodyguardProfileRequest {
  const BodyguardProfileRequest({
    required this.name,
    required this.hourlyRate,
    required this.bio,
    this.experienceYears,
    this.languages,
    this.certifications,
    this.qualifications,
    this.address,
    this.latitude,
    this.longitude,
    this.profileImageUrl,
  });

  final String name;
  final double hourlyRate;
  final String bio;
  final int? experienceYears;
  final String? languages;
  final String? certifications;
  final String? qualifications;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? profileImageUrl;

  /// Columns for the `bodyguards` row.
  ///
  /// [includeIdentity] writes `name` / `profile_image_url`. Pass `false` for
  /// a self-registered guard: `users` is the source of truth for those and
  /// `sync_bodyguard_identity()` copies them (documentation/user_profiles.md).
  Map<String, dynamic> toJson({bool includeIdentity = true}) {
    return <String, dynamic>{
      if (includeIdentity) JsonKeys.name: name.trim(),
      JsonKeys.hourlyRate: hourlyRate,
      JsonKeys.bio: bio.trim(),
      JsonKeys.experienceYears: ?experienceYears,
      if (languages != null) JsonKeys.languages: _nullIfEmpty(languages),
      if (certifications != null)
        JsonKeys.certifications: _nullIfEmpty(certifications),
      if (qualifications != null)
        JsonKeys.qualifications: _nullIfEmpty(qualifications),
      if (address != null) JsonKeys.address: _nullIfEmpty(address),
      JsonKeys.latitude: ?latitude,
      JsonKeys.longitude: ?longitude,
      if (includeIdentity && profileImageUrl != null)
        JsonKeys.profileImageUrl: _nullIfEmpty(profileImageUrl),
    };
  }
}

String? _nullIfEmpty(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
