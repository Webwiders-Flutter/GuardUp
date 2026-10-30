import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/utils/extensions/supabase_user_extension.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';
import 'package:guardup/core/widgets/common/app_circle_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardHeaderWidget extends StatelessWidget {
  const DashboardHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.displayName ?? 'Guest';
    final profileImage = user?.displayProfileImage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Notification bell and Language
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    AppAssets.notificationIcon,
                    height: 24,
                    width: 24,
                    color: AppColors.secondary,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      height: 8,
                      width: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              8.width,
              AppText(
                context.l10n.english,
                color: AppColors.whiteColor,
                fontSize: 12,
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.whiteColor,
                size: 16,
              ),
            ],
          ),

          // Center: Logo
          Image.asset(AppAssets.appLogo, height: 35, fit: BoxFit.contain),

          // Right side: Profile
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.hello,
                    color: AppColors.whiteColor,
                    fontSize: 10,
                  ),
                  AppText(
                    name,
                    color: AppColors.whiteColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              AppCircleAvatar(
                imageUrl: profileImage,
                radius: 18,
                showBorder: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
