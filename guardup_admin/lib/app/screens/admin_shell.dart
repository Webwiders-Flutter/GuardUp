import 'dart:math' as math;

import '/core/providers/theme/theme.provider.dart';
import '/features/auth/di/auth.providers.dart';
import '../../shared/widgets/feedbacks/widgets/app_snackbar.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '../../core/extensions/context.extension.dart';
import '../../core/extensions/spacing.extension.dart';
import '../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/admin_layout/dashboard_layout.dart';
import '/shared/widgets/admin_layout/models.dart';
import '/shared/widgets/admin_layout/sidebar.dart';
import '../../shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Enterprise admin shell widget.
///
/// Wraps [CustomDashboardLayout] with [go_router] shell navigation.
/// Provides:
/// - Categorized navigation hierarchy with section headers
/// - Interactive Command Palette / Quick Search trigger
/// - Real-time notification preview dropdown
/// - Authenticated profile menu with online status & sign-out confirmation
/// - 100% compliant with rules.md design system
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<CustomDashboardMenuItem> _findBreadcrumbTrail(
    List<CustomDashboardMenuItem> items,
    String route,
  ) {
    // 1. Exact match check (including children first)
    for (final item in items) {
      if (item.hasChildren) {
        final subTrail = _findBreadcrumbTrail(item.children, route);
        if (subTrail.isNotEmpty) {
          return [item, ...subTrail];
        }
      }
      if (item.route == route) {
        return [item];
      }
    }

    // 2. Prefix matching fallback (deepest match first)
    for (final item in items) {
      if (item.hasChildren) {
        final subTrail = _findBreadcrumbTrail(item.children, route);
        if (subTrail.isNotEmpty) {
          return [item, ...subTrail];
        }
      }
      if (item.route != null &&
          item.route != AppRoutes.home &&
          route.startsWith('${item.route}/')) {
        return [item];
      }
    }

    return const [];
  }

  // ── Menu Definition ──────────────────────────────────────────────────────────

  final List<CustomDashboardMenuItem> menuItems = [
    // ── MAIN ─────────────────────────────────────────────
    const CustomDashboardMenuItem(
      sectionTitle: 'Main',
      icon: Icons.grid_view_rounded,
      label: 'Dashboard',
      route: AppRoutes.home,
      description: 'Platform overview, key metrics and active trips',
    ),
    // ── USERS ─────────────────────────────────────────────
    CustomDashboardMenuItem(
      sectionTitle: 'Users',
      icon: Icons.person_outline,
      label: 'Customers',
      route: AppRoutes.userCustomer,
      description: 'Manage GuardUp client accounts',
      children: [
        CustomDashboardMenuItem(
          icon: Icons.verified_user_outlined,
          label: 'Approved',
          route: AppRoutes.userCustomerVerified,
          description: 'Manage active customer accounts',
        ),
        // CustomDashboardMenuItem(
        //   icon: Icons.pending_actions_outlined,
        //   label: 'Pending',
        //   route: AppRoutes.userCustomerPending,
        //   description: 'Manage pending customer accounts',
        // ),
        CustomDashboardMenuItem(
          icon: Icons.block_outlined,
          label: 'Blocked',
          route: AppRoutes.userCustomerBlocked,
          description: 'Manage blocked customer accounts',
        ),
      ],
    ),
    CustomDashboardMenuItem(
      icon: Icons.security_outlined,
      label: 'Bodyguards',
      route: AppRoutes.userGuard,
      description: 'Manage bodyguard personnel & credentials',
      children: [
        CustomDashboardMenuItem(
          icon: Icons.pending_actions_outlined,
          label: 'Pending',
          route: AppRoutes.userGuardPending,
          description: 'Review pending bodyguard verifications',
        ),
        CustomDashboardMenuItem(
          icon: Icons.verified_user_outlined,
          label: 'Approved',
          route: AppRoutes.userGuardVerified,
          description: 'Manage approved bodyguard operatives',
        ),
        CustomDashboardMenuItem(
          icon: Icons.cancel_outlined,
          label: 'Rejected',
          route: AppRoutes.userGuardRejected,
          description: 'Review rejected bodyguard applications',
        ),
        CustomDashboardMenuItem(
          icon: Icons.block_outlined,
          label: 'Blocked',
          route: AppRoutes.userGuardBlocked,
          description: 'Manage suspended bodyguard accounts',
        ),
      ],
    ),
    CustomDashboardMenuItem(
      icon: Icons.business_outlined,
      label: 'Companies',
      route: AppRoutes.userCompany,
      description: 'Manage security firm & partner accounts',
      children: [
        CustomDashboardMenuItem(
          icon: Icons.pending_actions_outlined,
          label: 'Pending',
          route: AppRoutes.userCompanyPending,
          description: 'Review pending company applications',
        ),
        CustomDashboardMenuItem(
          icon: Icons.verified_user_outlined,
          label: 'Approved',
          route: AppRoutes.userCompanyVerified,
          description: 'Manage approved security companies',
        ),
        CustomDashboardMenuItem(
          icon: Icons.cancel_outlined,
          label: 'Rejected',
          route: AppRoutes.userCompanyRejected,
          description: 'Review rejected company applications',
        ),
        CustomDashboardMenuItem(
          icon: Icons.block_outlined,
          label: 'Blocked',
          route: AppRoutes.userCompanyBlocked,
          description: 'Manage suspended security companies',
        ),
      ],
    ),

    // ── SUPPORT ──────────────────────────────────────────
    const CustomDashboardMenuItem(
      sectionTitle: 'Support',
      icon: Icons.support_agent_rounded,
      label: 'Help & Support',
      route: AppRoutes.helpSupport,
      description: 'Contact requests from the app and their resolution status',
    ),
    // const CustomDashboardMenuItem(
    //   icon: Icons.quiz_outlined,
    //   label: 'FAQs',
    //   route: AppRoutes.faqs,
    //   description:
    //       'Frequently asked questions, localized answers and role guides',
    // ),
    // Legal is not production-ready yet: visible in debug builds only.
    CustomDashboardMenuItem(
      sectionTitle: 'Legal',
      icon: Icons.article_outlined,
      label: 'Policies & Content',
      route: AppRoutes.content,
      description: 'Manage Terms & Conditions, Privacy Policy, About Us, Delete Account, and Support',
      children: ContentType.values.map((e) {
        return CustomDashboardMenuItem(
          icon: e.icon,
          label: e.label,
          route: AppRoutes.contentUrl(e),
          description: e.description,
        );
      }).toList(),
    ),

    // ── PLATFORM & MASTER DATA ───────────────────────────
    const CustomDashboardMenuItem(
      sectionTitle: 'Platform',
      icon: Icons.shield_outlined,
      label: 'Services',
      route: AppRoutes.services,
      description: 'Protection services catalog, ordering & active status',
    ),
    const CustomDashboardMenuItem(
      icon: Icons.description_outlined,
      label: 'Document Types',
      route: AppRoutes.documentTypes,
      description: 'Verification documents required per user role',
    ),
    const CustomDashboardMenuItem(
      icon: Icons.workspace_premium_outlined,
      label: 'Membership Plans',
      route: AppRoutes.membershipPlans,
      description: 'Customer membership tiers, pricing & booking discounts',
    ),

    // ── SYSTEM ───────────────────────────────────────────
    const CustomDashboardMenuItem(
      sectionTitle: 'System',
      icon: Icons.tune_rounded,
      label: 'Settings',
      route: AppRoutes.settings,
      description: 'Platform preferences, role permissions & configuration',
    ),
    if (kDebugMode)
      const CustomDashboardMenuItem(
        icon: Icons.notifications_outlined,
        label: 'Notifications',
        route: AppRoutes.notifications,
        description: 'System broadcasts, push notifications and delivery logs',
      ),
  ];

  final List<CustomDashboardMenuItem> bottomItems = [
    const CustomDashboardMenuItem(
      icon: Icons.account_circle_outlined,
      label: 'My Account',
      route: AppRoutes.profileDetails,
      description: 'Administrator profile and login preferences',
    ),
  ];

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final breadcrumbTrail = () {
      final topTrail = _findBreadcrumbTrail(menuItems, currentRoute);
      if (topTrail.isNotEmpty) return topTrail;
      return _findBreadcrumbTrail(bottomItems, currentRoute);
    }();

    final menuItem = breadcrumbTrail.isNotEmpty ? breadcrumbTrail.last : null;

    final pageTitle = menuItem != null
        ? (breadcrumbTrail.length >= 3
              ? '${breadcrumbTrail[breadcrumbTrail.length - 2].label} — ${menuItem.label}'
              : menuItem.label)
        : 'Dashboard';

    final List<BreadcrumbItem> breadcrumbs =
        menuItem != null && menuItem.route != AppRoutes.home
        ? [
            (label: 'Home', route: AppRoutes.home, icon: Icons.home_rounded),
            for (final item in breadcrumbTrail)
              (label: item.label, route: item.route, icon: item.icon),
          ]
        : const [
            (label: 'Home', route: AppRoutes.home, icon: Icons.home_rounded),
            (
              label: 'Dashboard',
              route: AppRoutes.home,
              icon: Icons.dashboard_rounded,
            ),
          ];

    return CustomDashboardLayout(
      topItems: menuItems,
      bottomItems: bottomItems,
      currentRoute: currentRoute,
      showPageHeader: true,
      showHeaderIcon: true,
      showHeading: true,
      headerTitleSize: 18.0,
      headerDescriptionSize: 12.5,
      onSelect: (item) {
        if (item.onTap != null) {
          item.onTap!();
        } else if (item.route != null) {
          try {
            context.go(item.route!);
          } catch (_) {
            // Route not yet wired in shell branches
          }
        }
      },
      appBarActions: _buildHeaderActions(context),
      currentPage: menuItem != null
          ? DashboardPage(
              icon: menuItem.icon,
              title: pageTitle,
              route: currentRoute,
              description: menuItem.description,
              breadcrumbs: breadcrumbs,
              builder: (_) => const SizedBox.shrink(),
            )
          : DashboardPage(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              route: AppRoutes.home,
              description:
                  'GuardUp Admin — Executive Protection Administration',
              breadcrumbs: const [
                (
                  label: 'Home',
                  route: AppRoutes.home,
                  icon: Icons.home_rounded,
                ),
                (
                  label: 'Dashboard',
                  route: AppRoutes.home,
                  icon: Icons.dashboard_rounded,
                ),
              ],
              builder: (_) => const SizedBox.shrink(),
            ),
      contentWidget: widget.navigationShell,
    );
  }

  // ── Header Actions ────────────────────────────────────────────────────────────

  Widget _buildHeaderActions(BuildContext context) {
    return AppBarActions(
      actions: [
        // ── Theme Mode Toggle ──────────────────────────────────
        _buildThemeToggle(context),

        AppSpacing.sm.w,

        // ── Notification Dropdown ──────────────────────────────
        // NotificationIconWidget(),
        // _buildNotificationMenu(context),

        // ── Vertical Separator ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: VerticalDivider(
            width: 1,
            color: context.colors.borderLight.withValues(alpha: 0.8),
          ),
        ),

        AppSpacing.sm.w,

        // ── User Profile Pill & Dropdown ───────────────────────
        _buildProfileMenu(context),
      ],
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final currentMode =
        ref.watch(themeControllerProvider).value ?? ThemeMode.system;
    final isDark = switch (currentMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => Theme.of(context).brightness == Brightness.dark,
    };

    final iconData = switch (currentMode) {
      ThemeMode.dark => Icons.dark_mode_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.system => Icons.brightness_auto_rounded,
    };

    final modeLabel = switch (currentMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System (${isDark ? "Dark" : "Light"})',
    };

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme mode: $modeLabel',
      offset: const Offset(0, AppSpacing.xxxl + AppSpacing.md),
      elevation: 8,
      surfaceTintColor: context.colors.transparent,
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: context.colors.borderLight.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      onSelected: (mode) {
        ref.read(themeControllerProvider.notifier).changeTheme(mode);
      },
      itemBuilder: (context) => [
        _buildThemeMenuItem(
          context,
          mode: ThemeMode.light,
          currentMode: currentMode,
          icon: Icons.light_mode_outlined,
          label: 'Light',
        ),
        _buildThemeMenuItem(
          context,
          mode: ThemeMode.dark,
          currentMode: currentMode,
          icon: Icons.dark_mode_outlined,
          label: 'Dark',
        ),
        _buildThemeMenuItem(
          context,
          mode: ThemeMode.system,
          currentMode: currentMode,
          icon: Icons.brightness_auto_outlined,
          label: 'System',
        ),
      ],
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: QuickContainer(
          w: AppSpacing.xxxl + AppSpacing.xs,
          h: AppSpacing.xxxl + AppSpacing.xs,
          alignment: Alignment.center,
          color: context.colors.surface,
          radius: AppRadius.md,
          border: Border.all(
            color: context.colors.borderLight.withValues(alpha: 0.8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              iconData,
              key: ValueKey(currentMode),
              size: AppSpacing.xl,
              color: context.colors.primary,
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<ThemeMode> _buildThemeMenuItem(
    BuildContext context, {
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    return PopupMenuItem<ThemeMode>(
      value: mode,
      height: 40,
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSpacing.lg,
            color: isSelected
                ? context.colors.secondary
                : context.colors.onSurfaceSecondary,
          ),
          AppSpacing.sm.w,
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? context.colors.secondary
                    : context.colors.onSurface,
              ),
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_rounded,
              size: AppSpacing.md + 2,
              color: context.colors.secondary,
            ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final adminUser = ref.watch(adminUserControllerProvider).value;
        final authUser = ref.watch(authControllerProvider).value;
        final displayName = adminUser?.fullName.isNotEmpty == true
            ? adminUser!.fullName
            : (authUser?.userMetadata?['full_name'] as String? ??
                  'Super Admin');
        final displayEmail = adminUser?.email.isNotEmpty == true
            ? adminUser!.email
            : (authUser?.email ?? 'admin@guardup.com');

        String initials = 'AD';
        final parts = displayName.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
        } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
          initials = parts[0]
              .substring(0, math.min(2, parts[0].length))
              .toUpperCase();
        }

        return PopupMenuButton<String>(
          offset: const Offset(0, AppSpacing.xxxl * 2),

          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with Online Green Dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    QuickContainer(
                      h: AppSpacing.xxxl + AppSpacing.xs,
                      w: AppSpacing.xxxl + AppSpacing.xs,
                      radius: AppRadius.full,
                      color: context.colors.secondary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: context.colors.secondary.withValues(alpha: 0.3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: context.textTheme.labelMedium?.bold().colour(
                          context.colors.secondary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: AppSpacing.sm + 1,
                        height: AppSpacing.sm + 1,
                        decoration: BoxDecoration(
                          color: context.colors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.surface,
                            width: (AppSpacing.xs / 2) - 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.sm.w,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: context.textTheme.bodySmall?.semiBold().size(
                        AppSpacing.md + 1,
                      ),
                    ),
                    Text(
                      displayEmail,
                      style: context.textTheme.labelSmall
                          ?.size(AppSpacing.md - 0.5)
                          .colour(context.colors.onSurfaceSecondary),
                    ),
                  ],
                ),
                AppSpacing.xs.w,
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSpacing.lg,
                  color: context.colors.onSurfaceSecondary,
                ),
              ],
            ),
          ),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                try {
                  context.go(AppRoutes.profileDetails);
                } catch (_) {}
                break;
              // case 'settings':
              //   try {
              //     context.go(AppRoutes.settings);
              //   } catch (_) {}
              //   break;
              case 'logout':
                _handleLogout(context, ref);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'profile',
              height: 42,
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: AppSpacing.lg + 2,
                    color: context.colors.onSurfaceSecondary,
                  ),
                  AppSpacing.md.w,
                  Text(
                    'Account Profile',
                    style: context.textTheme.bodyMedium?.medium().colour(
                      context.colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // PopupMenuItem<String>(
            //   value: 'settings',
            //   height: 42,
            //   child: Row(
            //     children: [
            //       Icon(
            //         Icons.tune_rounded,
            //         size: AppSpacing.lg + 2,
            //         color: context.colors.onSurfaceSecondary,
            //       ),
            //       AppSpacing.md.w,
            //       Text(
            //         'System Settings',
            //         style: context.textTheme.bodyMedium?.medium().colour(
            //           context.colors.onSurface,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              height: 42,
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: AppSpacing.lg + 2,
                    color: context.colors.error,
                  ),
                  AppSpacing.md.w,
                  Text(
                    'Sign Out',
                    style: context.textTheme.bodyMedium?.medium().colour(
                      context.colors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) async {
    final result = await AppPopup.showLogoutConfirmation(context);
    if (result?.action == PopupAction.confirm) {
      final signOut = await ref.read(authControllerProvider.notifier).signOut();
      if (signOut) {
        AppSnackbar.success("You have been logged out successfully.");
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      }
    }
  }
}

// ─── Command Palette Modal ───────────────────────────────────────────────────

class _CommandPaletteDialog extends StatefulWidget {
  final List<CustomDashboardMenuItem> menuItems;
  final ValueChanged<CustomDashboardMenuItem> onSelect;

  const _CommandPaletteDialog({
    required this.menuItems,
    required this.onSelect,
  });

  @override
  State<_CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<_CommandPaletteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');

  List<CustomDashboardMenuItem> _flatten(List<CustomDashboardMenuItem> items) {
    final list = <CustomDashboardMenuItem>[];
    for (final item in items) {
      if (!item.isDivider && item.route != null) {
        list.add(item);
      }
      if (item.hasChildren) {
        list.addAll(_flatten(item.children));
      }
    }
    return list;
  }

  @override
  void dispose() {
    _queryNotifier.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _flatten(widget.menuItems);

    return Dialog(
      backgroundColor: context.colors.surface,
      surfaceTintColor: context.colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Column(
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppTextField.search(
                controller: _searchCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search actions, fleet, trips, reports...',
                ),
                onChanged: (val) => _queryNotifier.value = val,
              ),
            ),
            Divider(
              height: 1,
              color: context.colors.borderLight.withValues(alpha: 0.8),
            ),
            // Results List
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  final filtered = query.isEmpty
                      ? allItems
                      : allItems.where((i) {
                          final q = query.toLowerCase();
                          return i.label.toLowerCase().contains(q) ||
                              (i.description?.toLowerCase().contains(q) ??
                                  false);
                        }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'No matching navigation items found',
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: context.colors.borderLight.withValues(alpha: 0.4),
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        dense: true,
                        leading: QuickContainer(
                          p: AppSpacing.xs + 2,
                          radius: AppRadius.sm,
                          color: context.colors.secondary.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            item.icon,
                            size: AppSpacing.lg + 2,
                            color: context.colors.secondary,
                          ),
                        ),
                        title: Text(
                          item.label,
                          style: context.textTheme.bodyMedium?.semiBold(),
                        ),
                        subtitle: item.description != null
                            ? Text(
                                item.description!,
                                style: context.textTheme.bodySmall
                                    ?.size(AppSpacing.md - 1)
                                    .colour(context.colors.onSurfaceSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: AppSpacing.md,
                          color: context.colors.onSurfaceSecondary,
                        ),
                        onTap: () => widget.onSelect(item),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
