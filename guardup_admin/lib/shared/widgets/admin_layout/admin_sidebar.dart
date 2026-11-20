import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../buttons/app_icon_button.dart';
import '../misc/app_logo.dart';
import 'admin_sidebar_tile.dart';
import 'models.dart';

/// Navigation sidebar for the admin console.
///
/// Renders [sections] as titled groups of [AdminSidebarTile]s, pinned
/// [footerItems] at the bottom and an optional [footer] (e.g. version label).
/// Fills its parent; width, collapse state and resizing are owned by
/// `AdminScaffold`. Colors come from the ambient theme, so wrapping it in the
/// dark theme gives the always-dark console look in both app modes.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.sections,
    required this.location,
    required this.onSelect,
    this.footerItems = const [],
    this.isCollapsed = false,
    this.onToggle,
    this.toggleIcon = Icons.keyboard_double_arrow_left_rounded,
    this.toggleTooltip = 'Collapse sidebar',
    this.brand,
    this.footer,
  });

  final List<AdminNavSection> sections;
  final List<AdminNavItem> footerItems;
  final String location;
  final ValueChanged<AdminNavItem> onSelect;

  /// Icon-only rail mode.
  final bool isCollapsed;

  /// Collapse / close handler shown in the header. In rail mode the brand
  /// mark itself becomes the expand trigger.
  final VoidCallback? onToggle;
  final IconData toggleIcon;
  final String toggleTooltip;

  /// Replaces the default brand block (logo, product name, caption).
  final Widget? brand;

  /// Pinned below [footerItems]; hidden in rail mode.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final horizontalInset = isCollapsed ? AppSpacing.md : AppSpacing.sm + 2;

    return QuickContainer(
      color: colors.surface,
      border: Border(right: BorderSide(color: colors.borderLight)),
      child: Column(
        children: [
          _SidebarHeader(
            isCollapsed: isCollapsed,
            brand: brand,
            onToggle: onToggle,
            toggleIcon: toggleIcon,
            toggleTooltip: toggleTooltip,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                AppSpacing.sm,
                horizontalInset,
                AppSpacing.lg,
              ),
              children: [
                for (final (index, section) in sections.indexed) ...[
                  if (section.title != null || index > 0)
                    _SectionHeader(
                      title: section.title,
                      isCollapsed: isCollapsed,
                      isFirst: index == 0,
                    ),
                  for (final item in section.items)
                    AdminSidebarTile(
                      key: ValueKey(item.route ?? item.label),
                      item: item,
                      location: location,
                      onSelect: onSelect,
                      isCollapsed: isCollapsed,
                    ),
                ],
              ],
            ),
          ),
          if (footerItems.isNotEmpty || (footer != null && !isCollapsed))
            QuickContainer(
              px: horizontalInset,
              py: AppSpacing.sm,
              border: Border(top: BorderSide(color: colors.borderLight)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in footerItems)
                    AdminSidebarTile(
                      key: ValueKey(item.route ?? item.label),
                      item: item,
                      location: location,
                      onSelect: onSelect,
                      isCollapsed: isCollapsed,
                    ),
                  if (footer != null && !isCollapsed) footer!,
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isCollapsed,
    required this.brand,
    required this.onToggle,
    required this.toggleIcon,
    required this.toggleTooltip,
  });

  final bool isCollapsed;
  final Widget? brand;
  final VoidCallback? onToggle;
  final IconData toggleIcon;
  final String toggleTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = Border(bottom: BorderSide(color: colors.borderLight));

    if (isCollapsed) {
      return QuickContainer(
        h: AppLayout.topBarHeight,
        alignment: Alignment.center,
        border: border,
        child: Tooltip(
          message: 'Expand sidebar',
          child: InkWell(
            onTap: onToggle,
            borderRadius: AppRadius.mdRadius,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: AppLogo(size: AppLayout.brandMarkSize),
            ),
          ),
        ),
      );
    }

    return QuickContainer(
      h: AppLayout.topBarHeight,
      pl: AppSpacing.lg,
      pr: AppSpacing.sm + 2,
      border: border,
      child: Row(
        children: [
          Expanded(child: brand ?? const _DefaultBrand()),
          if (onToggle != null)
            AppIconButton(
              icon: toggleIcon,
              tooltip: toggleTooltip,
              variant: AppIconButtonVariant.ghost,
              size: AppIconButtonSize.small,
              foregroundColor: colors.onSurfaceSecondary,
              onPressed: onToggle,
            ),
        ],
      ),
    );
  }
}

class _DefaultBrand extends StatelessWidget {
  const _DefaultBrand();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        const AppLogo(size: AppLayout.brandMarkSize),
        (AppSpacing.sm + 2).w,
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GuardUp',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleSmall
                    ?.bold()
                    .textSpacing(-0.2)
                    .colour(colors.onSurface),
              ),
              Text(
                'Admin Console',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.medium().colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isCollapsed,
    required this.isFirst,
  });

  final String? title;
  final bool isCollapsed;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedSwitcher(
      duration: AppDurations.fast,
      child: isCollapsed || title == null
          ? Padding(
              key: const ValueKey('divider'),
              padding: EdgeInsets.symmetric(
                vertical: isFirst ? AppSpacing.xs : AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              child: isFirst
                  ? const SizedBox.shrink()
                  : Divider(height: 1, color: colors.borderLight),
            )
          : Padding(
              key: const ValueKey('title'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                isFirst ? AppSpacing.sm : AppSpacing.lg + 2,
                AppSpacing.md,
                AppSpacing.xs + 2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title!.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall
                      ?.bold()
                      .textSpacing(0.9)
                      .colour(colors.onSurfaceSecondary.withValues(alpha: 0.7)),
                ),
              ),
            ),
    );
  }
}
