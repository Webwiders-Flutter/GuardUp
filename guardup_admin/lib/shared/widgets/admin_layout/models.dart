import 'package:flutter/material.dart';

/// A single crumb in the top-bar breadcrumb trail. Crumbs without a [route]
/// (e.g. sidebar section names) render as plain text.
typedef BreadcrumbItem = ({String label, String? route, IconData? icon});

/// Metadata for the page currently shown inside the admin shell.
///
/// [parentLabel] is the label of the nav group that owns the page (e.g.
/// "Bodyguards" for "Pending"); compact layouts use it to qualify the title
/// when breadcrumbs are hidden.
typedef AdminPageMeta = ({
  IconData icon,
  String title,
  String? parentLabel,
  String? description,
  List<BreadcrumbItem> breadcrumbs,
});

/// A titled group of sidebar items. A null [title] renders the items without
/// a section header.
typedef AdminNavSection = ({String? title, List<AdminNavItem> items});

/// Result of resolving a location against the navigation tree: the section
/// it belongs to and the item path from the top-level item down to the match.
typedef AdminNavMatch = ({AdminNavSection section, List<AdminNavItem> trail});

/// A navigation destination (or group of destinations) in the admin sidebar.
///
/// Items with [children] render as expandable groups (or flyouts in the
/// collapsed rail). Items with [onTap] act as commands instead of routes.
class AdminNavItem {
  const AdminNavItem({
    required this.icon,
    required this.label,
    this.route,
    this.description,
    this.onTap,
    this.children = const [],
    this.badgeCount = 0,
    this.badgeText,
    this.badgeColor,
    this.enabled = true,
    this.matchPrefix = true,
  });

  final IconData icon;
  final String label;
  final String? route;

  /// Shown under the page title and in the command palette.
  final String? description;
  final VoidCallback? onTap;
  final List<AdminNavItem> children;

  /// Numeric badge (e.g. pending reviews). Parents without their own count
  /// show the sum of their children.
  final int badgeCount;

  /// Short text tag such as "NEW". Shown alongside [badgeCount].
  final String? badgeText;
  final Color? badgeColor;
  final bool enabled;

  /// Whether nested locations (`$route/...`) also activate this item, so
  /// detail pages keep their parent highlighted. Disable for routes such as
  /// the dashboard whose path prefixes unrelated pages.
  final bool matchPrefix;
}

extension AdminNavItemX on AdminNavItem {
  bool get hasChildren => children.isNotEmpty;

  /// Whether this item's own route matches [location].
  bool matches(String location) {
    final route = this.route;
    if (route == null) return false;
    if (route == location) return true;
    return matchPrefix && location.startsWith('$route/');
  }

  /// Whether this item or any descendant matches [location].
  bool isActiveIn(String location) =>
      matches(location) || hasActiveDescendant(location);

  bool hasActiveDescendant(String location) =>
      children.any((child) => child.isActiveIn(location));

  /// Own badge count, or the sum of the children's counts.
  int get totalBadgeCount => badgeCount > 0
      ? badgeCount
      : children.fold(0, (sum, child) => sum + child.totalBadgeCount);

  /// This item (when routable) followed by all routable descendants.
  Iterable<AdminNavItem> get routableDescendants sync* {
    if (route != null) yield this;
    for (final child in children) {
      yield* child.routableDescendants;
    }
  }
}

extension AdminNavSectionsX on List<AdminNavSection> {
  /// Resolves [location] to its section and item trail.
  ///
  /// Exact route matches win over prefix matches, so `/users/guards/pending`
  /// selects "Pending" rather than its "Bodyguards" parent.
  AdminNavMatch? lookup(String location) {
    return _lookup(location, exact: true) ?? _lookup(location, exact: false);
  }

  AdminNavMatch? _lookup(String location, {required bool exact}) {
    for (final section in this) {
      final trail = _trail(section.items, location, exact: exact);
      if (trail.isNotEmpty) return (section: section, trail: trail);
    }
    return null;
  }
}

List<AdminNavItem> _trail(
  List<AdminNavItem> items,
  String location, {
  required bool exact,
}) {
  for (final item in items) {
    final nested = _trail(item.children, location, exact: exact);
    if (nested.isNotEmpty) return [item, ...nested];

    final isHit = exact ? item.route == location : item.matches(location);
    if (isHit) return [item];
  }
  return const [];
}
