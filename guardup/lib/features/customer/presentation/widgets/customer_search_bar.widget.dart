import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Luxury styled search input bar for the customer home & browse screens.
class CustomerSearchBarWidget extends StatelessWidget {
  final String hintText;
  final VoidCallback? onTap;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final Color? borderColor;

  final TextEditingController? controller;
  final bool readOnly;

  const CustomerSearchBarWidget({
    super.key,
    this.hintText = 'Search bodyguards near you...',
    this.onTap,
    this.onFilterTap,
    this.onChanged,
    this.borderColor,
    this.controller,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: QuickContainer(
        h: 52,
        px: AppSpacing.md,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: context.colors.surfaceContainer.withValues(alpha: 0.9),
        border: Border.all(
          color:
              borderColor ??
              context.colors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: context.colors.onSurfaceVariant,
              size: 22,
            ),
            AppSpacing.sm.w,
            Expanded(
              child: readOnly
                  ? Text(
                      controller?.text.isNotEmpty == true
                          ? controller!.text
                          : hintText,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: controller?.text.isNotEmpty == true
                            ? context.colors.onSurface
                            : context.colors.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : TextField(
                      controller: controller,
                      readOnly: readOnly,
                      onChanged: onChanged,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurface,
                      ),
                      cursorColor: context.colors.primary,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: hintText,
                        hintStyle: context.textTheme.bodyMedium?.colour(
                          context.colors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
            if (onFilterTap != null) ...[
              AppSpacing.xs.w,
              GestureDetector(
                onTap: onFilterTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: context.colors.primary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
