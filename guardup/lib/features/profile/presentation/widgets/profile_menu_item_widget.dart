import 'package:flutter/material.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';

class ProfileMenuItemWidget extends StatelessWidget {
  final String iconPath;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;

  const ProfileMenuItemWidget({
    super.key,
    required this.iconPath,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
        margin: EdgeInsets.symmetric(vertical: 2),
        color: Color(0xff132030),
        child: Row(
          children: [
            // Icon Container
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xff081026),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: iconColor != null
                    ? ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          iconColor!,
                          BlendMode.srcIn,
                        ),
                        child: AppImage(
                          imageUrl: iconPath,
                          appFileType: AppImageTypes.asset,
                          height: 20,
                          width: 20,
                        ),
                      )
                    : AppImage(
                        imageUrl: iconPath,
                        appFileType: AppImageTypes.asset,
                        height: 20,
                        width: 20,
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Title
            Expanded(
              child: Text(
                title,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: AppColors.surfaceLight,
                  // fontSize: 15,
                ),
              ),
            ),

            // Trailing Widget or Default Arrow
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }
}
