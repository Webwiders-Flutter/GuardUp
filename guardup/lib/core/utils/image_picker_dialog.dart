import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/services/media_picker_service.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

Future<File?> showImagePickerDialog(
  BuildContext context,
  MediaPickerService mediaPickerService, {
  String? title,
  bool cropImage = true,
}) {
  final displayTitle = title ?? context.l10n.selectPhoto;
  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.transparent,
    // useSafeArea: true,
    builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                displayTitle,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: context.l10n.camera,
                    color: AppColors.secondary,
                    onTap: () async {
                      // Pop the sheet immediately with the result of picking + cropping.
                      // We must NOT hold the sheet open while UCropActivity is running —
                      // doing so can invalidate the context on low-memory Android devices
                      // and cause a crash when the crop activity returns.
                      final file = await mediaPickerService.pickImage(
                        source: ImageSource.camera,
                        cropImage: cropImage,
                        context: context,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(file);
                      }
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: context.l10n.gallery,
                    color: Colors.blue.shade400,
                    onTap: () async {
                      // Pop the sheet immediately with the result of picking + cropping.
                      final file = await mediaPickerService.pickImage(
                        source: ImageSource.gallery,
                        cropImage: cropImage,
                        context: context,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(file);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Future<File?> showPickFileDialog(
  BuildContext context,
  MediaPickerService mediaPickerService, {
  String? title,
  bool cropImage = false,
  List<String> allowedExtensions = const [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ],
}) {
  final isArabic = context.isArabic;
  final displayTitle = title ?? (isArabic ? 'اختر ملف' : 'Pick File');

  return showModalBottomSheet<File?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                displayTitle,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: context.l10n.camera,
                    color: AppColors.secondary,
                    onTap: () async {
                      final file = await mediaPickerService.pickImage(
                        source: ImageSource.camera,
                        cropImage: cropImage,
                        context: context,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(file);
                      }
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: context.l10n.gallery,
                    color: Colors.blue.shade400,
                    onTap: () async {
                      final file = await mediaPickerService.pickImage(
                        source: ImageSource.gallery,
                        cropImage: cropImage,
                        context: context,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(file);
                      }
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.insert_drive_file_rounded,
                    label: isArabic ? 'ملف' : 'File',
                    color: Colors.teal.shade500,
                    onTap: () async {
                      final file = await mediaPickerService.pickDocument(
                        allowedExtensions: allowedExtensions,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(file);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}

Future<File?> showFilePickerDialog(
  BuildContext context,
  MediaPickerService mediaPickerService, {
  String? title,
  bool cropImage = false,
  List<String> allowedExtensions = const [
    'pdf',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'webp',
  ],
}) => showPickFileDialog(
  context,
  mediaPickerService,
  title: title,
  cropImage: cropImage,
  allowedExtensions: allowedExtensions,
);

Widget _buildImagePickerOption(
  BuildContext context, {
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.blackColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    ),
  );
}

Future<ImageSource?> showVideoSourceDialog(
  BuildContext context, {
  String? title,
}) {
  final displayTitle = title ?? context.l10n.selectVideoSource;
  return showModalBottomSheet<ImageSource?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                displayTitle,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImagePickerOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: context.l10n.camera,
                    color: Colors.purple.shade400,
                    onTap: () {
                      Navigator.of(context).pop(ImageSource.camera);
                    },
                  ),
                  _buildImagePickerOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: context.l10n.gallery,
                    color: Colors.blue.shade400,
                    onTap: () {
                      Navigator.of(context).pop(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    },
  );
}
