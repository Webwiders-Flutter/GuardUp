import 'package:flutter/material.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/menu.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../misc/app_badge.dart';
import '../misc/app_hover_builder.dart';
import 'models.dart';

/// One navigation entry in [AdminSidebar], at any depth.
///
/// - Leaf items navigate on tap.
/// - Groups expand inline as an accordion with a guide line; they open
///   automatically when one of their descendants becomes active.
/// - In the collapsed rail, groups open a flyout menu to the right.
class AdminSidebarTile extends StatefulWidget {
  const AdminSidebarTile({
    super.key,
    required this.item,
    required this.location,
    required this.onSelect,
    this.isCollapsed = false,
    this.depth = 0,
  });

  final AdminNavItem item;
  final String location;
  final ValueChanged<AdminNavItem> onSelect;
  final bool isCollapsed;
  final int depth;

  @override
  State<AdminSidebarTile> createState() => _AdminSidebarTileState();
}

class _AdminSidebarTileState extends State<AdminSidebarTile> {
  late final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(
    widget.item.hasActiveDescendant(widget.location),
  );

  @override
  void didUpdateWidget(covariant AdminSidebarTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routeChanged = oldWidget.location != widget.location;
    if (routeChanged && widget.item.hasActiveDescendant(widget.location)) {
      _isExpandedNotifier.value = true;
    }
  }

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  void _toggle() => _isExpandedNotifier.value = !_isExpandedNotifier.value;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isSelected = item.matches(widget.location);
    final hasActiveChild = item.hasActiveDescendant(widget.location);

    if (!item.hasChildren) {
      return _NavRow(
        item: item,
        depth: widget.depth,
        isCollapsed: widget.isCollapsed,
        isSelected: isSelected,
        onTap: item.enabled ? () => widget.onSelect(item) : null,
      );
    }

    if (widget.isCollapsed) {
      return Builder(
        builder: (anchor) => _NavRow(
          item: item,
          depth: widget.depth,
          isCollapsed: true,
          isSelected: false,
          isAncestorActive: hasActiveChild,
          onTap: () => _openFlyout(anchor),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpandedNotifier,
      builder: (context, isExpanded, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavRow(
              item: item,
              depth: widget.depth,
              isCollapsed: false,
              isSelected: isSelected,
              isAncestorActive: hasActiveChild,
              isExpanded: isExpanded,
              onTap: item.enabled ? _toggle : null,
            ),
            AnimatedSize(
              duration: AppDurations.normal,
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? _ChildList(
                      depth: widget.depth,
                      children: [
                        for (final child in item.children)
                          AdminSidebarTile(
                            key: ValueKey(child.route ?? child.label),
                            item: child,
                            location: widget.location,
                            onSelect: widget.onSelect,
                            depth: widget.depth + 1,
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFlyout(BuildContext anchor) async {
    final selected = await anchor.showAnchoredMenu<AdminNavItem>(
      placement: MenuPlacement.end,
      constraints: const BoxConstraints(
        minWidth: AppLayout.sidebarMinWidth,
        maxWidth: AppLayout.sidebarMaxWidth,
      ),
      items: [
        _FlyoutHeader(label: widget.item.label),
        const PopupMenuDivider(height: 1),
        ..._flyoutEntries(widget.item.children, nested: false),
      ],
    );
    if (selected != null) widget.onSelect(selected);
  }

  List<PopupMenuEntry<AdminNavItem>> _flyoutEntries(
    List<AdminNavItem> items, {
    required bool nested,
  }) {
    return [
      for (final child in items)
        if (child.hasChildren) ...[
          _FlyoutHeader(label: child.label, icon: child.icon),
          ..._flyoutEntries(child.children, nested: true),
        ] else
          PopupMenuItem<AdminNavItem>(
            value: child,
            enabled: child.enabled,
            height: AppLayout.menuItemHeight,
            padding: EdgeInsets.only(
              left: nested ? AppSpacing.xl : AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: _FlyoutItem(
              item: child,
              isSelected: child.matches(widget.location),
            ),
          ),
    ];
  }
}

// ─── Row ─────────────────────────────────────────────────────────────────────

/// Visual row shared by every sidebar entry. Sizing follows [depth]; the
/// collapsed rail renders an icon-only square with a tooltip.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.item,
    required this.depth,
    required this.isCollapsed,
    required this.isSelected,
    required this.onTap,
    this.isAncestorActive = false,
    this.isExpanded,
  });

  final AdminNavItem item;
  final int depth;
  final bool isCollapsed;
  final bool isSelected;
  final bool isAncestorActive;

  /// Null for leaf rows; the expansion state for group rows.
  final bool? isExpanded;
  final VoidCallback? onTap;

  bool get _isNested => depth > 0;
  bool get _isEmphasized => isSelected || isAncestorActive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onTap != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: AppHoverBuilder(
        enabled: enabled,
        cursor: SystemMouseCursors.click,
        builder: (context, isHovered, _) {
          final Color background;
          if (isSelected || (isCollapsed && isAncestorActive)) {
            background = colors.primary.withValues(alpha: 0.14);
          } else if (isHovered) {
            background = colors.onSurface.withValues(alpha: 0.06);
          } else {
            background = colors.transparent;
          }

          final Color iconColor = _isEmphasized
              ? colors.primary
              : isHovered
              ? colors.onSurface
              : colors.onSurfaceSecondary;

          final Color labelColor = _isEmphasized || isHovered
              ? colors.onSurface
              : colors.onSurface.withValues(alpha: 0.78);

          final row = AnimatedContainer(
            duration: AppDurations.instant,
            height: _isNested
                ? AppLayout.navSubItemHeight
                : AppLayout.navItemHeight,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.mdRadius,
                hoverColor: colors.transparent,
                mouseCursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: isCollapsed
                    ? _buildRailContent(context, iconColor)
                    : _buildContent(context, iconColor, labelColor),
              ),
            ),
          );

          return Opacity(opacity: item.enabled ? 1 : 0.45, child: row);
        },
      ),
    );
  }

  Widget _buildRailContent(BuildContext context, Color iconColor) {
    final badgeCount = item.totalBadgeCount;
    final hasBadge = badgeCount > 0 || item.badgeText != null;

    return Tooltip(
      message: item.label,
      preferBelow: false,
      waitDuration: AppDurations.medium,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(item.icon, size: AppLayout.iconLg, color: iconColor),
            if (hasBadge)
              Positioned(
                top: -AppSpacing.xs / 2,
                right: -AppSpacing.xs,
                child: AppBadge.dot(
                  color: item.badgeColor,
                  ringColor: context.colors.surface,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color iconColor,
    Color labelColor,
  ) {
    final colors = context.colors;
    final baseStyle = _isNested
        ? context.textTheme.bodySmall?.size(AppSpacing.md + 1)
        : context.textTheme.bodyMedium;
    final labelStyle =
        (_isEmphasized ? baseStyle?.semiBold() : baseStyle?.medium())?.colour(
          labelColor,
        );

    final badgeCount = isExpanded == true
        ? item.badgeCount
        : item.totalBadgeCount;

    // Expand to the row's fixed height so the content centres vertically.
    return Stack(
      clipBehavior: Clip.none,
      alignment: AlignmentDirectional.centerStart,
      fit: StackFit.expand,
      children: [
        // Active indicator: a bar inside top-level rows, a marker on the
        // guide line for nested rows.
        if (isSelected)
          Positioned(
            // Nested rows sit `xs` right of the 1px guide line (_ChildList).
            left: _isNested ? -(AppSpacing.xs + 1.5) : 0,
            top: _isNested ? AppSpacing.xs + 2 : AppSpacing.sm + 2,
            bottom: _isNested ? AppSpacing.xs + 2 : AppSpacing.sm + 2,
            width: _isNested ? 2 : 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: AppRadius.fullRadius,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(
            left: _isNested ? AppSpacing.sm + 2 : AppSpacing.md,
            right: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: _isNested ? AppLayout.iconSm : AppLayout.iconLg,
                color: iconColor,
              ),
              (_isNested ? AppSpacing.sm : AppSpacing.md).w,
              Expanded(
                child: Text(
                  item.label,
                  style: labelStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badgeText != null) ...[
                AppSpacing.xs.w,
                AppBadge(
                  label: item.badgeText!,
                  color: item.badgeColor ?? colors.primary,
                ),
              ],
              if (badgeCount > 0) ...[
                AppSpacing.xs.w,
                AppBadge.count(badgeCount, color: item.badgeColor),
              ],
              if (isExpanded != null) ...[
                AppSpacing.xs.w,
                AnimatedRotation(
                  turns: isExpanded! ? 0.25 : 0,
                  duration: AppDurations.fast,
                  curve: Curves.easeInOutCubic,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: AppLayout.iconSm,
                    color: colors.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Nested children container (guide line) ─────────────────────────────────

class _ChildList extends StatelessWidget {
  const _ChildList({required this.depth, required this.children});

  final int depth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Align the guide line with the centre of the parent's icon.
    final indent = depth == 0
        ? AppSpacing.md + (AppLayout.iconLg / 2)
        : AppSpacing.sm + 2 + (AppLayout.iconSm / 2);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: indent, top: 1, bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: context.colors.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

// ─── Rail flyout entries ─────────────────────────────────────────────────────

class _FlyoutHeader extends PopupMenuEntry<AdminNavItem> {
  const _FlyoutHeader({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  double get height => AppLayout.controlHeightSm;

  @override
  bool represents(AdminNavItem? value) => false;

  @override
  State<_FlyoutHeader> createState() => _FlyoutHeaderState();
}

class _FlyoutHeaderState extends State<_FlyoutHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: AppLayout.iconXs,
              color: context.colors.primary,
            ),
            AppSpacing.xs.w,
          ],
          Text(
            widget.label.toUpperCase(),
            style: context.textTheme.labelSmall
                ?.bold()
                .textSpacing(0.8)
                .colour(context.colors.primary),
          ),
        ],
      ),
    );
  }
}

class _FlyoutItem extends StatelessWidget {
  const _FlyoutItem({required this.item, required this.isSelected});

  final AdminNavItem item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(
          item.icon,
          size: AppLayout.iconMd,
          color: isSelected ? colors.primary : colors.onSurfaceSecondary,
        ),
        AppSpacing.sm.w,
        Expanded(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (isSelected
                        ? context.textTheme.bodyMedium?.semiBold()
                        : context.textTheme.bodyMedium?.medium())
                    ?.colour(colors.onSurface),
          ),
        ),
        if (item.badgeCount > 0) ...[
          AppSpacing.xs.w,
          AppBadge.count(item.badgeCount, color: item.badgeColor),
        ],
        if (isSelected) ...[
          AppSpacing.sm.w,
          AppBadge.dot(color: colors.primary),
        ],
      ],
    );
  }
}
