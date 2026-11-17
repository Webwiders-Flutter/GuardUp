import 'package:flutter/material.dart';

/// Breadcrumb item representation using Dart 3 record typedef per rules.md Section 13.
typedef BreadcrumbItem = ({String label, String? route, IconData? icon});

/// Represents a single item (leaf, parent with children, section header, or divider)
/// in the enterprise admin sidebar menu.
class CustomDashboardMenuItem {
  final IconData icon;
  final String label;
  final String? description;
  final String? route;
  final VoidCallback? onTap;
  final List<CustomDashboardMenuItem> children;
  final int badgeCount;
  final String? badgeText;
  final Color? badgeColor;
  final String? sectionTitle;
  final Widget? trailing;
  final bool isDivider;
  final bool enabled;

  const CustomDashboardMenuItem({
    required this.icon,
    required this.label,
    this.description,
    this.route,
    this.onTap,
    this.children = const [],
    this.badgeCount = 0,
    this.badgeText,
    this.badgeColor,
    this.sectionTitle,
    this.trailing,
    this.isDivider = false,
    this.enabled = true,
  });

  /// Convenience constructor for a pure section divider / header
  const CustomDashboardMenuItem.section({required String title})
    : icon = Icons.circle,
      label = title,
      sectionTitle = title,
      description = null,
      route = null,
      onTap = null,
      children = const [],
      badgeCount = 0,
      badgeText = null,
      badgeColor = null,
      trailing = null,
      isDivider = false,
      enabled = false;

  /// Convenience constructor for a divider line
  const CustomDashboardMenuItem.divider()
    : icon = Icons.remove,
      label = '',
      sectionTitle = null,
      description = null,
      route = null,
      onTap = null,
      children = const [],
      badgeCount = 0,
      badgeText = null,
      badgeColor = null,
      trailing = null,
      isDivider = true,
      enabled = false;

  CustomDashboardMenuItem copyWith({
    IconData? icon,
    String? label,
    String? description,
    String? route,
    VoidCallback? onTap,
    List<CustomDashboardMenuItem>? children,
    int? badgeCount,
    String? badgeText,
    Color? badgeColor,
    String? sectionTitle,
    Widget? trailing,
    bool? isDivider,
    bool? enabled,
  }) {
    return CustomDashboardMenuItem(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      description: description ?? this.description,
      route: route ?? this.route,
      onTap: onTap ?? this.onTap,
      children: children ?? this.children,
      badgeCount: badgeCount ?? this.badgeCount,
      badgeText: badgeText ?? this.badgeText,
      badgeColor: badgeColor ?? this.badgeColor,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      trailing: trailing ?? this.trailing,
      isDivider: isDivider ?? this.isDivider,
      enabled: enabled ?? this.enabled,
    );
  }

  bool get hasChildren => children.isNotEmpty;
  bool get isAction => onTap != null;
}

/// Represents a loaded dashboard page with metadata and widget builder.
class DashboardPage {
  final IconData icon;
  final String title;
  final String route;
  final String? description;
  final WidgetBuilder builder;
  final List<BreadcrumbItem>? breadcrumbs;

  const DashboardPage({
    required this.icon,
    required this.title,
    required this.route,
    required this.builder,
    this.description,
    this.breadcrumbs,
  });

  CustomDashboardMenuItem toMenuItem() {
    return CustomDashboardMenuItem(icon: icon, label: title);
  }
}
