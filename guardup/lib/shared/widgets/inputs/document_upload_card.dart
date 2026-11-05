import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/shared/widgets/feedbacks/widgets/app_file_preview.dart';
import '../sections/app_image.dart';
import '../sections/wrapper_card.dart';

/// A sleek, dumb document upload card matching GuardUp dark luxury design standards.
///
/// Behavior:
/// - When no file is selected: shows document icon, title, optional REQ badge / (Optional) text
///   or custom [iconWidget], optional description, and a "+" button or "Upload" button with icon.
/// - When a file is selected: changes icon to a thumbnail/file badge, shows filename with green checkmark,
///   "View" / "Upload" button with icon, and "Change" action with icon.
/// - If [description] is provided, the leading icon container and icon scale up to balance the two-line height.
/// - Supports [selectedFilePath] (local file path) and [initialUrl] (remote file URL).
/// - When [isLoading] is true, disables all interactions and shows a loading spinner.
class DocumentUploadCard extends StatelessWidget {
  /// The title of the document (e.g. "Security License", "Certifications").
  final String title;

  /// Optional subtitle or guidance description.
  final String? description;

  /// Local file path of the selected document.
  final String? selectedFilePath;

  /// Remote URL of an existing document.
  final String? initialUrl;

  /// Optional override for the displayed file name.
  final String? fileName;

  /// Whether this document is required (renders a red "REQ" badge). Defaults to `false`.
  final bool isRequired;

  /// Whether this document is optional (renders "(Optional)" text). Defaults to `false`.
  final bool isOptional;

  /// Optional custom icon or widget displayed next to the title instead of
  /// the "REQ" badge or "(Optional)" text.
  final Widget? iconWidget;

  /// When true, disables clicks and renders a loading indicator.
  final bool isLoading;

  /// When true, hides Change and Upload actions and only allows viewing/previewing the document.
  final bool isReadOnly;

  /// Whether to show the file name row and allow document previewing.
  /// Defaults to `true`. When `false`:
  /// - Hides the "View" action button
  /// - Disables card tap previewing
  /// - Hides the file status/filename row below the document title
  final bool showPreview;

  /// Verification status for the document.
  /// When provided, displays a status pill badge ("Verified", "Pending", "Rejected")
  /// styled with semantic colors retrieved directly from [DocumentStatus].
  final DocumentStatus? status;

  /// Explicitly control whether to show the "Upload" button instead of "+".
  /// If null, automatically shown when [onUpload] is provided.
  final bool? showUploadButton;

  /// Callback when user taps the "+" button, the card, or "Change".
  final VoidCallback? onPick;

  /// Callback when an upload action is triggered.
  final VoidCallback? onUpload;

  /// Callback when user taps "View". If null, automatically opens [AppFilePreviewSheet].
  final VoidCallback? onPreview;

  /// Optional custom leading icon when no file is selected.
  final Widget? icon;

  /// Label for initial select button (kept for backwards compatibility).
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
    this.isOptional = false,
    this.iconWidget,
    this.isLoading = false,
    this.isReadOnly = false,
    this.showPreview = true,
    this.status,
    this.showUploadButton,
    this.onPick,
    this.onUpload,
    this.onPreview,
    this.icon,
    this.selectLabel = 'Select',
    this.uploadLabel = 'Upload',
    this.changeLabel = 'Change',
    this.viewLabel = 'View',
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
  }) : assert(
         !(isRequired && isOptional),
         'Both isRequired and isOptional cannot be true simultaneously',
       );

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
    final path = (selectedFilePath ?? initialUrl ?? '').toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic');
  }

  bool get _isPdf {
    final path = (selectedFilePath ?? initialUrl ?? '').toLowerCase();
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
    final bool hasDescription =
        description != null && description!.trim().isNotEmpty;

    final VoidCallback? tapCallback = isReadOnly && _hasFile && showPreview
        ? () => _handlePreview(context)
        : (!_hasFile && !isReadOnly ? onPick : null);

    return IgnorePointer(
      ignoring: isLoading,
      child: WrapperCard(
        onTap: tapCallback,
        padding: AppSpacing.lg.allPadding,
        child: Row(
          children: [
            // 1. Leading Icon / Thumbnail
            _buildLeading(context, hasDescription),
            AppSpacing.md.w,

            // 2. Title & Status / Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTitleRow(context),
                  if (_hasFile && showPreview) ...[
                    AppSpacing.xxs.h,
                    _buildFileStatusRow(context),
                  ] else if (hasDescription) ...[
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
    );
  }

  /// Builds the title row with optional [iconWidget], "REQ" badge, or "(Optional)" label.
  Widget _buildTitleRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: context.textTheme.bodyLarge?.decreaseSize(1).semiBold(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (iconWidget != null) ...[
          AppSpacing.xs.w,
          iconWidget!,
        ] else if (isRequired) ...[
          AppSpacing.xs.w,
          _buildRequiredBadge(context),
        ] else if (isOptional) ...[
          AppSpacing.xs.w,
          _buildOptionalLabel(context),
        ],
      ],
    );
  }

  /// Builds the red "REQ" badge as shown in the design.
  Widget _buildRequiredBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(
          color: context.colors.error.withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: Text(
        'REQ',
        style: context.textTheme.labelSmall?.bold().copyWith(
          color: context.colors.error,
          fontSize: 10,
          letterSpacing: 0.5,
          height: 1.1,
        ),
      ),
    );
  }

  /// Builds the muted "(Optional)" label as shown in the design.
  Widget _buildOptionalLabel(BuildContext context) {
    return Text(
      '(Optional)',
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant.withValues(alpha: 0.72),
        fontSize: 11,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  /// Builds the leading document icon, image thumbnail, or PDF badge.
  /// If [hasDescription] is true, sizes scale up to visually align with two-line content.
  Widget _buildLeading(BuildContext context, bool hasDescription) {
    final double containerSize = hasDescription ? 52.0 : 44.0;
    final double iconSize = hasDescription ? 28.0 : 22.0;

    // If a custom icon is provided and preview is disabled, show the custom icon instead of file type or preview
    if (_hasFile && (showPreview || icon == null)) {
      if (_isImage) {
        return GestureDetector(
          onTap: showPreview ? () => _handlePreview(context) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: containerSize,
              height: containerSize,
              child: _buildImageWidget(containerSize),
            ),
          ),
        );
      }

      if (_isPdf) {
        return GestureDetector(
          onTap: showPreview ? () => _handlePreview(context) : null,
          child: QuickContainer(
            w: containerSize,
            h: containerSize,
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
              size: iconSize,
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: showPreview ? () => _handlePreview(context) : null,
        child: QuickContainer(
          w: containerSize,
          h: containerSize,
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
            size: iconSize,
          ),
        ),
      );
    }

    // Default unselected state: dark square with gold document/custom icon
    return QuickContainer(
      w: containerSize,
      h: containerSize,
      radius: AppRadius.md,
      color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
      border: Border.all(
        color: context.colors.outlineVariant.withValues(alpha: 0.6),
        width: 1,
      ),
      alignment: Alignment.center,
      child: _buildLeadingIcon(context, hasDescription, iconSize),
    );
  }

  Widget _buildLeadingIcon(
    BuildContext context,
    bool hasDescription,
    double defaultSize,
  ) {
    if (icon == null) {
      return Icon(
        Icons.description_outlined,
        color: context.colors.primary,
        size: defaultSize,
      );
    }

    if (icon is Icon) {
      final original = icon as Icon;
      final double targetSize = hasDescription
          ? (original.size != null
                ? (original.size! >= 26 ? original.size! : defaultSize)
                : defaultSize)
          : (original.size ?? defaultSize);

      return Icon(
        original.icon,
        color: original.color ?? context.colors.primary,
        size: targetSize,
        semanticLabel: original.semanticLabel,
        textDirection: original.textDirection,
        shadows: original.shadows,
      );
    }

    return IconTheme.merge(
      data: IconThemeData(size: defaultSize, color: context.colors.primary),
      child: icon!,
    );
  }

  Widget _buildImageWidget(double size) {
    if (selectedFilePath != null && selectedFilePath!.isNotEmpty) {
      return AppImage.file(
        file: io.File(selectedFilePath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    if (initialUrl != null && initialUrl!.isNotEmpty) {
      return AppImage.network(
        imageUrl: initialUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }
    return Icon(Icons.image_outlined, size: size * 0.5);
  }

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
            style: context.textTheme.bodySmall?.colour(context.colors.success),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds the right-side action ("+" button, "Upload" button with icon,
  /// "View" button with icon, status badge, or loading spinner).
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

    final statusBadge =
        status != null ? _buildStatusBadge(context, status!) : null;

    if (isReadOnly && !_hasFile) {
      return statusBadge ?? const SizedBox.shrink();
    }

    if (_hasFile) {
      final viewButton = showPreview
          ? _buildActionButton(
              context: context,
              label: viewLabel,
              icon: Icons.visibility_outlined,
              onTap: () => _handlePreview(context),
            )
          : null;

      final changeButton = !isReadOnly
          ? GestureDetector(
              onTap: onPick,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    changeLabel,
                    style: context.textTheme.labelMedium?.semiBold().colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.xs.w,
                  Icon(
                    Icons.change_circle,
                    size: 14,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            )
          : null;

      if (viewButton == null && changeButton == null) {
        return statusBadge ?? const SizedBox.shrink();
      }

      final buttonStack = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?viewButton,
          if (changeButton != null) ...[
            if (viewButton != null) AppSpacing.xxs.h,
            changeButton,
          ],
        ],
      );

      if (statusBadge != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buttonStack,
            AppSpacing.sm.w,
            statusBadge,
          ],
        );
      }

      return buttonStack;
    }

    // When no file is selected:
    final actionButton = _buildAddButton(context);
    if (statusBadge != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          actionButton,
          AppSpacing.sm.w,
          statusBadge,
        ],
      );
    }

    return actionButton;
  }

  /// Builds the status pill badge (e.g. "Verified", "Pending", "Rejected").
  Widget _buildStatusBadge(BuildContext context, DocumentStatus status) {
    final color = status.badgeColor(context);
    final bgColor = status.badgeBackgroundColor(context);
    final borderColor = status.badgeBorderColor(context);

    return QuickContainer(
      px: 14,
      py: 6,
      radius: AppRadius.full,
      color: bgColor,
      border: Border.all(color: borderColor, width: 1.0),
      child: Text(
        status.label,
        style: context.textTheme.labelSmall?.semiBold().colour(color),
      ),
    );
  }

  /// Action button with outline border, leading icon, and gold text (used for "Upload" and "View").
  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: QuickContainer(
        px: 14,
        py: 8,
        radius: AppRadius.md,
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.4),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.45),
          width: 1,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.colors.primary),
            AppSpacing.xs.w,
            Text(
              label,
              style: context.textTheme.labelMedium?.bold().colour(
                context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Modern "+" action button used when no file is selected.
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: QuickContainer(
        w: 42,
        h: 42,
        radius: AppRadius.md,
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.4),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.7),
          width: 1,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, color: context.colors.primary, size: 22),
      ),
    );
  }
}
