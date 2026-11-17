import '../enum/guard_service.enum.dart';

/// Represents a service item managed dynamically by Admin or fallback enum.
class ServiceItemModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String? iconName;
  final bool isActive;
  final int displayOrder;

  const ServiceItemModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.iconName,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory ServiceItemModel.fromJson(Map<String, dynamic> json) {
    return ServiceItemModel(
      id: (json['id'] ?? '') as String,
      code: (json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: json['description'] as String?,
      iconName: json['icon_name'] as String?,
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
      'icon_name': iconName,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  /// Maps to local [GuardService] enum if matching code exists.
  GuardService? get guardService => GuardService.tryFromApiValue(code);

  static List<ServiceItemModel> get defaultList => [
        const ServiceItemModel(
          id: 'srv_1',
          code: 'VIP_CLOSE_PROTECTION',
          name: 'VIP Close Protection',
          description: 'Dedicated personal bodyguards for high-profile clients',
          displayOrder: 1,
        ),
        const ServiceItemModel(
          id: 'srv_2',
          code: 'ARMED_ESCORT',
          name: 'Armed Escort',
          description: 'High-threat transit and armed convoy security',
          displayOrder: 2,
        ),
        const ServiceItemModel(
          id: 'srv_3',
          code: 'TACTICAL_DRIVER',
          name: 'Tactical Driver',
          description: 'Evasive security driving and executive transport',
          displayOrder: 3,
        ),
        const ServiceItemModel(
          id: 'srv_4',
          code: 'EVENT_SECURITY',
          name: 'Event Security',
          description: 'Crowd control, perimeter security, and venue access',
          displayOrder: 4,
        ),
        const ServiceItemModel(
          id: 'srv_5',
          code: 'RESIDENTIAL_PROTECTION',
          name: 'Residential Protection',
          description: 'Estate and private property static guarding',
          displayOrder: 5,
        ),
        const ServiceItemModel(
          id: 'srv_6',
          code: 'ASSET_PROTECTION',
          name: 'Asset Protection',
          description: 'Valuables and high-value cargo transport protection',
          displayOrder: 6,
        ),
        const ServiceItemModel(
          id: 'srv_7',
          code: 'SURVEILLANCE_RECON',
          name: 'Surveillance Recon',
          description: 'Counter-surveillance and route threat assessment',
          displayOrder: 7,
        ),
        const ServiceItemModel(
          id: 'srv_8',
          code: 'CRISIS_MANAGEMENT',
          name: 'Crisis Management',
          description: 'Emergency extraction and crisis response',
          displayOrder: 8,
        ),
      ];
}

