// import 'package:flutter/material.dart';

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

  // IconData get icon {
  //   final guard = guardService;
  //   if (guard != null) return guard.icon;
  //   switch (code.toUpperCase()) {
  //     case 'VIP_CLOSE_PROTECTION':
  //       return Icons.shield_outlined;
  //     case 'ARMED_ESCORT':
  //       return Icons.security_rounded;
  //     case 'TACTICAL_DRIVER':
  //       return Icons.directions_car_filled_outlined;
  //     case 'EVENT_SECURITY':
  //       return Icons.event_seat_rounded;
  //     case 'RESIDENTIAL_PROTECTION':
  //       return Icons.home_work_outlined;
  //     case 'ASSET_PROTECTION':
  //       return Icons.account_balance_wallet_outlined;
  //     case 'SURVEILLANCE_RECON':
  //       return Icons.visibility_outlined;
  //     case 'CRISIS_MANAGEMENT':
  //       return Icons.emergency_outlined;
  //     default:
  //       return Icons.verified_user_outlined;
  //   }
  // }
}

