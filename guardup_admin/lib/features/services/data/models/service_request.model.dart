import '/core/constants/api/json_keys.dart';

/// Request model representing payload for creating or updating a [ServiceModel].
class ServiceRequest {
  final String name;
  final String? description;
  final String? iconName;

  /// Public URL of the icon image. `null` clears the icon.
  final String? iconUrl;
  final int? displayOrder;
  final bool isActive;

  const ServiceRequest({
    required this.name,
    this.description,
    this.iconName,
    this.iconUrl,
    this.displayOrder,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final n = name.trim();
    final d = description?.trim();
    final i = iconName?.trim();

    return <String, dynamic>{
      JsonKeys.name: n,
      JsonKeys.description: (d != null && d.isNotEmpty) ? d : null,
      JsonKeys.iconName: (i != null && i.isNotEmpty) ? i : null,
      JsonKeys.iconUrl: iconUrl,
      if (displayOrder != null && displayOrder! > 0)
        JsonKeys.displayOrder: displayOrder,
      JsonKeys.isActive: isActive,
    };
  }
}
