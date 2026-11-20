import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/app/theme/app_theme.dart';
import '/core/constants/app_durations.dart';
import '/core/constants/app_layout.dart';
import '/core/constants/app_radius.dart';
import '../../../core/extensions/context.extension.dart';
import '../buttons/app_icon_button.dart';
import '../misc/app_hover_builder.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';
import 'models.dart';

/// Responsive frame of the admin console: sidebar + top bar + page body.
///
/// | Viewport width             | Sidebar                                   |
/// |----------------------------|-------------------------------------------|
/// | < [AppLayout.compactBreakpoint]  | Slide-in drawer, opened from the top bar  |
/// | < [AppLayout.expandedBreakpoint] | Icon rail by default                      |
/// | ≥ [AppLayout.expandedBreakpoint] | Expanded by default, drag-to-resize       |
///
/// The user's collapse choice and dragged width override the defaults for the
/// lifetime of the shell. Only the sidebar subtree rebuilds while resizing;
/// the top bar and [body] are untouched.
///
/// When [onSearch] is set, ⌘K / Ctrl+K anywhere in the shell triggers it.
class AdminScaffold extends StatefulWidget {
  const AdminScaffold({
    super.key,
    required this.sections,
    required this.location,
    required this.page,
    required this.onNavigate,
    required this.body,
    this.footerItems = const [],
    this.topBarActions = const [],
    this.onSearch,
    this.sidebarBrand,
    this.sidebarFooter,
    this.banner,
  });

  final List<AdminNavSection> sections;
  final List<AdminNavItem> footerItems;

  /// Current router location, used for active-state highlighting.
  final String location;
  final AdminPageMeta page;

  /// Navigates to a route (sidebar items, breadcrumbs).
  final ValueChanged<String> onNavigate;
  final Widget body;
  final List<Widget> topBarActions;
  final VoidCallback? onSearch;
  final Widget? sidebarBrand;
  final Widget? sidebarFooter;

  /// Full-width strip above everything (environment, maintenance notices).
  final Widget? banner;

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// `null` until the user collapses/expands manually; then it wins over the
  /// breakpoint default.
  final ValueNotifier<bool?> _collapsedOverrideNotifier = ValueNotifier(null);
  final ValueNotifier<double> _widthNotifier = ValueNotifier(
    AppLayout.sidebarWidth,
  );
  final ValueNotifier<bool> _isResizingNotifier = ValueNotifier(false);

  /// Unclamped pointer-following width during a drag, so slow drags still
  /// cross the snap-to-rail threshold.
  double _dragWidth = 0;

  @override
  void dispose() {
    _collapsedOverrideNotifier.dispose();
    _widthNotifier.dispose();
    _isResizingNotifier.dispose();
    super.dispose();
  }

  bool _isCollapsed(double viewportWidth) =>
      _collapsedOverrideNotifier.value ??
      viewportWidth < AppLayout.expandedBreakpoint;

  double _maxWidth(double viewportWidth) =>
      math.min(AppLayout.sidebarMaxWidth, viewportWidth * 0.4);

  void _toggleCollapsed(double viewportWidth) {
    _collapsedOverrideNotifier.value = !_isCollapsed(viewportWidth);
  }

  void _onResizeStart(double viewportWidth) {
    _dragWidth = _isCollapsed(viewportWidth)
        ? AppLayout.sidebarRailWidth
        : _widthNotifier.value;
    _isResizingNotifier.value = true;
  }

  void _onResizeUpdate(double dx, double viewportWidth) {
    _dragWidth += dx;
    const snapThreshold =
        (AppLayout.sidebarRailWidth + AppLayout.sidebarMinWidth) / 2;

    if (_dragWidth < snapThreshold) {
      _collapsedOverrideNotifier.value = true;
      return;
    }
    _collapsedOverrideNotifier.value = false;
    _widthNotifier.value = _dragWidth.clamp(
      AppLayout.sidebarMinWidth,
      _maxWidth(viewportWidth),
    );
  }

  void _onResizeEnd() => _isResizingNotifier.value = false;

  void _handleSelect(AdminNavItem item, {required bool closeDrawer}) {
    if (closeDrawer) _scaffoldKey.currentState?.closeDrawer();
    if (item.onTap != null) {
      item.onTap!();
    } else if (item.route != null) {
      widget.onNavigate(item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final isCompact = viewportWidth < AppLayout.compactBreakpoint;

        Widget scaffold = Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: false,
          backgroundColor: context.colors.backgroundLight,
          drawer: isCompact ? _buildDrawer(context) : null,
          body: Column(
            children: [
              ?widget.banner,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isCompact) _buildDockedSidebar(viewportWidth),
                    Expanded(
                      child: Column(
                        children: [
                          SafeArea(
                            bottom: false,
                            left: isCompact,
                            child: AdminTopBar(
                              page: widget.page,
                              isCompact: isCompact,
                              onNavigate: widget.onNavigate,
                              onSearchTap: widget.onSearch,
                              actions: widget.topBarActions,
                              leading: isCompact
                                  ? AppIconButton(
                                      icon: Icons.menu_rounded,
                                      tooltip: 'Open menu',
                                      onPressed: () => _scaffoldKey.currentState
                                          ?.openDrawer(),
                                    )
                                  : null,
                            ),
                          ),
                          Expanded(child: widget.body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        if (widget.onSearch != null) {
          scaffold = CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                  widget.onSearch!,
              const SingleActivator(LogicalKeyboardKey.keyK, control: true):
                  widget.onSearch!,
            },
            child: Focus(autofocus: true, child: scaffold),
          );
        }

        return scaffold;
      },
    );
  }

  /// The sidebar always renders with dark-theme tokens so it reads as the
  /// console's dark rail in both light and dark app modes.
  Widget _themedSidebar({
    required bool isCollapsed,
    required VoidCallback onToggle,
    required bool closeDrawerOnSelect,
    IconData toggleIcon = Icons.keyboard_double_arrow_left_rounded,
    String toggleTooltip = 'Collapse sidebar',
  }) {
    return Theme(
      data: AppTheme.darkTheme,
      child: AdminSidebar(
        sections: widget.sections,
        footerItems: widget.footerItems,
        location: widget.location,
        isCollapsed: isCollapsed,
        brand: widget.sidebarBrand,
        footer: widget.sidebarFooter,
        onToggle: onToggle,
        toggleIcon: toggleIcon,
        toggleTooltip: toggleTooltip,
        onSelect: (item) =>
            _handleSelect(item, closeDrawer: closeDrawerOnSelect),
      ),
    );
  }

  Widget _buildDockedSidebar(double viewportWidth) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _collapsedOverrideNotifier,
        _widthNotifier,
        _isResizingNotifier,
      ]),
      builder: (context, _) {
        final isCollapsed = _isCollapsed(viewportWidth);
        final width = isCollapsed
            ? AppLayout.sidebarRailWidth
            : _widthNotifier.value.clamp(
                AppLayout.sidebarMinWidth,
                _maxWidth(viewportWidth),
              );

        return AnimatedContainer(
          duration: _isResizingNotifier.value
              ? Duration.zero
              : AppDurations.normal,
          curve: Curves.easeInOutCubic,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: _themedSidebar(
                  isCollapsed: isCollapsed,
                  closeDrawerOnSelect: false,
                  onToggle: () => _toggleCollapsed(viewportWidth),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: AppLayout.sidebarResizeHandleWidth,
                child: _ResizeHandle(
                  isResizing: _isResizingNotifier.value,
                  onStart: () => _onResizeStart(viewportWidth),
                  onUpdate: (dx) => _onResizeUpdate(dx, viewportWidth),
                  onEnd: _onResizeEnd,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: AppLayout.drawerWidth,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: AppRadius.lgRadius.topRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _themedSidebar(
        isCollapsed: false,
        closeDrawerOnSelect: true,
        toggleIcon: Icons.close_rounded,
        toggleTooltip: 'Close menu',
        onToggle: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
    );
  }
}

// ─── Resize handle ───────────────────────────────────────────────────────────

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.isResizing,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
  });

  final bool isResizing;
  final VoidCallback onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppHoverBuilder(
      cursor: SystemMouseCursors.resizeColumn,
      builder: (context, isHovered, _) {
        final isActive = isHovered || isResizing;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => onStart(),
          onHorizontalDragUpdate: (details) => onUpdate(details.delta.dx),
          onHorizontalDragEnd: (_) => onEnd(),
          onHorizontalDragCancel: onEnd,
          child: Align(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: AppDurations.instant,
              width: isActive ? 2 : 0,
              color: colors.primary.withValues(alpha: 0.7),
            ),
          ),
        );
      },
    );
  }
}
