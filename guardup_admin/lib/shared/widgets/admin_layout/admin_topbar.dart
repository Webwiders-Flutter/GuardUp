import 'package:flutter/foundation.dart';
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
import '../misc/app_hover_builder.dart';
import 'models.dart';

/// Shell top bar: breadcrumb trail for the current page, quick-search trigger and
/// trailing [actions] (theme switcher, account menu, ...).
///
/// In [isCompact] mode (phones) the trail keeps its last two crumbs, the
/// search pill becomes an icon, and [leading] typically holds the drawer
/// menu button.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({
    super.key,
    required this.page,
    this.leading,
    this.actions = const [],
    this.onSearchTap,
    this.searchHint = 'Search pages…',
    this.onNavigate,
    this.isCompact = false,
  });

  final AdminPageMeta page;
  final Widget? leading;
  final List<Widget> actions;

  /// Opens the command palette. Hides the search trigger when null.
  final VoidCallback? onSearchTap;
  final String searchHint;

  /// Called with a breadcrumb's route when it is tapped.
  final ValueChanged<String>? onNavigate;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      h: AppLayout.topBarHeight,
      px: isCompact ? AppSpacing.md : AppSpacing.xxl,
      color: colors.surface,
      border: Border(bottom: BorderSide(color: colors.borderLight)),
      child: Row(
        children: [
          if (leading != null) ...[leading!, AppSpacing.md.w],
          Expanded(
            child: _PageHeading(
              page: page,
              isCompact: isCompact,
              onNavigate: onNavigate,
            ),
          ),
          if (onSearchTap != null) ...[
            AppSpacing.lg.w,
            if (isCompact)
              AppIconButton(
                icon: Icons.search_rounded,
                tooltip: 'Search',
                onPressed: onSearchTap,
              )
            else
              _SearchTrigger(hint: searchHint, onTap: onSearchTap!),
          ],
          for (final action in actions) ...[AppSpacing.sm.w, action],
        ],
      ),
    );
  }
}

// ─── Heading (breadcrumb trail) ──────────────────────────────────────────────

/// The top bar's only heading: the breadcrumb trail, ending in the current
/// page (emphasized). Compact layouts keep the last two crumbs so the page
/// stays identifiable ("Bodyguards › Pending").
class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.page,
    required this.isCompact,
    required this.onNavigate,
  });

  final AdminPageMeta page;
  final bool isCompact;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final crumbs = page.breadcrumbs.isEmpty
        ? <BreadcrumbItem>[(label: page.title, route: null, icon: page.icon)]
        : page.breadcrumbs;
    final visible = isCompact && crumbs.length > 2
        ? crumbs.sublist(crumbs.length - 2)
        : crumbs;

    return Tooltip(
      message: page.description ?? '',
      waitDuration: const Duration(seconds: 1),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedSwitcher(
          duration: AppDurations.fast,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previous, ?current],
          ),
          child: _Breadcrumbs(
            key: ValueKey(visible.map((crumb) => crumb.label).join('/')),
            items: visible,
            onNavigate: onNavigate,
          ),
        ),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({
    super.key,
    required this.items,
    required this.onNavigate,
  });

  final List<BreadcrumbItem> items;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final leadingIcon = items.first.icon;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: AppLayout.iconSm,
              color: colors.onSurfaceSecondary,
            ),
            (AppSpacing.xs + 2).w,
          ],
          for (final (index, crumb) in items.indexed) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: AppLayout.iconSm,
                  color: colors.onSurfaceSecondary.withValues(alpha: 0.6),
                ),
              ),
            _Crumb(
              crumb: crumb,
              isLast: index == items.length - 1,
              onNavigate: onNavigate,
            ),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.crumb,
    required this.isLast,
    required this.onNavigate,
  });

  final BreadcrumbItem crumb;
  final bool isLast;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final route = crumb.route;
    final isLink = !isLast && route != null && onNavigate != null;

    if (!isLink) {
      return Text(
        crumb.label,
        style: isLast
            ? context.textTheme.bodyMedium?.semiBold().colour(colors.onSurface)
            : context.textTheme.bodyMedium?.medium().colour(
                colors.onSurfaceSecondary,
              ),
      );
    }

    return AppHoverBuilder(
      cursor: SystemMouseCursors.click,
      builder: (context, isHovered, _) => GestureDetector(
        onTap: () => onNavigate!(route),
        child: Text(
          crumb.label,
          style: context.textTheme.bodyMedium?.medium().colour(
            isHovered ? colors.primary : colors.onSurfaceSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Search trigger ──────────────────────────────────────────────────────────

class _SearchTrigger extends StatelessWidget {
  const _SearchTrigger({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppHoverBuilder(
      cursor: SystemMouseCursors.click,
      builder: (context, isHovered, _) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdRadius,
          child: AnimatedContainer(
            duration: AppDurations.instant,
            width: AppLayout.searchTriggerWidth,
            height: AppLayout.controlHeight,
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: AppRadius.mdRadius,
              border: Border.all(
                color: isHovered
                    ? colors.primary.withValues(alpha: 0.45)
                    : colors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: AppLayout.iconSm,
                  color: colors.onSurfaceSecondary,
                ),
                AppSpacing.sm.w,
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall
                        ?.size(AppSpacing.md + 1)
                        .colour(colors.onSurfaceSecondary),
                  ),
                ),
                _KeyCap(label: _isApple ? '⌘K' : 'Ctrl K'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      px: AppSpacing.xs + 2,
      py: 2,
      radius: AppRadius.xs + 2,
      color: colors.surface,
      border: Border.all(color: colors.borderLight),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.semiBold().colour(
          colors.onSurfaceSecondary,
        ),
      ),
    );
  }
}
