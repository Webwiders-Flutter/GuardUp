import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class CustomErrorView extends StatelessWidget {
  final String message;
  final double? animationHeight;

  const CustomErrorView({
    super.key,
    required this.message,
    this.animationHeight = 250,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(AppAssets.notFoundAnimation, height: animationHeight),
          const SizedBox(height: 20),
          AppText(
            message,
            color: AppColors.whiteColor,
            textAlign: TextAlign.center,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}
