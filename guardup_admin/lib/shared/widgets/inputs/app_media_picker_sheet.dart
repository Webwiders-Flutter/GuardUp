// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/extensions/localization.extension.dart';
import '/core/services/media/media_picker.service.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';

import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';

class AppMediaPickerSheet extends StatefulWidget {
  final List<CropAspectRatioPreset>? aspectRatioPresets;
  final bool lockAspectRatio;
  final bool isVideo;
  final bool allowFile;
  final List<String>? allowedFileExtensions;

  const AppMediaPickerSheet({
    super.key,
    this.aspectRatioPresets,
    this.lockAspectRatio = false,
    required this.isVideo,
    this.allowFile = false,
    this.allowedFileExtensions,
  });

  /// Displays the [AppMediaPickerSheet] in a bottom sheet using [AppSheet].
  static Future<XFile?> show({
    required BuildContext context,
    bool isVideo = false,
    bool allowFile = false,
    List<String>? allowedFileExtensions,
  }) {
    return AppSheet.show<XFile?>(
      title: allowFile
          ? context.l10n.selectDocument
          : (isVideo ? context.l10n.selectAVideo : context.l10n.selectAnImage),
      subtitle: allowFile
          ? context.l10n.chooseSource
          : (isVideo
                ? context.l10n.chooseFromYourVideoLibraryOrTakeAVideo
                : context.l10n.chooseFromYourGalleryOrTakeAPhoto),
      context: context,
      child: AppMediaPickerSheet(
        isVideo: isVideo,
        allowFile: allowFile,
        allowedFileExtensions: allowedFileExtensions,
      ),
    );
  }

  @override
  State<AppMediaPickerSheet> createState() => _CustomImagePickerSheetState();
}

class _CustomImagePickerSheetState extends State<AppMediaPickerSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: 16.xPadding,
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.photo_library_rounded,
            title: context.l10n.chooseFromGallery,
            subtitle: widget.isVideo
                ? context.l10n.selectFromYourVideoLibrary
                : context.l10n.selectFromYourPhotoLibrary,
            onTap: () async {
              final pickedFile = widget.isVideo
                  ? await MediaPickerService.pickVideo(ImageSourceType.gallery)
                  : await MediaPickerService.pickImage(ImageSourceType.gallery);

              if (!mounted) return;
              context.pop<XFile?>(pickedFile);
            },
          ),
          12.h,
          _buildOptionTile(
            icon: Icons.camera_alt_rounded,
            title: context.l10n.takeAPhoto,
            subtitle: context.l10n.useCameraToCaptureNewImage,
            onTap: () async {
              final pickedFile = widget.isVideo
                  ? await MediaPickerService.pickVideo(ImageSourceType.camera)
                  : await MediaPickerService.pickImage(ImageSourceType.camera);

              if (!mounted) return;
              context.pop<XFile?>(pickedFile);
            },
          ),
          if (widget.allowFile) ...[
            12.h,
            _buildOptionTile(
              icon: Icons.folder_rounded,
              title: context.l10n.chooseFile,
              subtitle: context.l10n.selectFromYourFiles,
              onTap: () async {
                final pickedFile = await MediaPickerService.pickDocument(
                  allowedExtensions:
                      widget.allowedFileExtensions ??
                      const ['pdf', 'jpg', 'jpeg', 'png'],
                );

                if (!mounted) return;
                context.pop<XFile?>(pickedFile);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: QuickContainer(
          p: 16,
          color: context.colors.borderLight,
          radius: AppRadius.lg,
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              QuickContainer(
                w: 48,
                h: 48,
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary.withValues(alpha: 0.9),
                    context.colors.primary.withValues(alpha: 0.5),
                  ],
                ),
                radius: AppRadius.md,
                shadows: [
                  BoxShadow(
                    color: context.colors.backgroundLight.withValues(
                      alpha: 0.2,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],

                child: Icon(icon, color: context.colors.surface, size: 24),
              ),
              16.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textTheme.titleMedium),
                    4.h,
                    Text(
                      subtitle,
                      style: context.textTheme.labelMedium?.colour(
                        context.colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: context.colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
