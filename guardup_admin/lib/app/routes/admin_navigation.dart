import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/features/auth/presentation/screens/profile.screen.dart';
import '/features/dashboard/presentation/screens/dashboard.screen.dart';
import '/features/document-type/presentation/screens/document_type_management.screen.dart';
import '/features/help-support/presentation/screens/help_support_management.screen.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/features/legal/presentation/screens/content_management.screen.dart';
import '/features/membership/presentation/screens/membership_plan_management.screen.dart';
import '/features/notifications/presentation/screens/notification_management.screen.dart';
import '/features/services/presentation/screens/services_management.screen.dart';
import '/features/settings/presentation/screens/admin_settings.screen.dart';
import '/features/users/data/enums/user_role.enum.dart';
import '/features/users/data/enums/user_status.enum.dart';
import '/features/users/presentation/screens/users_management.screen.dart';
import '/shared/widgets/admin_layout/models.dart';

/// The admin console's navigation tree: sidebar sections, pinned footer items
/// and the fallback page shown when a location matches nothing.
///
/// Adding a page = adding an [AdminNavItem] here. The sidebar, breadcrumbs,
/// page title and command palette all derive from this single definition.
final class AdminNavigation {
  AdminNavigation._();

  static const AdminNavItem dashboard = AdminNavItem(
    icon: Icons.space_dashboard_outlined,
    label: 'Dashboard',
    route: DashboardScreen.route,
    description: 'Platform overview, key metrics and recent activity',
    matchPrefix: false,
  );

  static final List<AdminNavSection> sections = [
    (title: null, items: const [dashboard]),
    (
      title: 'Users',
      items: [
        AdminNavItem(
          icon: Icons.person_outline_rounded,
          label: 'Customers',
          route: UsersManagementScreen.roleLocation(UserRoleType.customer),
          description: 'Manage GuardUp client accounts',
          children: [
            AdminNavItem(
              icon: Icons.verified_user_outlined,
              label: 'Approved',
              route: UsersManagementScreen.location(
                UserRoleType.customer,
                UserStatus.active,
              ),
              description: 'Active customer accounts',
            ),
            AdminNavItem(
              icon: Icons.block_outlined,
              label: 'Blocked',
              route: UsersManagementScreen.location(
                UserRoleType.customer,
                UserStatus.blocked,
              ),
              description: 'Blocked customer accounts',
            ),
          ],
        ),
        AdminNavItem(
          icon: Icons.security_outlined,
          label: 'Bodyguards',
          route: UsersManagementScreen.roleLocation(UserRoleType.guard),
          description: 'Bodyguard personnel and credentials',
          children: [
            AdminNavItem(
              icon: Icons.pending_actions_outlined,
              label: 'Pending',
              route: UsersManagementScreen.location(
                UserRoleType.guard,
                UserStatus.approvalPending,
              ),
              description: 'Bodyguard verifications awaiting review',
            ),
            AdminNavItem(
              icon: Icons.verified_user_outlined,
              label: 'Approved',
              route: UsersManagementScreen.location(
                UserRoleType.guard,
                UserStatus.active,
              ),
              description: 'Approved bodyguard operatives',
            ),
            AdminNavItem(
              icon: Icons.cancel_outlined,
              label: 'Rejected',
              route: UsersManagementScreen.location(
                UserRoleType.guard,
                UserStatus.rejected,
              ),
              description: 'Rejected bodyguard applications',
            ),
            AdminNavItem(
              icon: Icons.block_outlined,
              label: 'Blocked',
              route: UsersManagementScreen.location(
                UserRoleType.guard,
                UserStatus.blocked,
              ),
              description: 'Suspended bodyguard accounts',
            ),
          ],
        ),
        AdminNavItem(
          icon: Icons.business_outlined,
          label: 'Companies',
          route: UsersManagementScreen.roleLocation(UserRoleType.company),
          description: 'Security firms and partner accounts',
          children: [
            AdminNavItem(
              icon: Icons.pending_actions_outlined,
              label: 'Pending',
              route: UsersManagementScreen.location(
                UserRoleType.company,
                UserStatus.approvalPending,
              ),
              description: 'Company applications awaiting review',
            ),
            AdminNavItem(
              icon: Icons.verified_user_outlined,
              label: 'Approved',
              route: UsersManagementScreen.location(
                UserRoleType.company,
                UserStatus.active,
              ),
              description: 'Approved security companies',
            ),
            AdminNavItem(
              icon: Icons.cancel_outlined,
              label: 'Rejected',
              route: UsersManagementScreen.location(
                UserRoleType.company,
                UserStatus.rejected,
              ),
              description: 'Rejected company applications',
            ),
            AdminNavItem(
              icon: Icons.block_outlined,
              label: 'Blocked',
              route: UsersManagementScreen.location(
                UserRoleType.company,
                UserStatus.blocked,
              ),
              description: 'Suspended security companies',
            ),
          ],
        ),
      ],
    ),
    (
      title: 'Platform',
      items: const [
        AdminNavItem(
          icon: Icons.shield_outlined,
          label: 'Services',
          route: ServicesManagementScreen.route,
          description: 'Protection services catalog, ordering and status',
        ),
        AdminNavItem(
          icon: Icons.description_outlined,
          label: 'Document Types',
          route: DocumentTypeManagementScreen.route,
          description: 'Verification documents required per user role',
        ),
        AdminNavItem(
          icon: Icons.workspace_premium_outlined,
          label: 'Membership Plans',
          route: MembershipPlanManagementScreen.route,
          description: 'Customer membership tiers, pricing and discounts',
        ),
      ],
    ),
    (
      title: 'System',
      items: [
        AdminNavItem(
          icon: Icons.article_outlined,
          label: 'Policies & Content',
          route: ContentManagementScreen.route,
          description:
              'Terms & Conditions, Privacy Policy, About Us and other pages',
          children: [
            for (final type in ContentType.values)
              AdminNavItem(
                icon: type.icon,
                label: type.label,
                route: ContentManagementScreen.location(type),
                description: type.description,
              ),
          ],
        ),
        const AdminNavItem(
          icon: Icons.tune_rounded,
          label: 'Settings',
          route: AdminSettingsScreen.route,
          description: 'Platform preferences and configuration',
        ),
        const AdminNavItem(
          icon: Icons.support_agent_rounded,
          label: 'Help & Support',
          route: HelpSupportManagementScreen.route,
          description: 'Contact requests from the app and their resolution',
        ),
        // Not production-ready yet: visible in debug builds only.
        if (kDebugMode) notifications,
        // Not production-ready yet: visible in debug builds only.
        if (kDebugMode) notifications,
      ],
    ),
  ];

  static const List<AdminNavItem> footerItems = [
    AdminNavItem(
      icon: Icons.account_circle_outlined,
      label: 'My Account',
      route: ProfileScreen.route,
      description: 'Administrator profile and sign-in preferences',
    ),
  ];

  static const AdminNavItem notifications = AdminNavItem(
    icon: Icons.notifications_outlined,
    label: 'Notifications',
    route: NotificationManagementScreen.route,
    description: 'Platform push notifications and delivery logs',
  );

  /// Sections plus footer items, for lookups and the command palette.
  static List<AdminNavSection> get searchable => [
    ...sections,
    (title: 'Account', items: footerItems),
    (title: 'System', items: const [notifications]),
  ];

  static const BreadcrumbItem _home = (
    label: 'Home',
    route: DashboardScreen.route,
    icon: Icons.home_rounded,
  );

  /// Page metadata for [location]: title, owning group and breadcrumbs
  /// (Home › Section › Group › Page). Falls back to the dashboard.
  static AdminPageMeta pageFor(String location) {
    final match = searchable.lookup(location);
    if (match == null || match.trail.last.route == DashboardScreen.route) {
      return (
        icon: dashboard.icon,
        title: dashboard.label,
        parentLabel: null,
        description: dashboard.description,
        breadcrumbs: [
          _home,
          (label: dashboard.label, route: dashboard.route, icon: null),
        ],
      );
    }

    final trail = match.trail;
    final page = trail.last;
    final sectionTitle = match.section.title;

    return (
      icon: page.icon,
      title: page.label,
      parentLabel: trail.length > 1 ? trail[trail.length - 2].label : null,
      description: page.description,
      breadcrumbs: [
        _home,
        if (sectionTitle != null)
          (label: sectionTitle, route: null, icon: null),
        for (final item in trail)
          (label: item.label, route: item.route, icon: item.icon),
      ],
    );
  }
}
