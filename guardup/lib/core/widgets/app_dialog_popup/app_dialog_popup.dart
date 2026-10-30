import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';

class AppConfirmationPopup {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  confirmColor == Colors.red
                      ? Icons.delete_outline
                      : Icons.logout_rounded,
                  size: 60,
                  color: confirmColor,
                ),

                const SizedBox(height: 16),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(color: AppColors.primary, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          context.l10n.cancel,
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: AppButton(
                        height: 50,
                        buttonColor: confirmColor,
                        text: confirmText,
                        onPressed: () {
                          Navigator.pop(context);
                          onConfirm();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showLogoutPopup(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return show(
      context: context,
      title: context.l10n.logout,
      message: context.l10n.logoutConfirmation,
      confirmText: context.l10n.logout,
      confirmColor: AppColors.primary,
      onConfirm: onConfirm,
    );
  }

  static Future<void> showDeleteAccountPopup(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return show(
      context: context,
      title: context.l10n.deleteAccount,
      message: context.l10n.deleteAccountConfirmation,
      confirmText: context.l10n.delete,
      confirmColor: Colors.red,
      onConfirm: onConfirm,
    );
  }

  static Future<void> showSuccessPopup({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onOk,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: AppColors.mainBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: AppColors.success,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AppButton(
                  height: 50,
                  buttonColor: AppColors.primary,
                  text: context.l10n.ok,
                  onPressed: () {
                    Navigator.pop(context);
                    onOk();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
