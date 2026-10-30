import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class SignupSuccessDialog extends StatelessWidget {
  const SignupSuccessDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.mainBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.greyColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.success,
              style: const TextStyle(
                color: AppColors.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.accountCreatedSuccess,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.headingTextFieldColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pushReplacement(AppRouter.login);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.l10n.ok,
                  style: const TextStyle(
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
