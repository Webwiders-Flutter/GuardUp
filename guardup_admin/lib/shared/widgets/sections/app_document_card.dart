import 'package:flutter/material.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_file_viewer.dart';

class AppDocumentCard extends StatelessWidget {
  const AppDocumentCard({
    super.key,
    required this.title,
    required this.fileUrl,
    this.subtitle,
    this.icon = Icons.description_outlined,
    this.maxWidth = 280,
  });

  final String title;
  final String fileUrl;
  final String? subtitle;
  final IconData icon;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    void openPreview() {
      AppFileViewer.show(
        context: context,
        fileUrl: fileUrl,
        title: title,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: colors.backgroundLight,
        borderRadius: AppRadius.smRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openPreview,
          borderRadius: AppRadius.smRadius,
          hoverColor: colors.primary.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Icon(icon, color: colors.primary, size: AppSpacing.xl),
                ),
                AppSpacing.sm.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.semiBold().colour(
                          colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
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
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: colors.onSurfaceSecondary,
                    size: AppSpacing.xl - 2,
                  ),
                  tooltip: 'Preview Document',
                  onPressed: openPreview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
