import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/json_converters.dart';
import '/features/auth/data/enum/user_status.enum.dart';
import '/features/company/data/model/company.model.dart';
import '/features/services/data/models/service.model.dart';
import 'user_availability.model.dart';
import 'user_document.model.dart';

export '/core/extensions/bodyguard.extension.dart';

part 'body_guard.model.freezed.dart';
part 'body_guard.model.g.dart';

CompanyModel? _companyFromJson(dynamic json) =>
    EmbeddedParser.parseObject(json, CompanyModel.fromJson);

List<UserDocumentModel>? _documentsFromJson(dynamic json) =>
    EmbeddedParser.parseList(json, UserDocumentModel.fromJson);

List<UserAvailabilityModel>? _availabilitiesFromJson(dynamic json) =>
    EmbeddedParser.parseList(json, UserAvailabilityModel.fromJson);

/// Bodyguard profile (`public.bodyguards`), 1:1 with the table.
///
/// - Self-registered: [userId] is the GUARD account; [name],
///   [profileImageUrl] and [status] are copied from that account by
///   `sync_bodyguard_identity()`.
/// - Company-managed: [userId] is null, [companyId] is the managing company.
///
/// Display helpers live in `BodyGuardModelX` (core/extensions).
@freezed
abstract class BodyGuardModel with _$BodyGuardModel {
  const factory BodyGuardModel({
    required String id,
    String? userId,
    String? companyId,
    @Default('') String name,
    String? profileImageUrl,
    @DoubleConverter() @Default(0.0) double hourlyRate,
    @DoubleConverter() @Default(0.0) double rating,
    @IntConverter() @Default(0) int experienceYears,
    @Default('') String bio,

    /// Free text, comma separated (e.g. "English, Hindi").
    String? languages,

    /// Free text, comma separated (e.g. "CPR, First Aid").
    String? certifications,
    String? qualifications,
    String? address,
    @NullableDoubleConverter() double? latitude,
    @NullableDoubleConverter() double? longitude,
    @Default(true) bool isActive,
    @Default(UserStatus.incomplete)
    @JsonKey(unknownEnumValue: UserStatus.incomplete)
    UserStatus status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,

    // Embedded relations (see BodyguardRepository select strings).
    @JsonKey(fromJson: _companyFromJson, includeToJson: false)
    CompanyModel? company,
    @JsonKey(fromJson: servicesFromUserServices, includeToJson: false)
    List<ServiceModel>? services,
    @JsonKey(fromJson: _documentsFromJson, includeToJson: false)
    List<UserDocumentModel>? documents,
    @JsonKey(fromJson: _availabilitiesFromJson, includeToJson: false)
    List<UserAvailabilityModel>? availabilities,
  }) = _BodyGuardModel;

  factory BodyGuardModel.fromJson(Map<String, dynamic> json) =>
      _$BodyGuardModelFromJson(json);
}
