import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/enum.jsonconverter.dart';
import '/features/auth/data/enum/user_role.enum.dart';

part 'document_type.model.freezed.dart';
part 'document_type.model.g.dart';

UserRole? _userRoleFromJson(dynamic value) {
  if (value == null) return null;
  return UserRole.values.fromValue(value);
}

String? _userRoleToJson(UserRole? role) => role?.apiValue;

@freezed
abstract class DocumentTypeModel with _$DocumentTypeModel {
  const DocumentTypeModel._();

  const factory DocumentTypeModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(
      name: 'target_role',
      fromJson: _userRoleFromJson,
      toJson: _userRoleToJson,
    )
    @Default(UserRole.guard)
    UserRole targetRole,
    @JsonKey(name: 'is_required') @Default(true) bool isRequired,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'display_order') @Default(0) int displayOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _DocumentTypeModel;

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeModelFromJson(json);

  /// Unique key for state mappings and foreign keys.
  String get docKey => id;

  @Deprecated('Column dropped from DB. Returns id.')
  String get code => id;

  IconData get icon {
    final key = name.toUpperCase().replaceAll(' ', '_');
    if (key.contains('ID_PROOF') ||
        key.contains('GOVERNMENT_ID') ||
        key.contains('ID')) {
      return Icons.badge_outlined;
    }
    if (key.contains('POLICE')) {
      return Icons.verified_user_outlined;
    }
    if (key.contains('LICENSE') || key.contains('SECURITY')) {
      return Icons.lock_outline_rounded;
    }
    if (key.contains('CERTIFICATION')) {
      return Icons.military_tech_outlined;
    }
    if (key.contains('BUSINESS') || key.contains('REGISTRATION')) {
      return Icons.description_outlined;
    }
    if (key.contains('LOGO')) {
      return Icons.image_outlined;
    }
    if (key.contains('ADDITIONAL')) {
      return Icons.folder_open_outlined;
    }
    return Icons.description_outlined;
  }

  bool get allowCrop {
    final key = name.toUpperCase().replaceAll(' ', '_');
    return key.contains('LOGO');
  }

  bool get allowFile => !allowCrop;
}
