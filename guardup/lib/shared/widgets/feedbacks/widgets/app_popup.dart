import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/core/extensions/number.extension.dart';

import '../../../../core/extensions/localization.extension.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import 'app_dialog.dart';

enum PopupAction { confirm, cancel, dismiss }

class PopupResult<T> {
  final PopupAction action;
  final T? data;

  const PopupResult({required this.action, this.data});
}

enum PopupVariant { info, success, warning, danger, custom }

class AppPopup {
  /// Helper method to pop dialog safely using GoRouter.
  static void _popResult(BuildContext context, PopupResult result) {
    if (context.canPop()) {
      context.pop(result);
    }
  }

  /// Displays a modern, executive enterprise confirmation/alert modal.
  static Future<PopupResult?> show({
    required BuildContext context,
    required String title,
    String? message,
    IconData? icon,
    Widget? customIcon,
    Widget? extraContent,
    PopupVariant variant = PopupVariant.info,
    Color? accentColor,
    List<AppButton>? buttons,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    bool blurBackground = true,
  }) {
    final colors = context.colors;

    return AppDialogs.showRaw<PopupResult>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: colors.black.withValues(alpha: 0.40),
      blurBackground: blurBackground,
      child: Builder(
        builder: (dialogContext) => _AppPopupWidget(
          title: title,
          message: message,
          icon: icon,
          customIcon: customIcon,
          extraContent: extraContent,
          variant: variant,
          accentColor: accentColor,
          buttons:
              buttons ??
              [
                AppButton(
                  text: context.l10n.cancel,
                  type: ButtonType.secondaryOff,
                  size: ButtonSize.normal,
                  onPressed: () => _popResult(
                    dialogContext,
                    const PopupResult(action: PopupAction.cancel),
                  ),
                ),
                AppButton(
                  text: context.l10n.confirm,
                  type: _getConfirmButtonType(variant),
                  size: ButtonSize.normal,
                  onPressed: () => _popResult(
                    dialogContext,
                    const PopupResult(action: PopupAction.confirm),
                  ),
                ),
              ],
          showCloseButton: showCloseButton,
          onClose: () => _popResult(
            dialogContext,
            const PopupResult(action: PopupAction.dismiss),
          ),
        ),
      ),
    );
  }

  static ButtonType _getConfirmButtonType(PopupVariant variant) {
    switch (variant) {
      case PopupVariant.danger:
        return ButtonType.danger;
      case PopupVariant.warning:
        return ButtonType.warning;
      case PopupVariant.success:
        return ButtonType.success;
      case PopupVariant.info:
      case PopupVariant.custom:
        return ButtonType.primary;
    }
  }

  // ── Predefined: Exit Confirmation ───────────────────────────────────────────
  static Future<PopupResult?> showExitConfirmation(BuildContext context) {
    return show(
      context: context,
      title: context.l10n.exitApp,
      message: context.l10n.areYouSureYouWantToLeaveAnyUnsavedChangesWillBeLost,
      icon: Icons.logout_rounded,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: context.l10n.exit,
          type: ButtonType.danger,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Cancel Trip Confirmation ─────────────────────────────────
  static Future<PopupResult?> showCancelTripConfirmation(
    BuildContext context, {
    String? tripNumber,
  }) {
    final title = tripNumber != null && tripNumber.isNotEmpty
        ? 'Cancel Trip #$tripNumber'
        : 'Cancel Trip';
    return show(
      context: context,
      title: title,
      message: 'Are you sure you want to cancel this trip? Fulfillment quantities will be updated and this action cannot be undone.',
      icon: Icons.cancel_outlined,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: 'Keep Trip',
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: 'Cancel Trip',
          type: ButtonType.danger,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Delete Confirmation ─────────────────────────────────────────
  static Future<PopupResult?> showDeleteConfirmation(
    BuildContext context, {
    String? deleteItemName,
  }) {
    return show(
      context: context,
      title: context.l10n.deleteItem(deleteItemName ?? context.l10n.thisItem),
      message: context.l10n.thisActionCannotBeUndoneAreYouAbsolutelySure,
      icon: Icons.delete_outline_rounded,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: context.l10n.keep,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: context.l10n.delete,
          type: ButtonType.danger,
          size: ButtonSize.normal,
          leading: const Icon(
            Icons.delete_outline_rounded,
            size: AppSpacing.lg,
          ),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Reject Confirmation ──────────────────────────────────────────
  static Future<PopupResult?> showRejectConfirmation(
    BuildContext context, {
    String? itemName,
    bool alsoDelete = false,
  }) {
    final title = itemName != null && itemName.isNotEmpty
        ? 'Reject $itemName'
        : 'Reject Registration';
    final message = alsoDelete
        ? 'Are you sure you want to reject${itemName != null ? ' "$itemName"' : ''}? This user will be permanently removed from the system.'
        : 'Are you sure you want to reject${itemName != null ? ' "$itemName"' : ''}?';
    final confirmLabel = alsoDelete ? 'Reject & Delete' : 'Reject';

    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.cancel_outlined,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: confirmLabel,
          type: ButtonType.danger,
          size: ButtonSize.normal,
          leading: Icon(
            alsoDelete ? Icons.delete_outline_rounded : Icons.cancel_outlined,
            size: AppSpacing.lg,
          ),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  static Future<PopupResult?> showReject(
    BuildContext context, {
    String? itemName,
    bool alsoDelete = false,
  }) => showRejectConfirmation(
    context,
    itemName: itemName,
    alsoDelete: alsoDelete,
  );

  // ── Predefined: Block Confirmation ───────────────────────────────────────────
  static Future<PopupResult?> showBlockConfirmation(
    BuildContext context, {
    String? itemName,
  }) {
    final title = itemName != null && itemName.isNotEmpty
        ? 'Block $itemName'
        : 'Block User';
    final message =
        'Are you sure you want to block${itemName != null ? ' "$itemName"' : ''}? They will no longer be able to log in or use the platform.';

    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.block_outlined,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: 'Block',
          type: ButtonType.danger,
          size: ButtonSize.normal,
          leading: const Icon(Icons.block_outlined, size: AppSpacing.lg),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  static Future<PopupResult?> showBlock(
    BuildContext context, {
    String? itemName,
  }) => showBlockConfirmation(context, itemName: itemName);

  // ── Predefined: Unblock Confirmation ─────────────────────────────────────────
  static Future<PopupResult?> showUnblockConfirmation(
    BuildContext context, {
    String? itemName,
  }) {
    final title = itemName != null && itemName.isNotEmpty
        ? 'Unblock $itemName'
        : 'Unblock User';
    final message =
        'Are you sure you want to unblock${itemName != null ? ' "$itemName"' : ''}? They will regain full access to the platform.';

    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.lock_open_rounded,
      variant: PopupVariant.info,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: 'Unblock',
          type: ButtonType.primary,
          size: ButtonSize.normal,
          leading: const Icon(Icons.lock_open_rounded, size: AppSpacing.lg),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  static Future<PopupResult?> showUnblock(
    BuildContext context, {
    String? itemName,
  }) => showUnblockConfirmation(context, itemName: itemName);

  // ── Predefined: Success ──────────────────────────────────────────────────────
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    String? message,
    String? buttonLabel,
  }) async {
    await show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      variant: PopupVariant.success,
      showCloseButton: false,
      buttons: [
        AppButton(
          text: buttonLabel ?? context.l10n.great,
          type: ButtonType.success,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Warning ──────────────────────────────────────────────────────
  static Future<PopupResult?> showWarning(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      variant: PopupVariant.warning,
      buttons: [
        AppButton(
          text: cancelLabel ?? context.l10n.goBack,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: confirmLabel ?? context.l10n.confirm,
          type: ButtonType.warning,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Info ─────────────────────────────────────────────────────────
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    String? message,
    String? buttonLabel,
  }) async {
    await show(
      context: context,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      variant: PopupVariant.info,
      showCloseButton: true,
      buttons: [
        AppButton(
          text: buttonLabel ?? context.l10n.confirm,
          type: ButtonType.primary,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Logout ───────────────────────────────────────────────────────
  static Future<PopupResult?> showLogoutConfirmation(BuildContext context) {
    return show(
      context: context,
      title: context.l10n.logOut,
      message: context.l10n.youWillBeSignedOutOfYourAccount,
      icon: Icons.logout_rounded,
      variant: PopupVariant.danger,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: context.l10n.logOut,
          type: ButtonType.danger,
          size: ButtonSize.normal,
          leading: const Icon(Icons.logout_rounded, size: AppSpacing.lg),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Delete Account ────────────────────────────────────────────────
  static Future<PopupResult?> showDeleteAccountConfirmation(
    BuildContext context,
  ) {
    return show(
      context: context,
      title: context.l10n.deleteAccountConfirmTitle,
      message: context.l10n.deleteAccountConfirmMessage,
      icon: Icons.delete_forever_rounded,
      variant: PopupVariant.danger,
      barrierDismissible: false,
      buttons: [
        AppButton(
          text: context.l10n.cancel,
          type: ButtonType.secondaryOff,
          size: ButtonSize.normal,
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.cancel),
          ),
        ),
        AppButton(
          text: context.l10n.deleteAccountButton,
          type: ButtonType.danger,
          size: ButtonSize.normal,
          leading: const Icon(
            Icons.delete_forever_rounded,
            size: AppSpacing.lg,
          ),
          onPressed: () => _popResult(
            context,
            const PopupResult(action: PopupAction.confirm),
          ),
        ),
      ],
    );
  }

  // ── Predefined: Custom Content ────────────────────────────────────────────────
  static Future<PopupResult?> showCustom({
    required BuildContext context,
    required String title,
    required Widget content,
    String? message,
    IconData? icon,
    List<AppButton>? buttons,
    bool showCloseButton = true,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      icon: icon,
      extraContent: content,
      variant: PopupVariant.custom,
      buttons: buttons,
      showCloseButton: showCloseButton,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL POPUP WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _AppPopupWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? customIcon;
  final Widget? extraContent;
  final PopupVariant variant;
  final Color? accentColor;
  final List<AppButton> buttons;
  final bool showCloseButton;
  final VoidCallback onClose;

  const _AppPopupWidget({
    required this.title,
    this.message,
    this.icon,
    this.customIcon,
    this.extraContent,
    required this.variant,
    this.accentColor,
    required this.buttons,
    required this.showCloseButton,
    required this.onClose,
  });

  Color _resolveAccentColor(BuildContext context) {
    if (accentColor != null) return accentColor!;
    final colors = context.colors;
    switch (variant) {
      case PopupVariant.success:
        return colors.success;
      case PopupVariant.warning:
        return colors.warning;
      case PopupVariant.danger:
        return colors.error;
      case PopupVariant.info:
        return colors.info;
      case PopupVariant.custom:
        return colors.primary;
    }
  }

  IconData _resolveDefaultIcon() {
    switch (variant) {
      case PopupVariant.success:
        return Icons.check_circle_outline_rounded;
      case PopupVariant.warning:
        return Icons.warning_amber_rounded;
      case PopupVariant.danger:
        return Icons.error_outline_rounded;
      case PopupVariant.info:
        return Icons.info_outline_rounded;
      case PopupVariant.custom:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = _resolveAccentColor(context);
    final size = MediaQuery.of(context).size;
    final hasIcon = icon != null || customIcon != null;

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: size.width * 0.90,
          constraints: const BoxConstraints(maxWidth: 430),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.xl.toBorderRadius,
            border: Border.all(
              color: colors.borderLight.withValues(alpha: 0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.xl.toBorderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top subtle accent hairline
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.1),
                        accent,
                        accent.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row with Icon and Close Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (hasIcon)
                            Center(
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.10),
                                  borderRadius: AppRadius.lg.toBorderRadius,
                                  border: Border.all(
                                    color: accent.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child:
                                      customIcon ??
                                      Icon(
                                        icon ?? _resolveDefaultIcon(),
                                        color: accent,
                                        size: AppSizes.iconXl,
                                      ),
                                ),
                              ),
                            ),
                          if (showCloseButton)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: InkWell(
                                  onTap: onClose,
                                  borderRadius: AppRadius.full.toBorderRadius,
                                  child: Container(
                                    padding: AppSpacing.ssm.allPadding,
                                    decoration: BoxDecoration(
                                      color: colors.onSurface.withValues(
                                        alpha: 0.05,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: AppSizes.iconMd,
                                      color: colors.onSurfaceSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (hasIcon) AppSpacing.lg.h,

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleMedium
                            ?.bold()
                            .increaseSize(1)
                            .colour(colors.onSurface)
                            .textSpacing(-0.2),
                      ),

                      // Optional message
                      if (message != null && message!.trim().isNotEmpty) ...[
                        AppSpacing.ssm.h,
                        Text(
                          message!,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium
                              ?.medium()
                              .colour(colors.onSurfaceSecondary)
                              .lineHeight(1.45),
                        ),
                      ],

                      // Optional extra content
                      if (extraContent != null) ...[
                        AppSpacing.lg.h,
                        extraContent!,
                      ],

                      AppSpacing.xxl.h,

                      // Actions row
                      _buildButtons(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    if (buttons.isEmpty) return const SizedBox.shrink();

    if (buttons.length == 1) {
      return SizedBox(width: double.infinity, child: buttons.first);
    }

    if (buttons.length == 2) {
      return Row(
        children: [
          Expanded(child: buttons.first),
          AppSpacing.md.w,
          Expanded(child: buttons.last),
        ],
      );
    }

    return Column(
      children: buttons
          .map(
            (btn) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(width: double.infinity, child: btn),
            ),
          )
          .toList(),
    );
  }
}
