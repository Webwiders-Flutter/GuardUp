import 'package:flutter/foundation.dart';

import '/core/constants/api/json_keys.dart';
import '/features/users/data/enums/user_role.enum.dart';
export 'document_type_request.model.dart';
export 'document_type_filters.model.dart';

@immutable
class DocumentTypeModel {
  final String id;
  final String name;
  final String? description;
  final UserRoleType targetRole;
  final bool isRequired;
  final bool isActive;
  final int displayOrder;
  final String? createdAt;
  final String? updatedAt;

  const DocumentTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.targetRole,
    this.isRequired = true,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      id: (json[JsonKeys.id] ?? '') as String,
      name: (json[JsonKeys.name] ?? '') as String,
      description: json[JsonKeys.description] as String?,
      targetRole:
          UserRoleType.fromApi(json[JsonKeys.targetRole] as String?) ??
          UserRoleType.guard,
      isRequired: (json[JsonKeys.isRequired] ?? true) as bool,
      isActive: (json[JsonKeys.isActive] ?? true) as bool,
      displayOrder: (json[JsonKeys.displayOrder] ?? 0) as int,
      createdAt: json[JsonKeys.createdAt] as String?,
      updatedAt: json[JsonKeys.updatedAt] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      JsonKeys.id: id,
      JsonKeys.name: name,
      JsonKeys.description: description,
      JsonKeys.targetRole: targetRole.apiValue,
      JsonKeys.isRequired: isRequired,
      JsonKeys.isActive: isActive,
      JsonKeys.displayOrder: displayOrder,
      JsonKeys.createdAt: createdAt,
      JsonKeys.updatedAt: updatedAt,
    };
  }

  DocumentTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    UserRoleType? targetRole,
    bool? isRequired,
    bool? isActive,
    int? displayOrder,
    String? createdAt,
    String? updatedAt,
  }) {
    return DocumentTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetRole: targetRole ?? this.targetRole,
      isRequired: isRequired ?? this.isRequired,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentTypeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          targetRole == other.targetRole &&
          isRequired == other.isRequired &&
          isActive == other.isActive &&
          displayOrder == other.displayOrder;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    targetRole,
    isRequired,
    isActive,
    displayOrder,
  );
}
