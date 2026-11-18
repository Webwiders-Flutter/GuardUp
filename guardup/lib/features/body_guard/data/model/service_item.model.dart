import 'package:flutter/material.dart';

import '../enum/guard_service.enum.dart';

/// Represents a service item managed dynamically by Admin or database.
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
    this.code = '',
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

  /// Maps to local [GuardService] enum if matching code or name exists.
  GuardService? get guardService =>
      GuardService.tryFromApiValue(code.isNotEmpty ? code : name);

  IconData get icon {
    final guard = guardService;
    if (guard != null) return guard.icon;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('close') || lowerName.contains('vip')) {
      return Icons.shield_outlined;
    }
    if (lowerName.contains('arm') || lowerName.contains('escort')) {
      return Icons.security_rounded;
    }
    if (lowerName.contains('driver') ||
        lowerName.contains('car') ||
        lowerName.contains('vehicle')) {
      return Icons.directions_car_filled_outlined;
    }
    if (lowerName.contains('event')) {
      return Icons.event_seat_rounded;
    }
    if (lowerName.contains('residen') ||
        lowerName.contains('home') ||
        lowerName.contains('estate')) {
      return Icons.home_work_outlined;
    }
    if (lowerName.contains('asset')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (lowerName.contains('surveil') || lowerName.contains('recon')) {
      return Icons.visibility_outlined;
    }
    if (lowerName.contains('crisis')) {
      return Icons.emergency_outlined;
    }
    return Icons.verified_user_outlined;
  }
}

