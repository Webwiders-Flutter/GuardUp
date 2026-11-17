import '/gen/assets.gen.dart';

import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

class InfoBanner extends StatelessWidget {
  final IconData? iconData;
  final SvgGenImage? svgData;
  final Widget? iconOverride;
  final Color? color;
  final String? heading;
  final Widget? headingOverride;

  final String description;
  final Widget? descriptionOverride;

  const InfoBanner({
    super.key,
    this.iconData,
    this.svgData,
    this.heading,
    this.color,
    this.iconOverride,
    this.headingOverride,
    this.description = '',
    this.descriptionOverride,
  }) : assert(
         !((iconData != null || svgData != null) && iconOverride != null),
         'icon/svg and iconOverride should not be provided at the same time.',
       ),
       assert(
         !(description != '' && descriptionOverride != null),
         'description and descriptionOverride should not be provided at the same time.',
       ),
       assert(
         !(heading != null && headingOverride != null),
         'heading and headingOverride should not be provided at the same time.',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.colors.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        border: Border.all(
          color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                (heading != null || headingOverride != null ? 2 : 1).tPadding,
            child:
                iconOverride ??
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(
                      alpha: isDark ? 0.20 : 0.12,
                    ),
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: svgData != null
                      ? svgData?.svg(
                          width: AppSpacing.lg,
                          height: AppSpacing.lg,
                        )
                      : Icon(
                          iconData ?? Icons.info_outline_rounded,
                          size: AppSpacing.lg,
                          color: effectiveColor,
                        ),
                ),
          ),
          AppSpacing.sm.w,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (heading != null || headingOverride != null) ...[
                  headingOverride ??
                      Text(
                        heading!,
                        style: context.textTheme.bodyMedium?.semiBold().colour(
                          effectiveColor,
                        ),
                      ),
                  (AppSpacing.xs / 2).h,
                ],
                descriptionOverride ??
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.lineHeight(1.4),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
