import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';

import 'extensions/context_extensions.dart';

enum ExitDialogResult { exit, discard, cancel }

class UIFeedback {
  static Future<ExitDialogResult> showDraftExitDialog(
    BuildContext context,
  ) async {
    final result = await showDialog<ExitDialogResult>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.color132030,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.bookmark_added_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.draftSavedSuccessfully,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          context.isArabic
              ? 'تم حفظ تقدم طلبك كمسودة. يمكنك استكمال طلبك في أي وقت من طلباتي.'
              : 'Your application progress has been saved as a draft. You can continue anytime from My Requests.',
          style: const TextStyle(color: AppColors.color8D8D8D, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, ExitDialogResult.cancel),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppColors.color8D8D8D),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, ExitDialogResult.discard),
            child: Text(
              context.isArabic ? 'إلغاء المسودة' : 'Discard Draft',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.blackColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx, ExitDialogResult.exit),
            child: Text(
              context.l10n.exit,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? ExitDialogResult.cancel;
  }

  // --- SNACKBAR ---
  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? context.colorScheme.error
            : context.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --- CUSTOM DIALOG ---
  static void showCustomDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: context.textTheme.titleMedium),
        content: Text(message, style: context.textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              if (onConfirm != null) onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // --- LOADER DIALOG ---
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CustomLoader(),
    );
  }

  // --- TOAST (Internal implementation since Flutter doesn't have a native one) ---
  // Using a OverlayEntry for a custom Toast look
  static void showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        width: context.screenWidth,
        child: UnconstrainedBox(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }
}
