import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../data/models/admin_settings.model.dart';

/// Top header banner for the Admin Settings dashboard.
///
/// Features:
/// - Screen title & descriptive enterprise subtitle
/// - Live operational status badge (System Operational vs Under Maintenance)
/// - Relative last updated sync badge
/// - Discard & Save action buttons with unsaved changes tracking
class SettingsHeader extends StatelessWidget {
  final AdminSettingsModel? settings;
  final ValueNotifier<bool> hasUnsavedChangesNotifier;
  final ValueNotifier<bool> isSavingNotifier;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onRefresh;

  const SettingsHeader({
    super.key,
    required this.settings,
    required this.hasUnsavedChangesNotifier,
    required this.isSavingNotifier,
    required this.onSave,
    required this.onDiscard,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isUnderMaintenance = settings?.isUnderMaintenance ?? false;
    final lastUpdated = settings?.updatedAt;

    return QuickContainer(
      p: AppSpacing.lg,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final titleSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: AppSpacing.xxl,
                      color: colors.primary,
                    ),
                  ),
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Settings',
                          style: context.textTheme.headlineSmall?.bold().colour(
                            colors.onSurface,
                          ),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'Configure platform parameters, release versions, maintenance announcements & support channels.',
                          style: context.textTheme.bodyMedium?.colour(
                            colors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.md.h,
              // Status badges row
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Maintenance mode indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isUnderMaintenance
                          ? colors.errorLight
                          : colors.successLight,
                      borderRadius: AppRadius.fullRadius,
                      border: Border.all(
                        color: isUnderMaintenance
                            ? colors.error.withValues(alpha: 0.4)
                            : colors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: AppSpacing.sm,
                          height: AppSpacing.sm,
                          decoration: BoxDecoration(
                            color: isUnderMaintenance
                                ? colors.error
                                : colors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        AppSpacing.xs.w,
                        Text(
                          isUnderMaintenance
                              ? 'System Under Maintenance'
                              : 'All Systems Operational',
                          style: context.textTheme.labelMedium
                              ?.semiBold()
                              .colour(
                                isUnderMaintenance
                                    ? colors.error
                                    : colors.success,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Last synced badge
                  if (lastUpdated != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.backgroundLight,
                        borderRadius: AppRadius.fullRadius,
                        border: Border.all(
                          color: colors.borderLight.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: AppSpacing.md,
                            color: colors.onSurfaceSecondary,
                          ),
                          AppSpacing.xs.w,
                          Text(
                            'Updated ${lastUpdated.timeAgo}',
                            style: context.textTheme.labelMedium?.colour(
                              colors.onSurfaceSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );

          final actionButtons = ValueListenableBuilder<bool>(
            valueListenable: hasUnsavedChangesNotifier,
            builder: (context, hasUnsaved, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: isSavingNotifier,
                builder: (context, isSaving, _) {
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Refresh button
                      AppButton.outline(
                        size: .normal,
                        type: .secondaryOff,
                        tooltip: 'Reload Settings',
                        icon: Icons.refresh_rounded,
                        onPressed: isSaving ? null : onRefresh,
                      ),

                      // Discard button
                      if (hasUnsaved)
                        AppButton(
                          fullWidth: false,
                          text: 'Discard Changes',
                          type: ButtonType.secondaryOff,
                          size: ButtonSize.normal,
                          leading: const Icon(
                            Icons.undo_rounded,
                            size: AppSpacing.lg,
                          ),
                          onPressed: isSaving ? null : onDiscard,
                        ),

                      // Save button with unsaved marker indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AppButton(
                            fullWidth: false,
                            text: hasUnsaved
                                ? 'Save Changes *'
                                : 'Save Changes',
                            type: hasUnsaved
                                ? ButtonType.primary
                                : ButtonType.secondaryPrimary,
                            size: ButtonSize.normal,
                            isLoading: isSaving,
                            leading: Icon(
                              hasUnsaved
                                  ? Icons.save_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: AppSpacing.lg,
                            ),
                            onPressed: (isSaving || !hasUnsaved)
                                ? null
                                : onSave,
                          ),
                          if (hasUnsaved)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: AppSpacing.sm + 2,
                                height: AppSpacing.sm + 2,
                                decoration: BoxDecoration(
                                  color: colors.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleSection,
                AppSpacing.lg.h,
                const Divider(height: 1),
                AppSpacing.md.h,
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleSection),
              AppSpacing.lg.w,
              actionButtons,
            ],
          );
        },
      ),
    );
  }
}
