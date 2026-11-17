import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = color.withValues(alpha: isDark ? 0.14 : 0.06);
    final borderColor = color.withValues(alpha: isDark ? 0.3 : 0.18);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: AppRadius.xsRadius,
                ),
                child: Icon(icon, size: AppSpacing.md, color: color),
              ),
              AppSpacing.xs.w,
            ],
            Flexible(
              child: Text(
                label,
                style: context.textTheme.labelSmall?.medium().colour(
                  colors.onSurfaceSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        (AppSpacing.xs + 2).h,
        Text(
          value,
          style: context.textTheme.titleMedium
              ?.bold()
              .colour(color)
              .textSpacing(-0.2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          (AppSpacing.xs / 2).h,
          Text(
            subtitle!,
            style: context.textTheme.labelSmall?.regular().colour(
              colors.onSurfaceSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.smRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppRadius.smRadius,
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.smRadius,
            hoverColor: color.withValues(alpha: isDark ? 0.08 : 0.04),
            splashColor: color.withValues(alpha: isDark ? 0.16 : 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: borderColor),
      ),
      child: content,
    );
  }
}
