import 'package:flutter/material.dart';

import '../../../auth/data/enum/user_role.enum.dart';
import '../../../company/data/enum/company_doc_type.enum.dart';
import '../enum/guard_doc_type.enum.dart';

/// Represents a document type managed by the Admin via the admin web portal.
class DocumentTypeModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final UserRole targetRole;
  final bool isRequired;
  final bool isActive;
  final int displayOrder;

  const DocumentTypeModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.targetRole,
    this.isRequired = true,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      id: (json['id'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      targetRole: UserRole.fromApiValue(json['target_role'] as String?),
      isRequired: (json['is_required'] ?? true) as bool,
      isActive: (json['is_active'] ?? true) as bool,
      displayOrder: (json['display_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'target_role': targetRole.apiValue,
      'is_required': isRequired,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  GuardDocType? get guardDocType => GuardDocType.tryFromApiValue(code);
  CompanyDocType? get companyDocType => CompanyDocType.tryFromApiValue(code);

  IconData get icon {
    switch (code.toUpperCase()) {
      case 'BUSINESS_REGISTRATION':
        return Icons.description_outlined;
      case 'GOVERNMENT_ID':
        return Icons.badge_outlined;
      case 'COMPANY_LOGO':
        return Icons.image_outlined;
      case 'ADDITIONAL_DOCUMENTS':
        return Icons.folder_open_outlined;
      case 'ID_PROOF':
        return Icons.badge_outlined;
      case 'POLICE_VERIFICATION':
        return Icons.verified_user_outlined;
      case 'SECURITY_LICENSE':
        return Icons.lock_outline_rounded;
      case 'CERTIFICATIONS':
        return Icons.military_tech_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  bool get allowCrop => code.toUpperCase() == 'COMPANY_LOGO';
  bool get allowFile => code.toUpperCase() != 'COMPANY_LOGO';
}

