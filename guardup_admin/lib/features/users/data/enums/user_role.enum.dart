import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:guardup_admin/features/dashboard/presentation/screens/dashboard.screen.dart';
import 'package:guardup_admin/features/users/data/enums/user_status.enum.dart';
import 'package:guardup_admin/features/users/presentation/screens/users_management.screen.dart';

import '/core/extensions/context.extension.dart';
import '/gen/app_localizations.dart';

enum UserRoleType {
  @JsonValue('ADMIN')
  admin('ADMIN'),

  @JsonValue('CUSTOMER')
  customer('CUSTOMER'),

  @JsonValue('GUARD')
  guard('GUARD'),

  @JsonValue('COMPANY')
  company('COMPANY');

  final String apiValue;

  const UserRoleType(this.apiValue);

  bool get isAdmin => this == UserRoleType.admin;
  bool get isCustomer => this == UserRoleType.customer;
  bool get isGuard => this == UserRoleType.guard;
  bool get isCompany => this == UserRoleType.company;

  /// URL-friendly path identifier for routing.
  String get slug {
    switch (this) {
      case UserRoleType.customer:
        return 'customer';
      case UserRoleType.guard:
        return 'bodyguard';
      case UserRoleType.company:
        return 'company';
      case UserRoleType.admin:
        return 'admin';
    }
  }

  /// Resolves [UserRoleType] from a URL slug or API value with safe fallback.
  static UserRoleType fromSlug(String slug) {
    final normalized = slug.toLowerCase().trim();
    if (normalized == 'bodyguard' || normalized == 'guard') {
      return UserRoleType.guard;
    }
    return UserRoleType.values.firstWhere(
      (e) => e.slug == normalized || e.apiValue.toLowerCase() == normalized,
      orElse: () => UserRoleType.customer,
    );
  }

  /// Resolves [UserRoleType] from API string value.
  static UserRoleType? fromApi(String? value) => tryFromSlug(value);

  /// Safely resolves [UserRoleType] from a nullable URL slug.
  static UserRoleType? tryFromSlug(String? slug) {
    if (slug == null || slug.isEmpty) return null;
    final normalized = slug.toLowerCase().trim();
    if (normalized == 'bodyguard' || normalized == 'guard') {
      return UserRoleType.guard;
    }
    try {
      return UserRoleType.values.firstWhere(
        (e) => e.slug == normalized || e.apiValue.toLowerCase() == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  /// Platform roles excluding admin (Customer, Bodyguard, Company).
  static List<UserRoleType> get platformRoles => [customer, guard, company];

  String label([AppLocalizations? l10n]) {
    switch (this) {
      case UserRoleType.admin:
        return 'Admin';
      case UserRoleType.customer:
        return 'Customer';
      case UserRoleType.guard:
        return 'Bodyguard';
      case UserRoleType.company:
        return 'Company';
    }
  }

  String description([AppLocalizations? l10n]) {
    switch (this) {
      case UserRoleType.admin:
        return 'Administrator with full system privileges';
      case UserRoleType.customer:
        return 'Client hiring protection services';
      case UserRoleType.guard:
        return 'Certified protection operative / Bodyguard';
      case UserRoleType.company:
        return 'Security firm / Agency managing bodyguard personnel';
    }
  }

  String redirectionRoute(UserStatus? status) {
    switch (this) {
      case UserRoleType.admin:
        return DashboardScreen.route;
      case UserRoleType.customer:
      case UserRoleType.guard:
      case UserRoleType.company:
        return status!=null? UsersManagementScreen.location(this, status): UsersManagementScreen.roleLocation(this);
    }
  }

  Color color(BuildContext context) {
    final colors = context.colors;
    switch (this) {
      case UserRoleType.admin:
        return colors.primary;
      case UserRoleType.customer:
        return colors.success;
      case UserRoleType.guard:
        return colors.secondary;
      case UserRoleType.company:
        return colors.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case UserRoleType.customer:
        return Icons.person_outline;
      case UserRoleType.guard:
        return Icons.security_outlined;
      case UserRoleType.company:
        return Icons.business_outlined;
      case UserRoleType.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}
