import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class LoginGateBottomSheet extends StatelessWidget {
  const LoginGateBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LoginGateBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.color081026,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.color525252,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          const Icon(
            Icons.lock_outline_rounded,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 24),
          AppText(
            context.l10n.joinTheCommunity,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AppText(
            context.l10n.createAccountToJoin,
            fontSize: 14,
            color: AppColors.color8D8D8D,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AppButton(
            text: context.l10n.signUpNow,
            buttonColor: AppColors.secondary,
            textColor: AppColors.blackColor,
            onPressed: () {
              context.pop();
              context.push(AppRouter.signup);
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.pop();
              context.push(AppRouter.login);
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.color8D8D8D,
                ),
                children: [
                  TextSpan(text: "${context.l10n.alreadyHaveAnAccount} "),
                  TextSpan(
                    text: context.l10n.logIn,
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
