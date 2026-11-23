import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/app/routes/admin_navigation.dart';
import '/core/constants/app_spacing.dart';
import '/core/constants/app_strings.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/admin_layout/admin_command_palette.dart';
import '/shared/widgets/admin_layout/admin_scaffold.dart';
import 'widgets/shell_account_menu.dart';
import 'widgets/shell_notification_button.dart';
import 'widgets/shell_theme_menu.dart';

/// Authenticated shell around every admin page.
///
/// Binds [AdminScaffold] to go_router: the current location drives the
/// sidebar highlight, breadcrumbs and page title (all derived from
/// [AdminNavigation]), and the routed page is rendered as the body.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    void navigate(String route) {
      if (route != location) context.go(route);
    }

    return AdminScaffold(
      sections: AdminNavigation.sections,
      footerItems: AdminNavigation.footerItems,
      location: location,
      page: AdminNavigation.pageFor(location),
      onNavigate: navigate,
      onSearch: () => AdminCommandPalette.show(
        context,
        sections: AdminNavigation.searchable,
        onSelect: (item) {
          if (item.route != null) navigate(item.route!);
        },
      ),
      topBarActions: const [
        ShellNotificationButton(),
        ShellThemeMenu(),
        _ActionDivider(),
        ShellAccountMenu(),
      ],
      sidebarFooter: const _VersionLabel(),
      body: navigationShell,
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.xxl,
      child: VerticalDivider(width: 1, color: context.colors.borderLight),
    );
  }
}

class _VersionLabel extends StatelessWidget {
  const _VersionLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${AppStrings.appName} · v${AppStrings.appVersion}',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onSurfaceSecondary.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
