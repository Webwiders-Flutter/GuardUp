import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/widgets/common/app_circle_avatar.dart';
import 'package:guardup/core/widgets/common/custom_image_viewer.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String email;
  final String memberSince;
  final String? imageUrl;

  const ProfileHeaderWidget({
    super.key,
    required this.name,
    this.email = '',
    required this.memberSince,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile Image with Edit Overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                if (imageUrl != null && imageUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomImageViewer(
                        imageUrl: imageUrl!,
                        heroTag: 'profile_image_$imageUrl',
                      ),
                    ),
                  );
                }
              },
              child: AppCircleAvatar(imageUrl: imageUrl, radius: 45),
            ),
            // Positioned(
            //   bottom: 0,
            //   right: 0,
            //   child: Container(
            //     height: 28,
            //     width: 28,
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF332036), // A dark purplish color from the mockup
            //       shape: BoxShape.circle,
            //       border: Border.all(color: AppColors.surfaceLight, width: 1.5),
            //     ),
            //     child: Center(
            //       child: AppAssets.editPenIcon.endsWith('.svg')
            //           ? SvgPicture.asset(
            //               AppAssets.editPenIcon,
            //               height: 14,
            //               width: 14,
            //               colorFilter: const ColorFilter.mode(
            //                 AppColors.surfaceLight,
            //                 BlendMode.srcIn,
            //               ),
            //             )
            //           : Image.asset(
            //               AppAssets.editPenIcon,
            //               height: 14,
            //               width: 14,
            //               color: AppColors.surfaceLight,
            //               errorBuilder: (context, error, stackTrace) =>
            //                   const Icon(Icons.edit, size: 14, color: Colors.white),
            //             ),
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(width: 20),

        // User Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: context.textTheme.titleLarge?.copyWith(
                  color: AppColors.surfaceLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,

                  style: context.textTheme.bodyMedium?.copyWith(
                    overflow: .ellipsis,
                    color: AppColors.surfaceLight.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${context.l10n.memberSincePrefix} $memberSince',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
