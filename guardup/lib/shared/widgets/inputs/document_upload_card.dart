import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:guardup/shared/widgets/misc/app_input_label.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/feedbacks/widgets/app_file_preview.dart';
import '../sections/app_image.dart';

/// A sleek, dumb document upload card matching GuardUp dark luxury design standards.
///
/// Behavior:
/// - When no file is selected: shows document icon, title, optional description, and "Upload" button.
/// - When a file is selected: changes icon to a thumbnail/file badge, shows filename with green checkmark,
///   "View" (preview) button, and "Change" action with icon.
/// - Supports [selectedFilePath] (local file path) and [initialUrl] (remote file URL).
/// - When [isLoading] is true, disables all interactions and shows a loading spinner.
class DocumentUploadCard extends StatelessWidget {
  /// The title of the document (e.g. "Additional Documents", "Transit Pass").
  final String title;

  /// Optional subtitle or guidance description.
  final String? description;

  /// Local file path of the selected document.
  final String? selectedFilePath;

  /// Remote URL of an existing document.
  final String? initialUrl;

  /// Optional override for the displayed file name.
  final String? fileName;

  /// Whether this document is required (renders a red asterisk *).
  final bool isRequired;

  /// When true, disables clicks and renders a loading indicator.
  final bool isLoading;

  /// When true, hides Change and Upload actions and only allows viewing/previewing the document.
  final bool isReadOnly;

  /// Callback when user taps "Upload" or "Change".
  final VoidCallback? onPick;

  /// Callback when an upload action is triggered.
  final VoidCallback? onUpload;

  /// Callback when user taps "View". If null, automatically opens [AppFilePreviewSheet].
  final VoidCallback? onPreview;

  /// Optional custom leading icon when no file is selected.
  final Widget? icon;

  /// Label for initial select button. Defaults to "Select".
  final String selectLabel;

  /// Label for upload button. Defaults to "Upload".
  final String uploadLabel;

  /// Label for change action. Defaults to "Change".
  final String changeLabel;

  /// Label for preview action. Defaults to "View".
  final String viewLabel;

  /// Allowed file extensions. Defaults to `['pdf', 'jpg', 'jpeg', 'png']`.
  final List<String> allowedExtensions;

  const DocumentUploadCard({
    super.key,
    required this.title,
    this.description,
    this.selectedFilePath,
    this.initialUrl,
    this.fileName,
    this.isRequired = false,
    this.isLoading = false,
    this.isReadOnly = false,
    this.onPick,
    this.onUpload,
    this.onPreview,
    this.icon,
    this.selectLabel = 'Select',
    this.uploadLabel = 'Upload',
    this.changeLabel = 'Change',
    this.viewLabel = 'View',
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  });

  bool get _hasFile =>
      (selectedFilePath != null && selectedFilePath!.trim().isNotEmpty) ||
      (initialUrl != null && initialUrl!.trim().isNotEmpty);

  String get _resolvedFileName {
    if (fileName != null && fileName!.isNotEmpty) return fileName!;
    if (selectedFilePath != null && selectedFilePath!.isNotEmpty) {
      return selectedFilePath!.split('/').last;
    }
    if (initialUrl != null && initialUrl!.isNotEmpty) {
      final sanitized = initialUrl!.split('?').first.split('/').last;
      if (sanitized.isNotEmpty) return Uri.decodeComponent(sanitized);
    }
    return 'Document';
  }

  bool get _isImage {
    final path = (selectedFilePath?? initialUrl ?? '')
        .toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic');
  }

  bool get _isPdf {
    final path = (selectedFilePath  ?? initialUrl ?? '')
        .toLowerCase();
    return path.endsWith('.pdf');
  }

  void _handlePreview(BuildContext context) {
    if (onPreview != null) {
      onPreview!.call();
      return;
    }

    if (!_hasFile) return;

    final resolvedFile =
        (selectedFilePath != null && selectedFilePath!.isNotEmpty
            ? XFile(selectedFilePath!)
            : null);

    AppFilePreviewSheet.show(
      context: context,
      title: title,
      file: resolvedFile,
      fileUrl: initialUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isLoading,
      child: GestureDetector(
        onTap: isReadOnly && _hasFile
            ? () => _handlePreview(context)
            : (!_hasFile && !isReadOnly ? onPick : null),
        child: QuickContainer(
        p: AppSpacing.lg,
        radius: AppRadius.lg,
        color: context.colors.surfaceContainer.withValues(alpha: 0.72),
        border: Border.all(color: context.colors.outlineVariant, width: 1),
        child: Row(
          children: [
            // 1. Leading Icon / Thumbnail
            _buildLeading(context),
            AppSpacing.md.w,

            // 2. Title & Status / Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFieldLabel(
                    text: title,
                    isRequired: isRequired,
                    labelStyle: context.textTheme.bodyLarge?.decreaseSize(1),
                  ),
                  if (_hasFile) ...[
                    AppSpacing.xxs.h,
                    _buildFileStatusRow(context),
                  ] else if (description != null &&
                      description!.isNotEmpty) ...[
                    AppSpacing.xxs.h,
                    Text(
                      description!,
                      style: context.textTheme.labelSmall?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.sm.w,

            // 3. Trailing Actions / Loading
            _buildTrailingActions(context),
          ],
        ),
      ),
    ),
  );
}

  /// Builds the leading document icon, image thumbnail, or PDF badge.
  Widget _buildLeading(BuildContext context) {
    const size = 46.0;

    if (_hasFile) {
      if (_isImage) {
        return GestureDetector(
          onTap: () => _handlePreview(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: size,
              height: size,
              child: _buildImageWidget(),
            ),
          ),
        );
      }

      if (_isPdf) {
        return GestureDetector(
          onTap: () => _handlePreview(context),
          child: QuickContainer(
            w: size,
            h: size,
            radius: AppRadius.md,
            color: context.colors.error.withValues(alpha: 0.12),
            border: Border.all(
              color: context.colors.error.withValues(alpha: 0.3),
              width: 1,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: context.colors.error,
              size: 24,
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: () => _handlePreview(context),
        child: QuickContainer(
          w: size,
          h: size,
          radius: AppRadius.md,
          color: context.colors.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.insert_drive_file_rounded,
            color: context.colors.primary,
            size: 24,
          ),
        ),
      );
    }

    // Default unselected state: dark square with gold document icon
    return QuickContainer(
      w: size,
      h: size,
      radius: AppRadius.md,
      color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
      border: Border.all(
        color: context.colors.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      ),
      alignment: Alignment.center,
      child:
          icon ??
          Icon(
            Icons.description_outlined,
            color: context.colors.primary,
            size: 24,
          ),
    );
  }

  Widget _buildImageWidget() {
    if (selectedFilePath != null && selectedFilePath!.isNotEmpty) {
      return AppImage.file(
        file: io.File(selectedFilePath!),
        width: 46,
        height: 46,
        fit: BoxFit.cover,
      );
    }
    if (initialUrl != null && initialUrl!.isNotEmpty) {
      return AppImage.network(
        imageUrl: initialUrl!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.image_outlined, size: 24);
  }

  // /// Builds the title row with optional red asterisk.
  // Widget _buildTitleRow(BuildContext context) {
  //   return RichText(
  //     maxLines: 1,
  //     overflow: TextOverflow.ellipsis,
  //     text: TextSpan(
  //       style: context.textTheme.titleSmall?.bold().colour(
  //         context.colors.onSurface,
  //       ),
  //       children: [
  //         TextSpan(text: title),
  //         if (isRequired)
  //           TextSpan(
  //             text: ' *',
  //             style: TextStyle(
  //               color: context.colors.error,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  /// Builds the filename with green checkmark when a file is selected.
  Widget _buildFileStatusRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: context.colors.success,
          size: 15,
        ),
        AppSpacing.xxs.w,
        Flexible(
          child: Text(
            _resolvedFileName,
            style: context.textTheme.bodySmall?.bold().colour(
              context.colors.success,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds the right-side action (Select pill, View/Upload + Change actions, or loading spinner).
  Widget _buildTrailingActions(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
        ),
      );
    }

    if (_hasFile) {
      final bool showUploadButton = !isReadOnly && onUpload != null;
      final String actionButtonLabel =
          showUploadButton ? uploadLabel : viewLabel;
      final VoidCallback? actionCallback =
          showUploadButton ? onUpload : () => _handlePreview(context);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action Button: "Upload" if onUpload provided; "View" otherwise or in read-only
          GestureDetector(
            onTap: actionCallback,
            child: QuickContainer(
              px: 16,
              py: 5,
              radius: AppRadius.round,
              color: const Color(0xFF0F2922),
              border: Border.all(color: const Color(0xFF16654C), width: 1),
              alignment: Alignment.center,
              child: Text(
                actionButtonLabel,
                style: context.textTheme.labelMedium?.bold().colour(
                  const Color(0xFF22C55E),
                ),
              ),
            ),
          ),

          // "Change" Action Link (hidden if read-only)
          if (!isReadOnly) ...[
            AppSpacing.xxs.h,
            GestureDetector(
              onTap: onPick,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.crop_free_rounded,
                    size: 14,
                    color: context.colors.onSurface,
                  ),
                  AppSpacing.sm.w,
                  Text(
                    changeLabel,
                    style: context.textTheme.labelMedium?.semiBold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // When no file is selected:
    // If read-only, hide actions completely
    if (isReadOnly) {
      return const SizedBox.shrink();
    }

    // Default "Select" pill button
    return GestureDetector(
      onTap: onPick,
      child: QuickContainer(
        px: 18,
        py: 8,
        radius: AppRadius.round,
        color: const Color(0xFF0F2922),
        border: Border.all(color: const Color(0xFF16654C), width: 1),
        alignment: Alignment.center,
        child: Text(
          selectLabel,
          style: context.textTheme.labelMedium?.bold().colour(
            const Color(0xFF22C55E),
          ),
        ),
      ),
    );
  }
}
