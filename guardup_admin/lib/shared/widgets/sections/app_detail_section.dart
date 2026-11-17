import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import 'app_detail_tile.dart';

class AppDetailSection extends StatelessWidget {
  const AppDetailSection({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    this.items,
    this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.boxShadow,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final List<DetailItem>? items;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final visibleItems = (items ?? [])
        .where((r) => r.value?.trim().isNotEmpty ?? false)
        .toList();

    if (visibleItems.isEmpty && child == null) {
      return const SizedBox.shrink();
    }

    final effectiveIconColor = iconColor ?? colors.secondary;
    final effectiveBgColor = backgroundColor ?? colors.surface;
    final effectiveBorderColor =
        borderColor ?? colors.borderLight.withValues(alpha: 0.65);
    final effectiveBorderWidth = borderWidth ?? 1.0;
    final effectiveRadius = borderRadius ?? AppRadius.lgRadius;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: effectiveBorderWidth,
        ),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.02),
                blurRadius: AppSpacing.md,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.smRadius,
                  color: effectiveIconColor.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.lg,
                  color: effectiveIconColor,
                ),
              ),
              AppSpacing.sm.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.semiBold().size(15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      (AppSpacing.xs / 2).h,
                      Text(
                        subtitle!,
                        style: context.textTheme.bodySmall?.colour(
                          colors.onSurfaceSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          AppSpacing.md.h,
          if (visibleItems.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleItems.length,
              separatorBuilder: (_, _) => Divider(
                color: colors.borderLight.withValues(alpha: 0.25),
                height: 1,
              ),
              itemBuilder: (context, index) {
                return AppDetailTile.fromItem(visibleItems[index]);
              },
            ),
          ],
          if (child != null) ...[
            if (visibleItems.isNotEmpty) AppSpacing.sm.h,
            child!,
          ],
        ],
      ),
    );
  }
}
