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

/// Custom luxury pill-style TabBar widget matching GuardUp design standards.
///
/// Features separate rounded pill segments with active gold top-to-bottom
/// gradient & subtle elevation glow, alongside sleek dark unselected segments.
class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabNames;
  final ValueChanged<int>? onTap;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? tabPadding;
  final double height;
  final double spacing;
  final double radius;

  const AppTabBar({
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
  });

  /// Factory constructor to easily create [AppTabBar] from a list of [AppTabItem]s.
  factory AppTabBar.fromItems({
    Key? key,
    required TabController controller,
    required List<AppTabItem> items,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
    TabAlignment? tabAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? tabPadding,
    double height = 44.0,
    double spacing = AppSpacing.sm,
    double radius = AppRadius.md,
  }) {
    return AppTabBar(
      key: key,
      controller: controller,
      tabNames: items.map((e) => e.tabName).toList(),
      onTap: onTap,
      isScrollable: isScrollable,
      tabAlignment: tabAlignment,
      padding: padding,
      tabPadding: tabPadding,
      height: height,
      spacing: spacing,
      radius: radius,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height + (padding?.vertical ?? 0));

  @override
  Widget build(BuildContext context) {
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
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
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
    final bool isSelected = animValue.round() == index;

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
              ? context.textTheme.bodySmall
                    ?.bold()
                    .colour(context.colors.onPrimary)
                    .increaseSize(1)
              : context.textTheme.bodySmall
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
  final ScrollPhysics? physics;
  final bool isScrollable;
  final TabAlignment? tabAlignment;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? tabPadding;
  final double height;
  final double spacing;
  final double radius;

  const AppTabView({
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
  });

  /// Constructor taking separate lists of tabNames and tabBodies.
  AppTabView.fromLists({
    Key? key,
    required TabController controller,
    required List<String> tabNames,
    required List<Widget> tabBodies,
    ScrollPhysics? physics,
    bool isScrollable = false,
    TabAlignment? tabAlignment,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? tabPadding,
    double height = 44.0,
    double spacing = AppSpacing.sm,
    double radius = AppRadius.md,
  }) : this(
         key: key,
         controller: controller,
         tabs: List.generate(
           tabNames.length,
           (index) =>
               AppTabItem(tabName: tabNames[index], tabBody: tabBodies[index]),
         ),
         physics: physics,
         isScrollable: isScrollable,
         tabAlignment: tabAlignment,
         padding: padding,
         tabPadding: tabPadding,
         height: height,
         spacing: spacing,
         radius: radius,
       );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTabBar(
          controller: controller,
          tabNames: tabs.map((e) => e.tabName).toList(),
          isScrollable: isScrollable,
          tabAlignment: tabAlignment,
          padding: padding,
          tabPadding: tabPadding,
          height: height,
          spacing: spacing,
          radius: radius,
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
