import 'dart:io';

import 'package:flutter/material.dart';
import 'package:guardup/core/app_types/image_types.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/widgets/app_image/app_image.dart';

class AppCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final double radius;
  final Color? backgroundColor;
  final bool showBorder;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;

  const AppCircleAvatar({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.radius = 45.0,
    this.backgroundColor,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.isNotEmpty == true || imageFile != null;
    final finalImageUrl = imageUrl ?? '';

    return Container(
      height: radius * 2,
      width: radius * 2,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color:
                    borderColor ?? AppColors.secondary.withValues(alpha: 0.3),
                width: borderWidth ?? 1,
              )
            : null,
      ),
      child: hasImage
          ? AppImage(
              height: radius * 2,
              width: radius * 2,
              shape: BoxShape.circle,
              backgroundColor:
                  backgroundColor ?? AppColors.primary.withValues(alpha: 0.2),
              imageUrl: finalImageUrl,
              imageFile: imageFile,
              appFileType: imageFile != null
                  ? AppImageTypes.file
                  : (finalImageUrl.startsWith('http')
                        ? AppImageTypes.network
                        : AppImageTypes.asset),
              onTap: onTap,
              errorWidget: const DefaultProfileIcon(),
            )
          : GestureDetector(onTap: onTap, child: const DefaultProfileIcon()),
    );
  }
}

class DefaultProfileIcon extends StatelessWidget {
  const DefaultProfileIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade700, // Dark grey for the person (hollow part)
        shape: BoxShape.circle,
      ),
      child: const FittedBox(
        child: Icon(
          Icons.account_circle,
          color: Colors.grey, // Light grey for the circle
        ),
      ),
    );
  }
}
