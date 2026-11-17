import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import 'models.dart';

/// Enterprise-grade, modern collapsible admin sidebar.
///
/// Features:
/// - 100% theme-driven via [context.colors] and [context.textTheme] per rules.md
/// - Zero-layout-jump active indicators with left accent bar
/// - Synchronized enterprise dimensions (40px item height, 14px item label, 11px uppercase section headers)
/// - Nested tree guide lines for multi-level child items
/// - Flyout menus with full child navigation in collapsed rail mode
/// - Status badges and text tag pills ("NEW", "LIVE")
/// - Bottom user preview card & collapse toggle button
class CustomDashboardSidebar extends StatelessWidget {
  final List<CustomDashboardMenuItem> topItems;
  final List<CustomDashboardMenuItem> bottomItems;
  final String currentRoute;
  final ValueChanged<CustomDashboardMenuItem> onSelect;
  final Widget? brandTitle;
  final Widget? brandLogo;
  final String? versionTag;
  final bool isCollapsed;
  final Color? sideBarColor;
  final VoidCallback? onToggle;
  final Widget? bottomFooter;
  final double? width;
  final double minWidth;
  final double maxWidth;
  final double collapsedWidth;
  final bool isResizable;
  final bool isDragging;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;
  final ValueChanged<bool>? onDraggingChanged;

  const CustomDashboardSidebar({
    super.key,
    required this.topItems,
    required this.bottomItems,
    required this.currentRoute,
    required this.onSelect,
    this.brandTitle,
    this.brandLogo,
    this.versionTag = '',
    this.sideBarColor,
    this.isCollapsed = false,
    this.onToggle,
    this.bottomFooter,
    this.width,
    this.minWidth = 220.0,
    this.maxWidth = 380.0,
    this.collapsedWidth = 68.0,
    this.isResizable = true,
    this.isDragging = false,
    this.onDragUpdate,
    this.onDraggingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSideBarColor = sideBarColor ?? context.colors.backgroundDark;
    final effectiveWidth = isCollapsed ? collapsedWidth : (width ?? 260.0);

    return AnimatedContainer(
      duration: isDragging ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: effectiveWidth,
      decoration: BoxDecoration(
        color: effectiveSideBarColor,
        border: Border(
          right: BorderSide(
            color: context.colors.borderDark,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // ── Brand Header ──────────────────────────────────────────
              _SidebarBrand(
                isCollapsed: isCollapsed,
                title: brandTitle,
                logo: brandLogo,
                versionTag: versionTag,
                onToggle: onToggle,
              ),

              // ── Navigation Items List ────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.sm,
                    horizontal: AppSpacing.sm,
                  ),
                  itemCount: topItems.length,
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    return _SidebarItemTile(
                      key: ValueKey('${item.label}_${item.route}'),
                      item: item,
                      currentRoute: currentRoute,
                      onSelect: onSelect,
                      isCollapsed: isCollapsed,
                      sideBarColor: effectiveSideBarColor,
                    );
                  },
                ),
              ),

              // ── Bottom Pinned Section ────────────────────────────────
              if (bottomItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: context.colors.white.withValues(alpha: 0.08),
                      ),
                      AppSpacing.xs.h,
                      ...bottomItems.map(
                        (item) => _SidebarItemTile(
                          key: ValueKey('${item.label}_${item.route}'),
                          item: item,
                          currentRoute: currentRoute,
                          onSelect: onSelect,
                          isCollapsed: isCollapsed,
                          sideBarColor: effectiveSideBarColor,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Optional Bottom Footer ───────────────────────────────
              ?bottomFooter,
            ],
          ),

          // ── Draggable Resize Handle ────────────────────────────────
          if (isResizable)
            _SidebarResizeHandle(
              isCollapsed: isCollapsed,
              isDragging: isDragging,
              onDragStart: () => onDraggingChanged?.call(true),
              onDragUpdate: (details) => onDragUpdate?.call(details),
              onDragEnd: () => onDraggingChanged?.call(false),
            ),
        ],
      ),
    );
  }
}

// ─── Sidebar Resize Handle ───────────────────────────────────────────────────

class _SidebarResizeHandle extends StatefulWidget {
  final bool isCollapsed;
  final bool isDragging;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _SidebarResizeHandle({
    required this.isCollapsed,
    required this.isDragging,
    required this.onDragUpdate,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  final ValueNotifier<bool> _isHoveredNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: AppSpacing.sm,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => _isHoveredNotifier.value = true,
        onExit: (_) => _isHoveredNotifier.value = false,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => widget.onDragStart(),
          onHorizontalDragUpdate: widget.onDragUpdate,
          onHorizontalDragEnd: (_) => widget.onDragEnd(),
          onHorizontalDragCancel: () => widget.onDragEnd(),
          child: Container(
            width: AppSpacing.sm,
            alignment: Alignment.centerRight,
            color: context.colors.transparent,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isHoveredNotifier,
              builder: (context, isHovered, _) {
                final isHighlighted = isHovered || widget.isDragging;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: isHighlighted ? 2.5 : 1,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? context.colors.secondary
                        : context.colors.white.withValues(alpha: 0.08),
                    boxShadow: isHighlighted
                        ? [
                            BoxShadow(
                              color: context.colors.secondary.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Brand Header ─────────────────────────────────────────────────────────────

class _SidebarBrand extends StatelessWidget {
  final bool isCollapsed;
  final Widget? title;
  final Widget? logo;
  final String? versionTag;
  final VoidCallback? onToggle;

  const _SidebarBrand({
    required this.isCollapsed,
    required this.title,
    this.logo,
    this.versionTag,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Container(
        height: AppSpacing.xxxl * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.colors.borderDark,
              width: 1.0,
            ),
          ),
        ),
        child: Tooltip(
          message: 'Expand Sidebar',
          waitDuration: const Duration(milliseconds: 200),
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onToggle,
            borderRadius: AppRadius.mdRadius,
            child: logo != null
                ? SizedBox(
                    width: (AppSpacing.md * 3) + 4,
                    height: (AppSpacing.md * 3) + 4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        logo!,
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: QuickContainer(
                            h: AppSpacing.lg,
                            w: AppSpacing.lg,
                            radius: AppRadius.full,
                            color: context.colors.primary,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: AppSpacing.md,
                              color: context.colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : QuickContainer(
                    h: (AppSpacing.md * 3) + 4,
                    w: (AppSpacing.md * 3) + 4,
                    radius: AppRadius.md,
                    color: context.colors.primary,
                    border: Border.all(
                      color: context.colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.security_rounded,
                      color: context.colors.onPrimary,
                      size: AppSpacing.xl,
                    ),
                  ),
          ),
        ),
      );
    }

    return Container(
      height: AppSpacing.xxxl * 2,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderDark,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo or Default Enterprise Brand Mark (per rules.md §16)
          if (logo != null)
            logo!
          else
            QuickContainer(
              h: (AppSpacing.md * 3) + 4,
              w: (AppSpacing.md * 3) + 4,
              radius: AppRadius.md,
              color: context.colors.primary,
              border: Border.all(
                color: context.colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.security_rounded,
                color: context.colors.onPrimary,
                size: AppSpacing.xl,
              ),
            ),

          // App Name + Version Tag
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm + 2),
              child: Row(
                children: [
                  Expanded(
                    child:
                        title ??
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GuardUp Admin',
                              style: context.textTheme.titleSmall
                                  ?.size(AppSpacing.md + 3.5)
                                  .bold()
                                  .colour(context.colors.white)
                                  .textSpacing(-0.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Executive Console',
                              style: context.textTheme.bodySmall
                                  ?.size(AppSpacing.md)
                                  .medium()
                                  .colour(
                                    context.colors.onSurfaceSecondary
                                        .withValues(alpha: 0.85),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                  ),
                  if (versionTag != null && versionTag!.isNotEmpty) ...[
                    AppSpacing.xs.w,
                    QuickContainer(
                      px: AppSpacing.xs + 2,
                      py: (AppSpacing.xs / 2),
                      radius: AppRadius.full,
                      color: context.colors.white.withValues(alpha: 0.08),
                      child: Text(
                        versionTag!,
                        style: context.textTheme.labelSmall
                            ?.size(AppSpacing.md - 1)
                            .semiBold()
                            .colour(
                              context.colors.white.withValues(alpha: 0.75),
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Top Collapse Button (visible in expanded mode)
          if (onToggle != null) ...[
            AppSpacing.xs.w,
            Tooltip(
              message: 'Collapse Sidebar',
              waitDuration: const Duration(milliseconds: 200),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: onToggle,
                borderRadius: AppRadius.smRadius,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.menu_open_rounded,
                    size: AppSpacing.xl,
                    color: context.colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Helpers for Route Matching & Deep Active Checks ──────────────────────────

bool _isRouteMatching(String? route, String currentRoute) {
  if (route == null) return false;
  if (route == currentRoute) return true;
  if (route != AppRoutes.home && currentRoute.startsWith('$route/')) {
    return true;
  }
  return false;
}

bool _isItemOrDescendantActive(
  CustomDashboardMenuItem item,
  String currentRoute,
) {
  if (_isRouteMatching(item.route, currentRoute)) return true;
  for (final child in item.children) {
    if (_isItemOrDescendantActive(child, currentRoute)) return true;
  }
  return false;
}

bool _hasActiveDescendant(CustomDashboardMenuItem item, String currentRoute) {
  for (final child in item.children) {
    if (_isItemOrDescendantActive(child, currentRoute)) return true;
  }
  return false;
}

int _calculateTotalBadgeCount(CustomDashboardMenuItem item) {
  if (item.badgeCount > 0) return item.badgeCount;
  return item.children.fold(0, (sum, c) => sum + _calculateTotalBadgeCount(c));
}

// ─── Sidebar Item Tile (Handles Section Header + Leaf / Parent) ─────────────────

class _SidebarItemTile extends StatefulWidget {
  final CustomDashboardMenuItem item;
  final String currentRoute;
  final ValueChanged<CustomDashboardMenuItem> onSelect;
  final bool isCollapsed;
  final Color sideBarColor;
  final int depth;

  const _SidebarItemTile({
    super.key,
    required this.item,
    required this.currentRoute,
    required this.onSelect,
    required this.isCollapsed,
    required this.sideBarColor,
    this.depth = 0,
  });

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  late final ValueNotifier<bool> _isExpandedNotifier;

  bool get _isSelected =>
      _isRouteMatching(widget.item.route, widget.currentRoute);
  bool get _hasChildren => widget.item.hasChildren;
  bool get _childActive =>
      _hasActiveDescendant(widget.item, widget.currentRoute);

  @override
  void initState() {
    super.initState();
    _isExpandedNotifier = ValueNotifier<bool>(_childActive);
  }

  @override
  void didUpdateWidget(covariant _SidebarItemTile old) {
    super.didUpdateWidget(old);
    if (_childActive && !_isExpandedNotifier.value) {
      _isExpandedNotifier.value = true;
    }
  }

  @override
  void dispose() {
    _isExpandedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Pure Divider Item ──────────────────────────────────────────
    if (widget.item.isDivider) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Divider(
          height: 1,
          thickness: 1,
          color: context.colors.white.withValues(alpha: 0.08),
        ),
      );
    }

    // ── Section Header (Only at root level) ─────────────────────────
    Widget? sectionWidget;
    if (widget.depth == 0 && widget.item.sectionTitle != null) {
      if (widget.isCollapsed) {
        sectionWidget = Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Divider(
            height: 1,
            thickness: 1,
            color: context.colors.white.withValues(alpha: 0.08),
          ),
        );
      } else {
        sectionWidget = Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            top: AppSpacing.md + 4,
            bottom: AppSpacing.xs + 2,
          ),
          child: Text(
            widget.item.sectionTitle!.toUpperCase(),
            style: context.textTheme.labelSmall
                ?.size(AppSpacing.md - 1)
                .bold()
                .colour(context.colors.white.withValues(alpha: 0.45))
                .textSpacing(0.8),
          ),
        );
      }
    }

    final parentBadgeCount = _calculateTotalBadgeCount(widget.item);

    // ── Leaf Item (No Children) ────────────────────────────────────
    if (!_hasChildren) {
      final tile = widget.depth == 0
          ? _LeafTile(
              icon: widget.item.icon,
              label: widget.item.label,
              badgeCount: widget.item.badgeCount,
              badgeText: widget.item.badgeText,
              badgeColor: widget.item.badgeColor,
              trailing: widget.item.trailing,
              isSelected: _isSelected,
              isCollapsed: widget.isCollapsed,
              enabled: widget.item.enabled,
              onTap: widget.item.enabled
                  ? () => widget.onSelect(widget.item)
                  : null,
            )
          : _SubTile(
              item: widget.item,
              isSelected: _isSelected,
              depth: widget.depth,
              onTap: () => widget.onSelect(widget.item),
            );

      if (sectionWidget != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [sectionWidget, tile],
        );
      }
      return tile;
    }

    // ── Parent with Children in Collapsed Rail Mode (Flyout) ───────
    if (widget.isCollapsed) {
      final flyout = PopupMenuButton<CustomDashboardMenuItem>(
        offset: const Offset((AppSpacing.xxxl * 2) - 6, 0),
        surfaceTintColor: widget.sideBarColor,
        color: widget.sideBarColor,
        tooltip: widget.item.label,
        onSelected: widget.onSelect,
        elevation: AppSpacing.md,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdRadius,
          side: BorderSide(color: context.colors.white.withValues(alpha: 0.1)),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<CustomDashboardMenuItem>(
            enabled: false,
            height: AppSpacing.xxxl - AppSpacing.xs,
            child: Text(
              widget.item.label.toUpperCase(),
              style: context.textTheme.labelSmall
                  ?.size(AppSpacing.sm + 1.5)
                  .bold()
                  .colour(context.colors.primary)
                  .textSpacing(0.8),
            ),
          ),
          const PopupMenuDivider(height: 1),
          ..._buildFlyoutItems(
            context,
            widget.item.children,
            widget.currentRoute,
          ),
        ],
        child: _LeafTile(
          icon: widget.item.icon,
          label: widget.item.label,
          badgeCount: parentBadgeCount,
          isSelected: false,
          isCollapsed: widget.isCollapsed,
          isParent: true,
          isExpanded: false,
          childActive: _childActive,
          onTap: null,
        ),
      );

      if (sectionWidget != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [sectionWidget, flyout],
        );
      }
      return flyout;
    }

    // ── Parent with Children in Expanded Mode (Accordion + Guide Lines)
    final accordion = ValueListenableBuilder<bool>(
      valueListenable: _isExpandedNotifier,
      builder: (context, isExpanded, _) {
        final headerTile = widget.depth == 0
            ? _LeafTile(
                icon: widget.item.icon,
                label: widget.item.label,
                badgeCount: parentBadgeCount,
                badgeText: widget.item.badgeText,
                badgeColor: widget.item.badgeColor,
                trailing: widget.item.trailing,
                isSelected: _isSelected,
                isCollapsed: widget.isCollapsed,
                isParent: true,
                isExpanded: isExpanded,
                childActive: _childActive,
                onTap: () {
                  _isExpandedNotifier.value = !_isExpandedNotifier.value;
                },
              )
            : _SubParentTile(
                item: widget.item,
                isExpanded: isExpanded,
                childActive: _childActive,
                isSelected: _isSelected,
                depth: widget.depth,
                onTap: () {
                  _isExpandedNotifier.value = !_isExpandedNotifier.value;
                },
              );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            headerTile,
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: isExpanded
                  ? Container(
                      margin: EdgeInsets.only(
                        left: widget.depth == 0
                            ? AppSpacing.lg + 2
                            : AppSpacing.md + 4,
                        top: 1,
                        bottom: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: context.colors.white.withValues(alpha: 0.08),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Column(
                        children: widget.item.children
                            .map(
                              (child) => _SidebarItemTile(
                                key: ValueKey(
                                  '${child.label}_${child.route}_${widget.depth + 1}',
                                ),
                                item: child,
                                currentRoute: widget.currentRoute,
                                onSelect: widget.onSelect,
                                isCollapsed: false,
                                sideBarColor: widget.sideBarColor,
                                depth: widget.depth + 1,
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );

    if (sectionWidget != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [sectionWidget, accordion],
      );
    }
    return accordion;
  }

  List<PopupMenuEntry<CustomDashboardMenuItem>> _buildFlyoutItems(
    BuildContext context,
    List<CustomDashboardMenuItem> children,
    String currentRoute,
  ) {
    final entries = <PopupMenuEntry<CustomDashboardMenuItem>>[];

    for (int i = 0; i < children.length; i++) {
      final child = children[i];

      if (child.hasChildren) {
        if (entries.isNotEmpty) {
          entries.add(const PopupMenuDivider(height: 8));
        }
        entries.add(
          PopupMenuItem<CustomDashboardMenuItem>(
            enabled: false,
            height: AppSpacing.xxxl - AppSpacing.sm,
            child: Row(
              children: [
                Icon(
                  child.icon,
                  size: AppSpacing.md + 2,
                  color: context.colors.primary.withValues(alpha: 0.9),
                ),
                AppSpacing.xs.w,
                Text(
                  child.label.toUpperCase(),
                  style: context.textTheme.labelSmall
                      ?.size(AppSpacing.sm + 1)
                      .bold()
                      .colour(context.colors.primary)
                      .textSpacing(0.6),
                ),
              ],
            ),
          ),
        );

        for (final grandChild in child.children) {
          final isGrandChildSelected = _isRouteMatching(
            grandChild.route,
            currentRoute,
          );
          entries.add(
            PopupMenuItem<CustomDashboardMenuItem>(
              value: grandChild,
              height: AppSpacing.xxxl + 2,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      grandChild.icon,
                      size: AppSpacing.lg,
                      color: isGrandChildSelected
                          ? context.colors.primary
                          : context.colors.white.withValues(alpha: 0.7),
                    ),
                    AppSpacing.sm.w,
                    Expanded(
                      child: Text(
                        grandChild.label,
                        style:
                            (isGrandChildSelected
                                    ? context.textTheme.bodyMedium?.semiBold()
                                    : context.textTheme.bodyMedium?.medium())
                                ?.size(AppSpacing.md + 0.5)
                                .colour(
                                  isGrandChildSelected
                                      ? context.colors.white
                                      : context.colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                ),
                      ),
                    ),
                    if (grandChild.badgeCount > 0)
                      _buildBadge(context, count: grandChild.badgeCount),
                    if (grandChild.badgeText != null)
                      _buildTextBadge(context, text: grandChild.badgeText!),
                    if (isGrandChildSelected)
                      Container(
                        width: AppSpacing.xs + 1,
                        height: AppSpacing.xs + 1,
                        margin: const EdgeInsets.only(left: AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        final isChildSelected = _isRouteMatching(child.route, currentRoute);
        entries.add(
          PopupMenuItem<CustomDashboardMenuItem>(
            value: child,
            height: AppSpacing.xxxl + AppSpacing.xs,
            child: Row(
              children: [
                Icon(
                  child.icon,
                  size: AppSpacing.xl,
                  color: isChildSelected
                      ? context.colors.primary
                      : context.colors.white.withValues(alpha: 0.7),
                ),
                AppSpacing.sm.w,
                Expanded(
                  child: Text(
                    child.label,
                    style:
                        (isChildSelected
                                ? context.textTheme.bodyMedium?.semiBold()
                                : context.textTheme.bodyMedium?.medium())
                            ?.size(AppSpacing.md + 1)
                            .colour(
                              isChildSelected
                                  ? context.colors.white
                                  : context.colors.white.withValues(
                                      alpha: 0.85,
                                    ),
                            ),
                  ),
                ),
                if (child.badgeCount > 0)
                  _buildBadge(context, count: child.badgeCount),
                if (child.badgeText != null)
                  _buildTextBadge(context, text: child.badgeText!),
                if (isChildSelected)
                  Container(
                    width: AppSpacing.xs + 1,
                    height: AppSpacing.xs + 1,
                    margin: const EdgeInsets.only(left: AppSpacing.xs + 2),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }

    return entries;
  }

  Widget _buildBadge(BuildContext context, {required int count}) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs + 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: (AppSpacing.xs / 2) - 0.5,
      ),
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: context.textTheme.labelSmall
            ?.size(AppSpacing.sm + 1.5)
            .bold()
            .colour(context.colors.white),
      ),
    );
  }

  Widget _buildTextBadge(BuildContext context, {required String text}) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs + 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: (AppSpacing.xs / 2) - 0.5,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Text(
        text,
        style: context.textTheme.labelSmall
            ?.size(AppSpacing.sm + 1)
            .bold()
            .colour(context.colors.white),
      ),
    );
  }
}

// ─── Leaf Tile Widget ─────────────────────────────────────────────────────────

class _LeafTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? trailing;
  final bool isSelected;
  final bool isCollapsed;
  final bool isParent;
  final bool isExpanded;
  final bool childActive;
  final bool enabled;
  final VoidCallback? onTap;

  const _LeafTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    this.badgeCount = 0,
    this.badgeText,
    this.badgeColor,
    this.trailing,
    this.isParent = false,
    this.isExpanded = false,
    this.childActive = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<_LeafTile> createState() => _LeafTileState();
}

class _LeafTileState extends State<_LeafTile> {
  final ValueNotifier<bool> _hoveredNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colors.primary;
    final inactiveIcon = context.colors.onSurfaceSecondary.withValues(
      alpha: 0.85,
    );
    final inactiveLabel = context.colors.white.withValues(alpha: 0.85);
    final hoverColor = context.colors.white.withValues(alpha: 0.06);

    final isHighlighted = widget.isSelected || widget.childActive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: (AppSpacing.xs / 2) - 0.5),
      child: Tooltip(
        message: widget.isCollapsed ? widget.label : '',
        waitDuration: const Duration(milliseconds: 250),
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => _hoveredNotifier.value = true,
          onExit: (_) => _hoveredNotifier.value = false,
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: AppRadius.mdRadius,
            child: ValueListenableBuilder<bool>(
              valueListenable: _hoveredNotifier,
              builder: (context, hovered, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  height:
                      (AppSpacing.md * 3) +
                      4, // 40px standard enterprise height
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? activeColor.withValues(alpha: 0.14)
                        : hovered && widget.enabled
                        ? hoverColor
                        : context.colors.transparent,
                    borderRadius: AppRadius.mdRadius,
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // ── Left Active Indicator Bar (ZERO layout jump) ─────
                      if (!widget.isCollapsed && isHighlighted)
                        Positioned(
                          left: 0,
                          top: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          width: 3.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: AppRadius.fullRadius,
                            ),
                          ),
                        ),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isCollapsed ? 0 : AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: widget.isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            // Icon & Collapsed Indicator Dot
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  widget.icon,
                                  size: AppSpacing.xl,
                                  color: isHighlighted
                                      ? activeColor
                                      : hovered && widget.enabled
                                      ? context.colors.white
                                      : inactiveIcon,
                                ),
                                if (widget.isCollapsed &&
                                    (widget.badgeCount > 0 ||
                                        widget.badgeText != null))
                                  Positioned(
                                    top: -2,
                                    right: -3,
                                    child: Container(
                                      width: AppSpacing.xs + 2,
                                      height: AppSpacing.xs + 2,
                                      decoration: BoxDecoration(
                                        color:
                                            widget.badgeColor ??
                                            context.colors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // Expanded Details: Label + Badges + Trailing
                            if (!widget.isCollapsed) ...[
                              (AppSpacing.sm + 2).w,
                              Expanded(
                                child: Text(
                                  widget.label,
                                  style:
                                      (isHighlighted
                                              ? context.textTheme.bodyMedium
                                                    ?.semiBold()
                                              : context.textTheme.bodyMedium
                                                    ?.medium())
                                          ?.size(AppSpacing.md + 2) // 14px
                                          .colour(
                                            isHighlighted
                                                ? context.colors.white
                                                : hovered && widget.enabled
                                                ? context.colors.white
                                                : inactiveLabel,
                                          ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              if (widget.trailing != null) widget.trailing!,

                              // Text Tag Badge (e.g. "NEW")
                              if (widget.badgeText != null)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: AppSpacing.xs + 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs + 2,
                                    vertical: (AppSpacing.xs / 2) - 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.badgeColor ?? activeColor,
                                    borderRadius: AppRadius.fullRadius,
                                  ),
                                  child: Text(
                                    widget.badgeText!,
                                    style: context.textTheme.labelSmall
                                        ?.size(AppSpacing.sm + 1)
                                        .bold()
                                        .colour(context.colors.white),
                                  ),
                                ),

                              // Number Count Badge
                              if (widget.badgeCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(
                                    left: AppSpacing.xs + 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs + 2,
                                    vertical: (AppSpacing.xs / 2) - 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        widget.badgeColor ??
                                        context.colors.error,
                                    borderRadius: AppRadius.fullRadius,
                                  ),
                                  child: Text(
                                    widget.badgeCount > 99
                                        ? '99+'
                                        : '${widget.badgeCount}',
                                    style: context.textTheme.labelSmall
                                        ?.size(AppSpacing.sm + 1.5)
                                        .bold()
                                        .colour(context.colors.white),
                                  ),
                                ),

                              // Parent Chevron
                              if (widget.isParent) ...[
                                AppSpacing.xs.w,
                                AnimatedRotation(
                                  turns: widget.isExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOutCubic,
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    size: AppSpacing.lg,
                                    color: isHighlighted
                                        ? activeColor
                                        : context.colors.white.withValues(
                                            alpha: 0.45,
                                          ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-Parent Tile (Intermediate parent with children, e.g. depth >= 1) ─────

class _SubParentTile extends StatefulWidget {
  final CustomDashboardMenuItem item;
  final bool isExpanded;
  final bool childActive;
  final bool isSelected;
  final VoidCallback onTap;
  final int depth;

  const _SubParentTile({
    required this.item,
    required this.isExpanded,
    required this.childActive,
    required this.isSelected,
    required this.onTap,
    this.depth = 1,
  });

  @override
  State<_SubParentTile> createState() => _SubParentTileState();
}

class _SubParentTileState extends State<_SubParentTile> {
  final ValueNotifier<bool> _hoveredNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colors.primary;
    final inactiveIcon = context.colors.onSurfaceSecondary.withValues(
      alpha: 0.85,
    );
    final inactiveLabel = context.colors.white.withValues(alpha: 0.85);
    final hoverColor = context.colors.white.withValues(alpha: 0.05);

    final isHighlighted = widget.isSelected || widget.childActive;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.xs,
        top: 1,
        bottom: 1,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _hoveredNotifier.value = true,
        onExit: (_) => _hoveredNotifier.value = false,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.mdRadius,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hoveredNotifier,
            builder: (context, hovered, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? activeColor.withValues(alpha: 0.12)
                      : hovered
                      ? hoverColor
                      : context.colors.transparent,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: AppSpacing.lg,
                      color: isHighlighted
                          ? activeColor
                          : hovered
                          ? context.colors.white
                          : inactiveIcon,
                    ),
                    (AppSpacing.xs + 3).w,
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style:
                            (isHighlighted
                                    ? context.textTheme.bodySmall?.semiBold()
                                    : context.textTheme.bodySmall?.medium())
                                ?.size(AppSpacing.md + 1)
                                .colour(
                                  isHighlighted
                                      ? context.colors.white
                                      : hovered
                                      ? context.colors.white
                                      : inactiveLabel,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.item.badgeCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? context.colors.error,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          widget.item.badgeCount > 99
                              ? '99+'
                              : '${widget.item.badgeCount}',
                          style: context.textTheme.labelSmall
                              ?.size(AppSpacing.sm + 1)
                              .bold()
                              .colour(context.colors.white),
                        ),
                      ),
                    if (widget.item.badgeText != null)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? activeColor,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          widget.item.badgeText!,
                          style: context.textTheme.labelSmall
                              ?.size(AppSpacing.sm + 0.5)
                              .bold()
                              .colour(context.colors.white),
                        ),
                      ),
                    AppSpacing.xs.w,
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: AppSpacing.md + 2,
                        color: isHighlighted
                            ? activeColor
                            : context.colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Sub-Item Tile (Hierarchical leaf child inside accordion) ──────────────────

class _SubTile extends StatefulWidget {
  final CustomDashboardMenuItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final int depth;

  const _SubTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
    this.depth = 1,
  });

  @override
  State<_SubTile> createState() => _SubTileState();
}

class _SubTileState extends State<_SubTile> {
  final ValueNotifier<bool> _hoveredNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hoveredNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colors.primary;
    final inactiveIcon = context.colors.onSurfaceSecondary.withValues(
      alpha: 0.80,
    );
    final inactiveLabel = context.colors.white.withValues(alpha: 0.75);
    final hoverColor = context.colors.white.withValues(alpha: 0.04);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        right: AppSpacing.xs,
        top: 1,
        bottom: 1,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _hoveredNotifier.value = true,
        onExit: (_) => _hoveredNotifier.value = false,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.mdRadius,
          child: ValueListenableBuilder<bool>(
            valueListenable: _hoveredNotifier,
            builder: (context, hovered, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.sm - 2,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? activeColor.withValues(alpha: 0.14)
                      : hovered
                      ? hoverColor
                      : context.colors.transparent,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: widget.depth > 1
                          ? AppSpacing.md + 1
                          : AppSpacing.lg,
                      color: widget.isSelected
                          ? activeColor
                          : hovered
                          ? context.colors.white
                          : inactiveIcon,
                    ),
                    (AppSpacing.xs + 3).w,
                    Expanded(
                      child: Text(
                        widget.item.label,
                        style:
                            (widget.isSelected
                                    ? context.textTheme.bodySmall?.semiBold()
                                    : context.textTheme.bodySmall?.medium())
                                ?.size(
                                  widget.depth > 1
                                      ? AppSpacing.md
                                      : AppSpacing.md + 1,
                                )
                                .colour(
                                  widget.isSelected
                                      ? context.colors.white
                                      : hovered
                                      ? context.colors.white
                                      : inactiveLabel,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.item.badgeCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? context.colors.error,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          widget.item.badgeCount > 99
                              ? '99+'
                              : '${widget.item.badgeCount}',
                          style: context.textTheme.labelSmall
                              ?.size(AppSpacing.sm + 1)
                              .bold()
                              .colour(context.colors.white),
                        ),
                      ),
                    if (widget.item.badgeText != null)
                      Container(
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: widget.item.badgeColor ?? activeColor,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          widget.item.badgeText!,
                          style: context.textTheme.labelSmall
                              ?.size(AppSpacing.sm + 0.5)
                              .bold()
                              .colour(context.colors.white),
                        ),
                      ),
                    if (widget.isSelected)
                      Container(
                        width: AppSpacing.xs,
                        height: AppSpacing.xs,
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── AppBar Actions Container ─────────────────────────────────────────────────

/// Wraps header action widgets in a clean, spaced row.
class AppBarActions extends StatelessWidget {
  final List<Widget> actions;
  const AppBarActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}
