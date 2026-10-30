import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_button/app_button.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/custom_ritch_text.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              36.height,
              Expanded(
                child: Image.asset(
                  AppAssets.onboardingImage01,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              Image.asset(
                AppAssets.onboardingImage02,
                height: 175,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ],
          ),

          Positioned(
            left: 30,
            right: 50,
            top: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomRichText(
                  firstText: context.l10n.yourJourney,
                  firstFontSize: 35,
                  firstColor: AppColors.whiteColor,
                  secondText: context.l10n.startsHereOnboarding,
                  secondFontSize: 35,
                  secondColor: AppColors.secondary,
                ),
                5.height,
                AppText(
                  context.l10n.exploreEurope,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),

          Positioned(
            left: 30,
            right: 40,
            bottom: 100,
            child: Column(
              children: [
                AppButton(
                  height: 50,
                  width: double.infinity,
                  borderRadius: 10,
                  buttonColor: AppColors.secondary,
                  text: context.l10n.signup,
                  textColor: AppColors.blackColor,
                  onPressed: () {
                    context.pushReplacement(AppRouter.signup);
                  },
                ),
                20.height,
                AppButton(
                  height: 50,
                  borderRadius: 10,
                  borderWidth: 1,
                  width: double.infinity,
                  buttonColor: AppColors.blackColor,
                  borderColor: AppColors.secondary,
                  text: context.l10n.logIn,
                  textColor: AppColors.secondary,
                  onPressed: () {
                    context.pushReplacement(AppRouter.login);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
