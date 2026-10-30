import 'package:flutter/material.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 120),
        Center(
          child: AppImage(
            imageUrl: AppAssets.appLogo,
            height: 120,
            width: 165,
            backgroundColor: Colors.transparent,
            fit: BoxFit.contain,
            appFileType: AppImageTypes.asset,
            borderRadius: 0,
          ),
        ),
        const SizedBox(height: 30),
        AppText(
          title,
          textAlign: TextAlign.center,
          type: AppTextType.headlineLarge,
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: AppColors.whiteColor,
        ),
        const SizedBox(height: 8),
        AppText(
          subtitle,
          textAlign: TextAlign.center,
          color: Colors.white60,
          fontSize: 13,
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
