import 'package:flutter/material.dart';
import 'package:guardup/core/app_types/app_text_type.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class LogoutPopup extends StatelessWidget {
  final VoidCallback onYes;

  const LogoutPopup({super.key, required this.onYes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage(
              imageUrl: AppAssets.logoutIcon,
              height: 70,
              width: 70,
              backgroundColor: Colors.transparent,
              fit: BoxFit.contain,
              appFileType: AppImageTypes.asset,
              borderRadius: 0,
            ),

            const SizedBox(height: 18),

            AppText(
              context.l10n.areYouSure,
              type: AppTextType.bodyMedium,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.blackColor,
            ),

            const SizedBox(height: 10),

            AppText(
              context.l10n.youWantToLogout,
              type: AppTextType.bodySmall,
              textAlign: TextAlign.center,
              fontSize: 13,
              color: AppColors.blackColor,
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onYes();
                },
                child: AppText(
                  context.l10n.yes,
                  type: AppTextType.bodyMedium,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                ),
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: AppText(
                context.l10n.no,
                type: AppTextType.bodyMedium,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
