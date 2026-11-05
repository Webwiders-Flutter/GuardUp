// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/number.extension.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/logger/app_logger.dart';
import '/core/services/media/media_picker.service.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';

class AppMediaPickerSheet extends StatefulWidget {
  final List<CropAspectRatioPreset>? aspectRatioPresets;
  final bool lockAspectRatio;
  final bool isVideo;
  final bool allowFile;
  final List<String>? allowedFileExtensions;
  final bool allowCrop;

  const AppMediaPickerSheet({
    super.key,
    this.aspectRatioPresets,
    this.lockAspectRatio = false,
    required this.isVideo,
    this.allowFile = false,
    this.allowedFileExtensions,
    this.allowCrop = false,
  });

  /// Displays the [AppMediaPickerSheet] in a bottom sheet using [AppSheet].
  static Future<XFile?> show({
    required BuildContext context,
    bool isVideo = false,
    bool allowFile = false,
    List<String>? allowedFileExtensions,
    bool allowCrop = false,
    List<CropAspectRatioPreset>? aspectRatioPresets,
    bool lockAspectRatio = false,
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
        allowCrop: allowCrop,
        aspectRatioPresets: aspectRatioPresets,
        lockAspectRatio: lockAspectRatio,
      ),
    );
  }

  @override
  State<AppMediaPickerSheet> createState() => _CustomImagePickerSheetState();
}

class _CustomImagePickerSheetState extends State<AppMediaPickerSheet> {
  Future<void> _handleMediaSelection(ImageSourceType source) async {
    AppLogger.d(
      "Picking media from ${source.name} (allowCrop: ${widget.allowCrop})",
    );

    final pickedFile = widget.isVideo
        ? await MediaPickerService.pickVideo(source)
        : await MediaPickerService.pickImage(source);

    if (!mounted || pickedFile == null) return;

    if (!widget.allowCrop || widget.isVideo) {
      context.pop<XFile?>(pickedFile);
      return;
    }

    final croppedFile = await MediaPickerService.cropImage(
      pickedFile.path,
      context.colors,
      aspectRatioPresets: widget.aspectRatioPresets,
      lockAspectRatio: widget.lockAspectRatio,
    );

    if (!mounted || croppedFile == null) return;
    context.pop<XFile?>(croppedFile);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.lg.xPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            icon: Icons.photo_library_rounded,
            title: context.l10n.chooseFromGallery,
            subtitle: widget.isVideo
                ? context.l10n.selectFromYourVideoLibrary
                : context.l10n.selectFromYourPhotoLibrary,
            onTap: () => _handleMediaSelection(ImageSourceType.gallery),
          ),
          AppSpacing.md.h,
          _buildOptionTile(
            icon: Icons.camera_alt_rounded,
            title: context.l10n.takeAPhoto,
            subtitle: context.l10n.useCameraToCaptureNewImage,
            onTap: () => _handleMediaSelection(ImageSourceType.camera),
          ),
          if (widget.allowFile) ...[
            AppSpacing.md.h,
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

                if (!mounted || pickedFile == null) return;
                context.pop<XFile?>(pickedFile);
              },
            ),
          ],
          AppSpacing.lg.h,
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
        borderRadius: AppRadius.lg.toBorderRadius,
        onTap: onTap,
        child: QuickContainer(
          p: AppSpacing.md,
          color: context.colors.surfaceContainer.withValues(alpha: 0.72),
          radius: AppRadius.lg,
          border: Border.all(color: context.colors.outlineVariant, width: 1),
          child: Row(
            children: [
              QuickContainer(
                w: 48,
                h: 48,
                gradient: context.colors.primaryGradient,
                radius: AppRadius.md,
                alignment: Alignment.center,
                child: Icon(icon, color: context.colors.onPrimary, size: 24),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textTheme.titleMedium?.bold()),
                    AppSpacing.xs.h,
                    Text(
                      subtitle,
                      style: context.textTheme.labelMedium?.colour(
                        context.colors.onSurfaceVariant,
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
