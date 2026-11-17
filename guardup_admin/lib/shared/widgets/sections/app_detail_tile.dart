import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';

typedef DetailItem = ({String label, String? value, IconData icon});

class AppDetailTile extends StatelessWidget {
  const AppDetailTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.isCopyable = false,
    this.expanded = true,
    this.onTap,
  });

  factory AppDetailTile.fromItem(
    DetailItem item, {
    Key? key,
    Widget? trailing,
    bool isCopyable = false,
    bool expanded = true,
    VoidCallback? onTap,
  }) {
    return AppDetailTile(
      key: key,
      label: item.label,
      value: item.value ?? '',
      icon: item.icon,
      trailing: trailing,
      isCopyable: isCopyable,
      expanded: expanded,
      onTap: onTap,
    );
  }

  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final bool isCopyable;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: context.textTheme.bodySmall?.colour(colors.onSurfaceSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        (AppSpacing.xs / 2).h,
        Text(
          value,
          style: context.textTheme.bodyMedium?.semiBold().colour(
            colors.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    Widget? effectiveTrailing = trailing;
    if (effectiveTrailing == null && isCopyable && value.trim().isNotEmpty) {
      effectiveTrailing = IconButton(
        icon: Icon(
          Icons.copy_rounded,
          size: AppSpacing.md + 2,
          color: colors.onSurfaceSecondary.withValues(alpha: 0.6),
        ),
        tooltip: 'Copy $label',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: AppSpacing.md,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          AppSnackbar.show(
            message: 'Copied $label to clipboard',
            type: SnackbarType.success,
            duration: const Duration(seconds: 2),
          );
        },
      );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              borderRadius: AppRadius.smRadius,
              color: colors.secondary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: AppSpacing.lg, color: colors.secondary),
          ),
          AppSpacing.sm.w,
          if (expanded) Expanded(child: textColumn) else textColumn,
          ?effectiveTrailing,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smRadius,
        child: content,
      );
    }

    return content;
  }
}
