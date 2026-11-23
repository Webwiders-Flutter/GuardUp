import 'package:flutter/foundation.dart';

import '/core/constants/api/json_keys.dart';
export 'service_request.model.dart';
export 'service_filters.model.dart';

@immutable
class ServiceModel {
  final String id;
  final String name;
  final String? description;
  final String? iconName;
  final String? iconUrl;
  final bool isActive;
  final int displayOrder;
  final String? createdAt;
  final String? updatedAt;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    this.iconName,
    this.iconUrl,
    this.isActive = true,
    this.displayOrder = 1000,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json[JsonKeys.id] ?? '') as String,
      name: (json[JsonKeys.name] ?? '') as String,
      description: json[JsonKeys.description] as String?,
      iconName: json[JsonKeys.iconName] as String?,
      iconUrl: json[JsonKeys.iconUrl] as String?,
      isActive: (json[JsonKeys.isActive] ?? true) as bool,
      displayOrder: (json[JsonKeys.displayOrder] ?? 1000) as int,
      createdAt: json[JsonKeys.createdAt] as String?,
      updatedAt: json[JsonKeys.updatedAt] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      JsonKeys.id: id,
      JsonKeys.name: name,
      JsonKeys.description: description,
      JsonKeys.iconName: iconName,
      JsonKeys.iconUrl: iconUrl,
      JsonKeys.isActive: isActive,
      JsonKeys.displayOrder: displayOrder,
      JsonKeys.createdAt: createdAt,
      JsonKeys.updatedAt: updatedAt,
    };
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? iconUrl,
    bool? isActive,
    int? displayOrder,
    String? createdAt,
    String? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          iconName == other.iconName &&
          iconUrl == other.iconUrl &&
          isActive == other.isActive &&
          displayOrder == other.displayOrder;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    iconName,
    iconUrl,
    isActive,
    displayOrder,
  );
}
