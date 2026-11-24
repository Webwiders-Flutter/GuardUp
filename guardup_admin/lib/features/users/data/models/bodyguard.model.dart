import 'package:freezed_annotation/freezed_annotation.dart';

import '/features/services/data/models/service.model.dart';
import '/features/users/data/enums/gender_type.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import 'user_availability.model.dart';
import 'user_document.model.dart';

part 'bodyguard.model.freezed.dart';
part 'bodyguard.model.g.dart';

/// Embedded `user_services(id, service:services(...))` rows as services.
List<ServiceModel>? _servicesFromJson(dynamic json) {
  if (json is! List) return null;
  return [
    for (final row in json)
      if (row is Map<String, dynamic> && row['service'] is Map<String, dynamic>)
        ServiceModel.fromJson(row['service'] as Map<String, dynamic>),
  ];
}

/// Bodyguard profile (`public.bodyguards`).
///
/// - Self-registered: [userId] is the GUARD account; name, photo, gender and
///   [status] are copied from that account (approved with it).
/// - Company-managed: [userId] is null, [companyId] is the company; reviewed
///   by an admin on its own ([status], [rejectionReason]). Its services,
///   documents and availability are embedded by the bodyguards repository.
@freezed
abstract class BodyguardModel with _$BodyguardModel {
  const factory BodyguardModel({
    required String id,
    String? userId,
    String? companyId,
    @Default('') String name,
    String? profileImageUrl,
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GenderType? gender,
    @Default('+91') String phoneCode,
    String? phoneNumber,
    double? hourlyRate,
    double? rating,
    int? experienceYears,
    String? bio,

    /// Free text, comma separated (e.g. "English, Hindi").
    String? languages,

    /// Free text, comma separated (e.g. "CPR, First Aid").
    String? certifications,
    @Default(true) bool isActive,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Embedded relations (company-managed bodyguards; see BodyguardsRepository)
    @JsonKey(fromJson: _servicesFromJson, includeToJson: false)
    List<ServiceModel>? services,
    List<UserDocumentModel>? documents,
    List<UserAvailabilityModel>? availabilities,
  }) = _BodyguardModel;

  factory BodyguardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyguardModelFromJson(json);
}
