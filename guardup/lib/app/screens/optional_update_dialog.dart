import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_router.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_dialog.dart';

/// Modal dialog prompting the user about an optional (flexible) app update
/// using the standardized [AppDialog] framework and localization.
abstract final class OptionalUpdateDialog {
  /// Displays the optional update dialog with backdrop blur, standardized header,
  /// version comparison card, and action buttons.
  static Future<void> show({
    required BuildContext context,
    required String currentVersion,
    required String targetVersion,
    String? updateMessage,
    VoidCallback? onUpdateNow,
    VoidCallback? onLater,
  }) {
    final effectiveContext =
        AppRouter.rootNavigatorKey.currentContext ?? context;
    final l10n = effectiveContext.l10n;

    return AppDialog.show(
      context: effectiveContext,
      maxWidth: (AppSpacing.xxxl * 13) + AppSpacing.xxl,
      title: l10n.newUpdateAvailable,
      subtitle: l10n.updateReadyToInstall(targetVersion),
      icon: QuickContainer(
        w: AppSpacing.xxxl + AppSpacing.xs,
        h: AppSpacing.xxxl + AppSpacing.xs,
        radius: AppRadius.full,
        color: effectiveContext.colors.primary.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child: Icon(
          Icons.auto_awesome_rounded,
          size: AppSpacing.xl,
          color: effectiveContext.colors.primary,
        ),
      ),
      action: AppDialogHeaderAction.close,
      onActionTap: () {
        onLater?.call();
        Navigator.of(effectiveContext, rootNavigator: true).pop();
      },
      bottom: Builder(
        builder: (dialogCtx) {
          final dialogL10n = dialogCtx.l10n;

          return Row(
            children: [
              Expanded(
                child: AppButton(
                  text: dialogL10n.later,
                  type: ButtonType.secondaryOff,
                  onPressed: () {
                    onLater?.call();
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: AppButton(
                  text: dialogL10n.updateNow,
                  type: ButtonType.primary,
                  leading: const Icon(Icons.download_rounded),
                  onPressed: () {
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                    onUpdateNow?.call();
                  },
                ),
              ),
            ],
          );
        },
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            updateMessage != null && updateMessage.trim().isNotEmpty
                ? updateMessage
                : l10n.optionalUpdateDefaultMessage,
            style: effectiveContext.textTheme.bodyMedium?.colour(
              effectiveContext.colors.onSurfaceVariant,
            ),
          ),
          AppSpacing.lg.h,
          QuickContainer(
            p: AppSpacing.md,
            radius: AppRadius.md,
            color: effectiveContext.colors.surface,
            border: Border.all(
              color: effectiveContext.colors.borderColor.withValues(alpha: 0.6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.currentVersionLabel,
                      style: effectiveContext.textTheme.labelSmall?.colour(
                        effectiveContext.colors.onSurfaceVariant,
                      ),
                    ),
                    (AppSpacing.xs / 2).h,
                    Text(
                      'v$currentVersion',
                      style: effectiveContext.textTheme.bodyMedium
                          ?.semiBold()
                          .colour(effectiveContext.colors.onSurface),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSpacing.xl,
                  color: effectiveContext.colors.primary,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.latestVersionLabel,
                      style: effectiveContext.textTheme.labelSmall?.colour(
                        effectiveContext.colors.onSurfaceVariant,
                      ),
                    ),
                    (AppSpacing.xs / 2).h,
                    Text(
                      'v$targetVersion',
                      style: effectiveContext.textTheme.bodyMedium
                          ?.semiBold()
                          .colour(effectiveContext.colors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
