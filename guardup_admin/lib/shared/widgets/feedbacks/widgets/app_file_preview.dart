import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/file_object.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '../../buttons/app_button.dart';
import 'app_sheet.dart';
import '../../sections/app_image.dart';
import 'app_dialog.dart';

/// Interactive document preview sheet for images and PDF/document files.
class AppFilePreviewSheet extends StatelessWidget {
  final XFile? file;
  final String? fileUrl;
  final String title;

  const AppFilePreviewSheet({
    super.key,
    this.file,
    this.fileUrl,
    required this.title,
  }) : assert(
         (file != null) ^ (fileUrl != null),
         'Either file or fileUrl must be provided, and only one can be provided at a time.',
       );

  /// Displays the [AppFilePreviewSheet] in a bottom sheet using [AppSheet].
  static Future<void> show({
    required BuildContext context,
    required String title,
    XFile? file,
    String? fileUrl,
  }) {
    return AppSheet.show<void>(
      context: context,
      title: title,
      action: AppSheetHeaderAction.close,
      child: AppFilePreviewSheet(file: file, fileUrl: fileUrl, title: title),
    );
  }

  /// Displays the [AppFilePreviewSheet] in a modal dialog using [AppDialogs].
  static Future<void> showDialog({
    required BuildContext context,
    required String title,
    XFile? file,
    String? fileUrl,
    bool barrierDismissible = true,
  }) {
    return AppDialogs.show(
      context: context,
      title: title,
      barrierDismissible: barrierDismissible,
      child: AppFilePreviewSheet(file: file, fileUrl: fileUrl, title: title),
    );
  }

  bool get _isImage => file.isImage || fileUrl.isImage || _fileName.isImage;
  String get _fileName => file?.fileName.isNotEmpty == true
      ? file!.fileName
      : fileUrl?.fileName ?? '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalEdgeInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isImage)
            _buildImagePreview(context)
          else
            _buildDocumentPreview(context),
          AppSpacing.lg.h,
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: QuickContainer(
            color: context.colors.borderLight.withValues(alpha: 0.3),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: AppImage.auto(
                source: fileUrl ?? file,
                fit: BoxFit.contain,
                height: 70.hPercent(context),
                errorWidget: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: context.colors.error,
                        ),
                        AppSpacing.sm.h,
                        Text(
                          'Failed to load image preview',
                          style: context.textTheme.bodySmall?.colour(
                            context.colors.error,
                          ),
                        ),
                        if (fileUrl != null && fileUrl!.isNotEmpty) ...[
                          AppSpacing.sm.h,
                          TextButton.icon(
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                            ),
                            label: const Text('Open link in browser'),
                            onPressed: () =>
                                AppLauncher.launchUrlString(fileUrl!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        AppSpacing.md.h,
        if (fileUrl != null && fileUrl!.isNotEmpty)
          AppButton(
            text: 'Open Full Resolution in New Tab',
            leading: const Icon(Icons.open_in_new_rounded, size: 18),
            onPressed: () => AppLauncher.launchUrlString(fileUrl!),
          )
        else if (!kIsWeb)
          Text(
            'Pinch or double tap to zoom',
            style: context.textTheme.labelSmall?.colour(
              context.colors.onSurfaceSecondary,
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpacing.md.h,
        QuickContainer(
          p: AppSpacing.xl,
          color: context.colors.errorLight,
          shape: QuickContainerShape.circle,
          child: Icon(
            Icons.picture_as_pdf_rounded,
            size: AppSpacing.xxxl + AppSpacing.lg,
            color: context.colors.error,
          ),
        ),
        AppSpacing.md.h,
        Text(
          _fileName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.semiBold().colour(
            context.colors.onSurface,
          ),
        ),
        if (file != null)
          FutureBuilder<String>(
            future: file!.getFormattedSize(),
            initialData: file!.formattedSize,
            builder: (context, snapshot) {
              final fileSize = snapshot.data ?? '';
              if (fileSize.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  fileSize,
                  style: context.textTheme.labelSmall?.colour(
                    context.colors.onSurfaceSecondary,
                  ),
                ),
              );
            },
          ),
        AppSpacing.xl.h,
        AppButton(
          text: 'Open Document',
          leading: const Icon(Icons.open_in_new_rounded),
          onPressed: () {
            if (file != null) {
              AppLauncher.launchFile(file!.path);
            } else if (fileUrl != null) {
              AppLauncher.launchUrlString(fileUrl!);
            }
          },
        ),
      ],
    );
  }
}
