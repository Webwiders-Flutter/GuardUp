import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Data class representing a tab item with a name and an optional body widget.
class AppTabItem {
  final String tabName;
  final Widget? tabBody;

  const AppTabItem({required this.tabName, this.tabBody});
}

/// Visual presentation style for [AppTabBar].
enum AppTabBarType {
  /// Separate rounded pill segments with background highlights.
  pill,

  /// Clean underline tabs with bottom indicator line and subtle divider.
  underline,
}

/// Custom TabBar widget supporting both luxury pill and underline styles.
///
/// - **pill**: Separate rounded segments with active gold gradient & elevation.
/// - **underline**: Clean underline tabs with active gold line and full-width bottom divider.
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabNames;
  final AppTabBarType type;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? tabPadding;
  final double height;
  final double spacing;
  final double radius;
  final Color? indicatorColor;
  final Color? dividerColor;
  final TabBarIndicatorSize? indicatorSize;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabNames,
    this.type = AppTabBarType.pill,
    this.onTap,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 40.0,
    this.spacing = AppSpacing.sm,
    this.radius = AppRadius.md,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize,
  });

  /// Factory constructor for rounded pill-style tab bar.
  const AppTabBar.pill({
    super.key,
    required this.controller,
    required this.tabNames,
    this.onTap,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 40.0,
    this.spacing = AppSpacing.sm,
    this.radius = AppRadius.md,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize,
  }) : type = AppTabBarType.pill;

  /// Factory constructor for sleek underline-style tab bar.
  const AppTabBar.underline({
    super.key,
    required this.controller,
    required this.tabNames,
    this.onTap,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 44.0,
    this.spacing = AppSpacing.md,
    this.radius = AppRadius.xs,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize = TabBarIndicatorSize.label,
  }) : type = AppTabBarType.underline;

  /// Factory constructor to easily create [AppTabBar] from a list of [AppTabItem]s.
  factory AppTabBar.fromItems({
    Key? key,
    required TabController controller,
    required List<AppTabItem> items,
    AppTabBarType type = AppTabBarType.pill,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
    TabAlignment? tabAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? tabPadding,
    double height = 44.0,
    double spacing = AppSpacing.sm,
    double radius = AppRadius.md,
    Color? indicatorColor,
    Color? dividerColor,
    TabBarIndicatorSize? indicatorSize,
  }) {
    return AppTabBar(
      key: key,
      controller: controller,
      tabNames: items.map((e) => e.tabName).toList(),
      type: type,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: tabAlignment,
      padding: padding,
      tabPadding: tabPadding,
      height: height,
      spacing: spacing,
      radius: radius,
      indicatorColor: indicatorColor,
      dividerColor: dividerColor,
      indicatorSize: indicatorSize,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + (padding?.vertical ?? 0));

  @override
  Widget build(BuildContext context) {
    if (type == AppTabBarType.underline) {
      return _buildUnderlineTabBar(context);
    }
    return _buildPillTabBar(context);
  }

  // ---------------------------------------------------------------------------
  // Underline Tab Bar Style
  // ---------------------------------------------------------------------------
  Widget _buildUnderlineTabBar(BuildContext context) {
    final effectiveIndicatorColor = indicatorColor ?? context.colors.primary;
    final effectiveDividerColor = dividerColor ?? context.colors.outlineVariant;

    return TabBar(
      controller: controller,
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment:
          tabAlignment ??
          (isScrollable ? TabAlignment.start : TabAlignment.fill),
      padding: padding ?? EdgeInsets.zero,
      labelPadding: EdgeInsets.symmetric(horizontal: spacing),
      indicatorSize: indicatorSize ?? TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: effectiveIndicatorColor, width: 2.5),
        borderRadius: BorderRadius.circular(radius),
      ),
      dividerColor: effectiveDividerColor,
      dividerHeight: 1.0,
      overlayColor: WidgetStateProperty.all(context.colors.transparent),
      splashFactory: NoSplash.splashFactory,
      labelColor: effectiveIndicatorColor,
      labelStyle: (context.textTheme.labelMedium ?? const TextStyle())
          .medium()
          .colour(effectiveIndicatorColor)
          .increaseSize(1),
      unselectedLabelColor: context.colors.onSurfaceVariant,
      unselectedLabelStyle: (context.textTheme.labelMedium ?? const TextStyle())
          .medium()
          .colour(context.colors.onSurfaceVariant)
          .increaseSize(1),
      tabs: tabNames.map((name) => Tab(height: height, text: name)).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Pill Tab Bar Style
  // ---------------------------------------------------------------------------
  Widget _buildPillTabBar(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animation ?? controller,
      builder: (context, child) {
        final currentAnimValue =
            controller.animation?.value ?? controller.index.toDouble();

        return TabBar(
          controller: controller,
          onTap: onTap,
          isScrollable: isScrollable,
          tabAlignment:
              tabAlignment ??
              (isScrollable ? TabAlignment.start : TabAlignment.fill),
          padding: padding ?? EdgeInsets.zero,
          labelPadding: EdgeInsets.symmetric(horizontal: spacing / 1.5),
          indicator: const BoxDecoration(),
          indicatorColor: context.colors.transparent,
          dividerColor: context.colors.transparent,
          overlayColor: WidgetStateProperty.all(context.colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: List.generate(
            tabNames.length,
            (index) => _buildPillTab(
              context: context,
              index: index,
              label: tabNames[index],
              animValue: currentAnimValue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTab({
    required BuildContext context,
    required int index,
    required String label,
    required double animValue,
  }) {
    final bool isSelected = controller.indexIsChanging
        ? controller.index == index
        : animValue.round() == index;

    return Tab(
      height: height,
      child: QuickContainer(
        h: height,
        w: isScrollable ? null : double.infinity,
        px: isScrollable
            ? AppSpacing.lg
            : (tabPadding?.horizontal ?? AppSpacing.xs),
        radius: radius,
        gradient: isSelected ? context.colors.primaryGradient : null,
        color: isSelected
            ? null
            : context.colors.surfaceContainer.withValues(alpha: 0.72),
        border: isSelected
            ? null
            : Border.all(color: context.colors.outlineVariant, width: 1),
        shadows: isSelected
            ? [
                BoxShadow(
                  color: context.colors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        alignment: Alignment.center,
        child: Text(
          label,
          style: isSelected
              ? context.textTheme.labelMedium?.bold().colour(
                  context.colors.onPrimary,
                )
              : context.textTheme.labelMedium
                    ?.weight(FontWeight.w500)
                    .colour(context.colors.outline)
                    .increaseSize(1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// A combined widget that renders [AppTabBar] and [TabBarView] together.
class AppTabView extends StatelessWidget {
  final TabController controller;
  final List<AppTabItem> tabs;
  final AppTabBarType type;
  final ScrollPhysics? physics;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? tabPadding;
  final double height;
  final double spacing;
  final double radius;
  final Color? indicatorColor;
  final Color? dividerColor;
  final TabBarIndicatorSize? indicatorSize;

  const AppTabView({
    super.key,
    required this.controller,
    required this.tabs,
    this.type = AppTabBarType.pill,
    this.physics,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 44.0,
    this.spacing = AppSpacing.sm,
    this.radius = AppRadius.md,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize,
  });

  const AppTabView.pill({
    super.key,
    required this.controller,
    required this.tabs,
    this.physics,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 44.0,
    this.spacing = AppSpacing.sm,
    this.radius = AppRadius.md,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize,
  }) : type = AppTabBarType.pill;

  const AppTabView.underline({
    super.key,
    required this.controller,
    required this.tabs,
    this.physics,
    this.isScrollable = false,
    this.tabAlignment,
    this.padding,
    this.tabPadding,
    this.height = 44.0,
    this.spacing = AppSpacing.md,
    this.radius = AppRadius.xs,
    this.indicatorColor,
    this.dividerColor,
    this.indicatorSize = TabBarIndicatorSize.label,
  }) : type = AppTabBarType.underline;

  /// Constructor taking separate lists of tabNames and tabBodies.
  AppTabView.fromLists({
    Key? key,
    required TabController controller,
    required List<String> tabNames,
    required List<Widget> tabBodies,
    AppTabBarType type = AppTabBarType.pill,
    ScrollPhysics? physics,
    bool isScrollable = false,
    TabAlignment? tabAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? tabPadding,
    double height = 44.0,
    double spacing = AppSpacing.sm,
    double radius = AppRadius.md,
    Color? indicatorColor,
    Color? dividerColor,
    TabBarIndicatorSize? indicatorSize,
  }) : this(
         key: key,
         controller: controller,
         tabs: List.generate(
           tabNames.length,
           (index) =>
               AppTabItem(tabName: tabNames[index], tabBody: tabBodies[index]),
         ),
         type: type,
         physics: physics,
         isScrollable: isScrollable,
         tabAlignment: tabAlignment,
         padding: padding,
         tabPadding: tabPadding,
         height: height,
         spacing: spacing,
         radius: radius,
         indicatorColor: indicatorColor,
         dividerColor: dividerColor,
         indicatorSize: indicatorSize,
       );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTabBar(
          controller: controller,
          tabNames: tabs.map((e) => e.tabName).toList(),
          type: type,
          isScrollable: isScrollable,
          tabAlignment: tabAlignment,
          padding: padding,
          tabPadding: tabPadding,
          height: height,
          spacing: spacing,
          radius: radius,
          indicatorColor: indicatorColor,
          dividerColor: dividerColor,
          indicatorSize: indicatorSize,
        ),
        AppSpacing.md.h,
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
