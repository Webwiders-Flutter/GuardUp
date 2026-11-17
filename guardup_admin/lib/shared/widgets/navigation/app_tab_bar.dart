import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

/// Data class representing a tab item with name, optional icons, badge, and body widget.
class AppTabItem {
  final String tabName;
  final IconData? icon;
  final IconData? selectedIcon;
  final Widget? badge;
  final Widget? tabBody;

  const AppTabItem({
    required this.tabName,
    this.icon,
    this.selectedIcon,
    this.badge,
    this.tabBody,
  });
}

/// Visual styles supported by [AppTabBar].
enum AppTabBarStyle {
  /// Standard enterprise underline indicator.
  underline,

  /// Segmented pill styling for admin consoles, tabs, and control panels.
  pill,
}

/// Custom animated TabBar widget used across screens for consistent tab navigation styling.
///
/// Supports:
/// - Standard underline indicator style ([AppTabBarStyle.underline])
/// - Modern segmented pill style ([AppTabBarStyle.pill])
/// - Driving via [TabController] or standalone [selectedIndex]
/// - Rich tab items with icons, active state icons, and badges ([AppTabItem])
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final int? selectedIndex;
  final List<AppTabItem> items;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final AppTabBarStyle style;
  final EdgeInsetsGeometry? padding;

  const AppTabBar({
    super.key,
    this.controller,
    this.selectedIndex,
    required this.items,
    this.onTap,
    this.isScrollable = false,
    this.style = AppTabBarStyle.underline,
    this.padding,
  }) : assert(
         controller != null || selectedIndex != null,
         'Either controller or selectedIndex must be provided to AppTabBar',
       );

  /// Convenience constructor accepting a simple list of tab name strings.
  AppTabBar.fromNames({
    Key? key,
    TabController? controller,
    int? selectedIndex,
    required List<String> tabNames,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
    AppTabBarStyle style = AppTabBarStyle.underline,
    EdgeInsetsGeometry? padding,
  }) : this(
         key: key,
         controller: controller,
         selectedIndex: selectedIndex,
         items: tabNames.map((e) => AppTabItem(tabName: e)).toList(),
         onTap: onTap,
         isScrollable: isScrollable,
         style: style,
         padding: padding,
       );

  /// Factory constructor to easily create [AppTabBar] from a list of [AppTabItem]s.
  factory AppTabBar.fromItems({
    Key? key,
    required TabController controller,
    required List<AppTabItem> items,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
    AppTabBarStyle style = AppTabBarStyle.underline,
    EdgeInsetsGeometry? padding,
  }) {
    return AppTabBar(
      key: key,
      controller: controller,
      items: items,
      onTap: onTap,
      isScrollable: isScrollable,
      style: style,
      padding: padding,
    );
  }

  /// Factory constructor for modern segmented pill tabs (e.g. Admin Settings, Filters).
  factory AppTabBar.pills({
    Key? key,
    TabController? controller,
    int? selectedIndex,
    required List<AppTabItem> items,
    ValueChanged<int>? onTap,
    bool isScrollable = true,
    EdgeInsetsGeometry? padding,
  }) {
    return AppTabBar(
      key: key,
      controller: controller,
      selectedIndex: selectedIndex,
      items: items,
      onTap: onTap,
      isScrollable: isScrollable,
      style: AppTabBarStyle.pill,
      padding: padding,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    style == AppTabBarStyle.pill
        ? (AppSpacing.xxl + AppSpacing.lg)
        : (AppSpacing.xxl * 2),
  );

  @override
  Widget build(BuildContext context) {
    if (style == AppTabBarStyle.pill) {
      return _buildPillTabBar(context);
    }
    return _buildUnderlineTabBar(context);
  }

  // ── Underline Style ──────────────────────────────────────────────────────────

  Widget _buildUnderlineTabBar(BuildContext context) {
    final colors = context.colors;

    final container = QuickContainer(
      border: Border(
        bottom: BorderSide(
          color: colors.borderLight.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: controller != null
          ? AnimatedBuilder(
              animation: controller!.animation ?? controller!,
              builder: (context, child) {
                final animValue =
                    controller!.animation?.value ??
                    controller!.index.toDouble();
                return TabBar(
                  controller: controller,
                  onTap: onTap,
                  isScrollable: isScrollable,
                  padding: padding ?? EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  indicatorColor: colors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 2,
                  dividerColor: colors.transparent,
                  tabs: List.generate(
                    items.length,
                    (index) => _buildUnderlineTab(
                      context: context,
                      index: index,
                      item: items[index],
                      animValue: animValue,
                    ),
                  ),
                );
              },
            )
          : _buildStaticUnderlineTabs(context),
    );

    return container;
  }

  Widget _buildUnderlineTab({
    required BuildContext context,
    required int index,
    required AppTabItem item,
    required double animValue,
  }) {
    final colors = context.colors;
    final weight = (1.0 - (animValue - index).abs()).clamp(0.0, 1.0);
    final isSelected = weight > 0.5;
    final iconData = isSelected ? (item.selectedIcon ?? item.icon) : item.icon;

    final activeBgColor = colors.borderLight.withValues(alpha: 0.4);
    final bgColor =
        Color.lerp(colors.transparent, activeBgColor, weight) ??
        colors.transparent;

    final unselectedStyle = context.textTheme.bodySmall
        ?.medium()
        .colour(colors.onSurfaceSecondary)
        .increaseSize(1);
    final selectedStyle = context.textTheme.bodySmall?.bold().increaseSize(1);

    final textStyle = TextStyle.lerp(unselectedStyle, selectedStyle, weight);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: bgColor),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                size: AppSpacing.lg,
                color: Color.lerp(
                  colors.onSurfaceSecondary,
                  colors.primary,
                  weight,
                ),
              ),
              AppSpacing.xs.w,
            ],
            Text(item.tabName, style: textStyle),
            if (item.badge != null) ...[AppSpacing.xs.w, item.badge!],
          ],
        ),
      ),
    );
  }

  Widget _buildStaticUnderlineTabs(BuildContext context) {
    final colors = context.colors;
    final activeIndex = selectedIndex ?? 0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: isScrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Row(
        children: List.generate(items.length, (index) {
          final isSelected = index == activeIndex;
          final item = items[index];
          final iconData = isSelected
              ? (item.selectedIcon ?? item.icon)
              : item.icon;

          return InkWell(
            onTap: () => onTap?.call(index),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? colors.primary : colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconData != null) ...[
                    Icon(
                      iconData,
                      size: AppSpacing.lg,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceSecondary,
                    ),
                    AppSpacing.xs.w,
                  ],
                  Text(
                    item.tabName,
                    style:
                        (isSelected
                                ? context.textTheme.bodySmall?.bold()
                                : context.textTheme.bodySmall?.medium())
                            ?.colour(
                              isSelected
                                  ? colors.primary
                                  : colors.onSurfaceSecondary,
                            )
                            .increaseSize(1),
                  ),
                  if (item.badge != null) ...[AppSpacing.xs.w, item.badge!],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Pill Style ───────────────────────────────────────────────────────────────

  Widget _buildPillTabBar(BuildContext context) {
    final colors = context.colors;

    if (controller != null) {
      return AnimatedBuilder(
        animation: controller!.animation ?? controller!,
        builder: (context, child) {
          final activeIndex = controller!.index;
          return _buildPillContainer(context, colors, activeIndex);
        },
      );
    }

    final activeIndex = selectedIndex ?? 0;
    return _buildPillContainer(context, colors, activeIndex);
  }

  Widget _buildPillContainer(
    BuildContext context,
    dynamic colors,
    int activeIndex,
  ) {
    final tabItems = List.generate(items.length, (index) {
      final isSelected = index == activeIndex;
      final item = items[index];
      final iconData = isSelected
          ? (item.selectedIcon ?? item.icon)
          : item.icon;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
        child: InkWell(
          onTap: () {
            if (controller != null) {
              controller!.animateTo(index);
            }
            onTap?.call(index);
          },
          borderRadius: AppRadius.smRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : colors.transparent,
              borderRadius: AppRadius.smRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[
                  Icon(
                    iconData,
                    size: AppSpacing.lg,
                    color: isSelected
                        ? colors.onPrimary
                        : colors.onSurfaceSecondary,
                  ),
                  AppSpacing.sm.w,
                ],
                Text(
                  item.tabName,
                  style:
                      (isSelected
                              ? context.textTheme.labelMedium?.semiBold()
                              : context.textTheme.labelMedium)
                          ?.colour(
                            isSelected ? colors.onPrimary : colors.onSurface,
                          ),
                ),
                if (item.badge != null) ...[AppSpacing.xs.w, item.badge!],
              ],
            ),
          ),
        ),
      );
    });

    return QuickContainer(
      p: AppSpacing.xs,
      radius: AppRadius.md,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: tabItems),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tabItems.map((e) => Expanded(child: e)).toList(),
            ),
    );
  }
}

/// A combined widget that renders [AppTabBar] and [TabBarView] together.
class AppTabView extends StatelessWidget {
  final TabController controller;
  final List<AppTabItem> tabs;
  final ScrollPhysics? physics;
  final AppTabBarStyle style;

  const AppTabView({
    super.key,
    required this.controller,
    required this.tabs,
    this.physics,
    this.style = AppTabBarStyle.underline,
  });

  /// Constructor taking separate lists of tabNames and tabBodies.
  AppTabView.fromLists({
    Key? key,
    required TabController controller,
    required List<String> tabNames,
    required List<Widget> tabBodies,
    ScrollPhysics? physics,
    AppTabBarStyle style = AppTabBarStyle.underline,
  }) : this(
         key: key,
         controller: controller,
         tabs: List.generate(
           tabNames.length,
           (index) =>
               AppTabItem(tabName: tabNames[index], tabBody: tabBodies[index]),
         ),
         physics: physics,
         style: style,
       );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTabBar(controller: controller, items: tabs, style: style),
        Expanded(
          child: TabBarView(
            controller: controller,
            physics: physics,
            children: tabs
                .map((e) => e.tabBody ?? const SizedBox.shrink())
                .toList(),
          ),
        ),
      ],
    );
  }
}
