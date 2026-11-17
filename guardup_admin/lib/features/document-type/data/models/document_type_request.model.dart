import '/core/constants/api/json_keys.dart';
import '/features/users/data/enums/user_role.enum.dart';

/// Request model representing payload for creating or updating a [DocumentTypeModel].
class DocumentTypeRequest {
  final String name;
  final String? description;
  final UserRoleType targetRole;
  final bool isRequired;
  final bool isActive;
  final int? displayOrder;

  const DocumentTypeRequest({
    required this.name,
    this.description,
    required this.targetRole,
    this.isRequired = true,
    this.isActive = true,
    this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    final n = name.trim();
    final d = description?.trim();

    return <String, dynamic>{
      JsonKeys.name: n,
      JsonKeys.description: (d != null && d.isNotEmpty) ? d : null,
      JsonKeys.targetRole: targetRole.apiValue,
      JsonKeys.isRequired: isRequired,
      JsonKeys.isActive: isActive,
      if (displayOrder != null) JsonKeys.displayOrder: displayOrder,
    };
  }
}
