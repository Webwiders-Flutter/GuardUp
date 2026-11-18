import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/file_object.extension.dart';
import '../../../core/extensions/spacing.extension.dart';
import '../../../core/extensions/textstyle_extension.dart';
import '../../../core/logger/app_logger.dart';
import '/core/services/media/media_picker.service.dart';
import '../buttons/app_button.dart';
import '../feedbacks/widgets/app_file_preview.dart';
import '../feedbacks/widgets/app_snackbar.dart';
import '../sections/app_image.dart';

/// Represents the current upload state.
enum DocumentUploadState { idle, fileSelected, uploaded }

/// A modern, SaaS-grade document & media upload card optimized for Admin Dashboards.
///
/// Features:
/// - Fully responsive dropzone and file card (adapts to mobile, sidebars, and desktop)
/// - Optional [width] and [height] constraints
/// - Dotted / dashed dropzone border with smooth hover styling
/// - Cross-platform support (Flutter Web, macOS desktop, iOS/Android)
/// - Thumbnail preview for images (local bytes, XFiles, and remote URLs)
/// - Clean horizontal / stacked file card when a file is selected or uploaded
/// - Supports both local [XFile] and existing remote network [initialUrl]
/// - Desktop-friendly preview dialog (instead of mobile bottom sheet)
/// - Actions: Browse, Preview, Replace, Remove, and optional Upload
/// - State managed cleanly via [ValueNotifier]s instead of `setState`
class AppMediaPickerCard extends StatefulWidget {
  final String title;
  final String? description;
  final String? fileName;
  final String actionLabel;
  final SvgPicture Function(double size)? svgBuilder;
  final Widget? icon;
  final Widget? action;
  final Color? iconColor;
  final Color? borderColor;
  final Color? fillColor;
  final XFile? initialFile;
  final String? initialUrl;
  final ValueChanged<XFile?>? onFilePicked;
  final ValueChanged<XFile?>? onPicked;
  final VoidCallback? onFileRemoved;
  final Future<void> Function(XFile file)? onUpload;
  final List<String> allowedExtensions;
  final double? width;
  final double? height;
  final String? maxSize;
  final bool isRequired;
  final bool enabled;
  final bool supportUpload;
  final bool readOnly;
  final bool showStatus;

  const AppMediaPickerCard({
    super.key,
    required this.title,
    this.description,
    this.fileName,
    this.actionLabel = 'Browse file',
    this.svgBuilder,
    this.icon,
    this.action,
    this.iconColor,
    this.fillColor,
    this.borderColor,
    this.initialFile,
    this.initialUrl,
    this.onFilePicked,
    this.onPicked,
    this.onFileRemoved,
    this.onUpload,
    this.allowedExtensions = const ['png', 'jpg', 'jpeg', 'webp', 'svg', 'pdf'],
    this.width,
    this.height,
    this.maxSize,
    this.isRequired = false,
    this.enabled = true,
    this.supportUpload = false,
    this.readOnly = false,
    this.showStatus = true,
  });

  @override
  State<AppMediaPickerCard> createState() => _AppMediaPickerCardState();
}

class _AppMediaPickerCardState extends State<AppMediaPickerCard> {
  late final ValueNotifier<DocumentUploadState> _stateNotifier;
  late final ValueNotifier<XFile?> _selectedFileNotifier;
  late final ValueNotifier<Uint8List?> _fileBytesNotifier;
  late final ValueNotifier<String?> _remoteUrlNotifier;
  late final ValueNotifier<bool> _isLoadingNotifier;
  late final ValueNotifier<bool> _isHoveredNotifier;

  @override
  void initState() {
    super.initState();
    _stateNotifier = ValueNotifier<DocumentUploadState>(
      DocumentUploadState.idle,
    );
    _selectedFileNotifier = ValueNotifier<XFile?>(widget.initialFile);
    _fileBytesNotifier = ValueNotifier<Uint8List?>(null);
    _remoteUrlNotifier = ValueNotifier<String?>(widget.initialUrl);
    _isLoadingNotifier = ValueNotifier<bool>(false);
    _isHoveredNotifier = ValueNotifier<bool>(false);

    _initInitialState();
  }

  @override
  void didUpdateWidget(covariant AppMediaPickerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFile != widget.initialFile ||
        oldWidget.initialUrl != widget.initialUrl) {
      _initInitialState();
    }
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _selectedFileNotifier.dispose();
    _fileBytesNotifier.dispose();
    _remoteUrlNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isHoveredNotifier.dispose();
    super.dispose();
  }

  void _initInitialState() {
    if (widget.initialFile != null) {
      _selectedFileNotifier.value = widget.initialFile;
      _remoteUrlNotifier.value = null;
      _stateNotifier.value = widget.supportUpload
          ? DocumentUploadState.uploaded
          : DocumentUploadState.fileSelected;
      _loadFileBytes(widget.initialFile!);
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _selectedFileNotifier.value = null;
      _fileBytesNotifier.value = null;
      _remoteUrlNotifier.value = widget.initialUrl;
      _stateNotifier.value = DocumentUploadState.uploaded;
    } else {
      _selectedFileNotifier.value = null;
      _fileBytesNotifier.value = null;
      _remoteUrlNotifier.value = null;
      _stateNotifier.value = DocumentUploadState.idle;
    }
  }

  Future<void> _loadFileBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      if (mounted) {
        _fileBytesNotifier.value = bytes;
      }
    } catch (e, st) {
      AppLogger.e(
        'Error loading file bytes in AppMediaPickerCard',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _notifyPicked(XFile? file) {
    widget.onPicked?.call(file);
    widget.onFilePicked?.call(file);
  }

  String get _fileName {
    final file = _selectedFileNotifier.value;
    if (file != null && file.fileName.isNotEmpty) return file.fileName;
    if (widget.fileName != null && widget.fileName!.isNotEmpty) {
      return widget.fileName!;
    }
    return _remoteUrlNotifier.value?.fileName ?? '';
  }

  bool get _isImage {
    final file = _selectedFileNotifier.value;
    if (file != null) {
      if (file.isImage || file.fileExtension.isImage || file.fileName.isImage) {
        return true;
      }
      if (widget.allowedExtensions.isNotEmpty &&
          widget.allowedExtensions.every((ext) => ext.isImage)) {
        return true;
      }
    }
    final url = _remoteUrlNotifier.value;
    if (url != null && url.isNotEmpty) {
      if (url.isImage ||
          url.fileExtension.isImage ||
          _fileName.isImage ||
          (widget.fileName?.isImage ?? false)) {
        return true;
      }
      if (widget.allowedExtensions.isNotEmpty &&
          widget.allowedExtensions.every((ext) => ext.isImage)) {
        return true;
      }
    }
    return false;
  }

  bool get _isSvg =>
      _selectedFileNotifier.value.isSvg || _remoteUrlNotifier.value.isSvg;

  bool get _isPdf =>
      _selectedFileNotifier.value.isPdf || _remoteUrlNotifier.value.isPdf;

  bool get _isVideo =>
      _selectedFileNotifier.value.isVideo || _remoteUrlNotifier.value.isVideo;

  String get _formattedFileSize {
    final bytes = _fileBytesNotifier.value;
    if (bytes != null) return formatBytes(bytes.length);
    if (_selectedFileNotifier.value != null) return 'Ready';
    if (_remoteUrlNotifier.value != null) return 'Cloud storage';
    return '';
  }

  Future<void> _pickFile() async {
    if (!widget.enabled || widget.readOnly || _isLoadingNotifier.value) return;

    try {
      final hasSvg = widget.allowedExtensions.any(
        (ext) => ext.toLowerCase().trim() == 'svg',
      );
      // If SVG is allowed or on web, use pickDocument (FilePicker) so that
      // vector SVG files are not rasterized to canvas PNGs by ImagePicker.
      final shouldUseImagePicker =
          !hasSvg &&
          !kIsWeb &&
          widget.allowedExtensions.isNotEmpty &&
          widget.allowedExtensions.every((ext) => ext.isImage);

      XFile? picked;
      if (shouldUseImagePicker) {
        picked = await MediaPickerService.pickImage(ImageSourceType.gallery);
      } else {
        picked = await MediaPickerService.pickDocument(
          allowedExtensions: widget.allowedExtensions,
        );
      }

      if (picked == null || !mounted) return;

      Uint8List? bytes;
      try {
        bytes = await picked.readAsBytes();
      } catch (e, st) {
        AppLogger.e(
          'Could not read bytes of selected file',
          error: e,
          stackTrace: st,
        );
      }

      _selectedFileNotifier.value = picked;
      _fileBytesNotifier.value = bytes;
      _remoteUrlNotifier.value = null;
      _stateNotifier.value = DocumentUploadState.fileSelected;

      _notifyPicked(picked);
    } catch (e, st) {
      AppLogger.e(
        'Error picking file in AppMediaPickerCard',
        error: e,
        stackTrace: st,
      );
      if (mounted) {
        AppSnackbar.error('Failed to select file: ${e.toString()}');
      }
    }
  }

  Future<void> _onUploadTap() async {
    final file = _selectedFileNotifier.value;
    if (!widget.supportUpload || file == null || _isLoadingNotifier.value) {
      return;
    }
    _isLoadingNotifier.value = true;

    try {
      await widget.onUpload?.call(file);
      if (mounted) {
        _stateNotifier.value = DocumentUploadState.uploaded;
      }
    } catch (e, st) {
      AppLogger.e('Failed to upload file', error: e, stackTrace: st);
      if (mounted) {
        _stateNotifier.value = DocumentUploadState.fileSelected;
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  void _removeFile() {
    if (!widget.enabled || widget.readOnly || _isLoadingNotifier.value) return;
    _selectedFileNotifier.value = null;
    _fileBytesNotifier.value = null;
    _remoteUrlNotifier.value = null;
    _stateNotifier.value = DocumentUploadState.idle;

    _notifyPicked(null);
    widget.onFileRemoved?.call();
  }

  void _openPreviewDialog() {
    final file = _selectedFileNotifier.value;
    final remoteUrl = _remoteUrlNotifier.value;
    if (file == null && (remoteUrl == null || remoteUrl.isEmpty)) return;

    AppFilePreviewSheet.showDialog(
      context: context,
      title: widget.title.isNotEmpty ? widget.title : 'Document Preview',
      file: file,
      fileUrl: file == null ? remoteUrl : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title.isNotEmpty) ...[
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.title,
                    style: context.textTheme.bodyMedium?.semiBold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                ),
                if (widget.isRequired) ...[
                  AppSpacing.xs.w,
                  Text(
                    '*',
                    style: context.textTheme.labelMedium?.bold().colour(
                      context.colors.error,
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.xs.h,
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              return ValueListenableBuilder<DocumentUploadState>(
                valueListenable: _stateNotifier,
                builder: (context, state, _) {
                  if (state == DocumentUploadState.idle) {
                    return _buildDropzone(context, constraints);
                  }
                  return _buildFileCard(context, state, constraints);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Idle Dropzone ──────────────────────────────────────────────────────────
  Widget _buildDropzone(BuildContext context, BoxConstraints constraints) {
    final colors = context.colors;
    final effectiveBorderColor = widget.borderColor ?? colors.borderLight;
    final baseBgColor = widget.fillColor ?? colors.surface;

    if (widget.readOnly) {
      return Container(
        height: widget.height,
        constraints: BoxConstraints(minHeight: widget.height ?? 50),
        width: widget.width ?? double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: baseBgColor,
          borderRadius: AppRadius.mdRadius,
          border: Border.all(color: effectiveBorderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          'No document available',
          style: context.textTheme.bodySmall?.colour(colors.onSurfaceSecondary),
        ),
      );
    }

    final extensionsText = widget.allowedExtensions
        .map((e) => e.toUpperCase())
        .join(', ');

    final effectiveWidth =
        widget.width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity);
    final isCompact =
        effectiveWidth < 280 || (widget.height != null && widget.height! < 125);
    final badgeDimension = isCompact
        ? (AppSpacing.xxl + AppSpacing.md)
        : (AppSpacing.xxxl + AppSpacing.md);

    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      opaque: true,
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) {
        if (widget.enabled && !_isHoveredNotifier.value) {
          _isHoveredNotifier.value = true;
        }
      },
      onExit: (_) {
        if (widget.enabled && _isHoveredNotifier.value) {
          _isHoveredNotifier.value = false;
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickFile,
        child: CustomPaint(
          foregroundPainter: _DottedBorderPainter(
            color: effectiveBorderColor,
            strokeWidth: 1.2,
            dashWidth: 4.0,
            dashSpace: 4.0,
            radius: AppRadius.md,
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: _isHoveredNotifier,
            builder: (context, isHovered, child) {
              final effectiveBgColor = isHovered
                  ? Color.alphaBlend(
                      colors.onSurface.withValues(alpha: 0.05),
                      baseBgColor,
                    )
                  : baseBgColor;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                height: widget.height,
                constraints: BoxConstraints(
                  minHeight: widget.height ?? (isCompact ? 100 : 135),
                ),
                width: widget.width ?? double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppSpacing.sm : AppSpacing.lg,
                  vertical: isCompact ? AppSpacing.sm : (AppSpacing.md + 4),
                ),
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: child,
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Badge
                QuickContainer(
                  w: badgeDimension,
                  h: badgeDimension,
                  radius: isCompact ? AppRadius.sm : (AppRadius.sm + 2),
                  color: (widget.iconColor ?? colors.primary).withValues(
                    alpha: 0.08,
                  ),
                  alignment: Alignment.center,
                  child: widget.icon != null
                      ? IconTheme(
                          data: IconThemeData(
                            color: widget.iconColor ?? colors.primary,
                            size: isCompact
                                ? AppSpacing.lg + 2
                                : AppSpacing.xxl,
                          ),
                          child: widget.icon!,
                        )
                      : widget.svgBuilder != null
                      ? widget.svgBuilder!(
                          isCompact ? AppSpacing.lg + 2 : AppSpacing.xxl,
                        )
                      : Icon(
                          Icons.cloud_upload_outlined,
                          size: isCompact ? AppSpacing.lg + 2 : AppSpacing.xxl,
                          color: widget.iconColor ?? colors.primary,
                        ),
                ),
                (isCompact ? AppSpacing.xs : AppSpacing.sm).h,

                // Action Text Prompt
                Text(
                  widget.actionLabel,
                  textAlign: TextAlign.center,
                  style:
                      (isCompact
                              ? context.textTheme.labelMedium
                              : context.textTheme.bodyMedium)
                          ?.semiBold()
                          .colour(colors.primary),
                ),
                (AppSpacing.xs / 2).h,

                // Helper / Extension hints
                Builder(
                  builder: (context) {
                    final sizeHint =
                        widget.maxSize != null &&
                            widget.maxSize!.trim().isNotEmpty
                        ? ' (max. ${widget.maxSize!.trim().replaceFirst(RegExp(r'^max\.?\s*', caseSensitive: false), '')})'
                        : '';
                    return Text(
                      widget.description ?? '$extensionsText$sizeHint',
                      textAlign: TextAlign.center,
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Selected / Uploaded File Card ──────────────────────────────────────────
  Widget _buildFileCard(
    BuildContext context,
    DocumentUploadState state,
    BoxConstraints constraints,
  ) {
    final colors = context.colors;
    final effectiveWidth =
        widget.width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity);
    final isNarrow = effectiveWidth < 440;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _selectedFileNotifier,
        _fileBytesNotifier,
        _remoteUrlNotifier,
        _isLoadingNotifier,
        _stateNotifier,
      ]),
      builder: (context, _) {
        final currentState = _stateNotifier.value;
        final isUploaded = currentState == DocumentUploadState.uploaded;
        final showUploadAction =
            widget.supportUpload && widget.onUpload != null && !isUploaded;

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionIconButton(
              tooltip: 'Preview',
              icon: Icons.visibility_outlined,
              iconColor: colors.onSurfaceSecondary,
              onPressed: _openPreviewDialog,
            ),
            if (!widget.readOnly) ...[
              AppSpacing.xs.w,
              _actionIconButton(
                tooltip: 'Change file',
                icon: Icons.swap_horiz_rounded,
                iconColor: colors.primary,
                onPressed: _pickFile,
              ),
              AppSpacing.xs.w,
              _actionIconButton(
                tooltip: 'Remove',
                icon: Icons.delete_outline_rounded,
                iconColor: colors.error,
                onPressed: _removeFile,
              ),
              if (showUploadAction) ...[
                AppSpacing.sm.w,
                AppButton(
                  text: 'Upload',
                  size: ButtonSize.small,
                  type: ButtonType.primary,
                  isLoading: _isLoadingNotifier.value,
                  onPressed: _onUploadTap,
                ),
              ],
            ],
          ],
        );

        final fileInfo = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.semiBold().colour(
                colors.onSurface,
              ),
            ),
            (AppSpacing.xs / 2).h,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_formattedFileSize.isNotEmpty) ...[
                  Flexible(
                    child: Text(
                      _formattedFileSize,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelSmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                  ),
                  AppSpacing.xs.w,
                  Text(
                    '•',
                    style: context.textTheme.labelSmall?.colour(
                      colors.onSurfaceSecondary,
                    ),
                  ),
                  AppSpacing.xs.w,
                ],
                if (widget.showStatus && !widget.readOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: (isUploaded || !widget.supportUpload)
                          ? colors.successLight.withValues(alpha: 0.2)
                          : colors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.xsRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (isUploaded || !widget.supportUpload)
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_checked_rounded,
                          size: 11,
                          color: (isUploaded || !widget.supportUpload)
                              ? colors.success
                              : colors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          !widget.supportUpload
                              ? 'Selected'
                              : (isUploaded ? 'Uploaded' : 'Ready'),
                          style: context.textTheme.labelSmall
                              ?.medium()
                              .colour(
                                (isUploaded || !widget.supportUpload)
                                    ? colors.success
                                    : colors.primary,
                              )
                              .decreaseSize(1),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );

        final cardContent = Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            color: widget.fillColor ?? colors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: widget.borderColor ?? colors.borderLight,
              width: 1,
            ),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildThumbnail(context),
                        AppSpacing.sm.w,
                        Expanded(child: fileInfo),
                      ],
                    ),
                    AppSpacing.sm.h,
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: colors.borderLight,
                    ),
                    AppSpacing.xs.h,
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionButtons,
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildThumbnail(context),
                    AppSpacing.md.w,
                    Expanded(child: fileInfo),
                    AppSpacing.md.w,
                    actionButtons,
                  ],
                ),
        );

        if (widget.readOnly) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openPreviewDialog,
              child: cardContent,
            ),
          );
        }

        return cardContent;
      },
    );
  }

  Widget _actionIconButton({
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: AppSpacing.lg + 3, color: iconColor),
      splashRadius: AppSpacing.lg + 2,
      padding: const EdgeInsets.all(AppSpacing.xs),
      constraints: const BoxConstraints(),
    );
  }

  // ── Thumbnail / Badge Preview ──────────────────────────────────────────────
  Widget _buildThumbnail(BuildContext context) {
    const size = 46.0;
    final fileBytes = _fileBytesNotifier.value;
    final file = _selectedFileNotifier.value;
    final remoteUrl = _remoteUrlNotifier.value;

    final hasContent =
        fileBytes != null ||
        file != null ||
        (remoteUrl != null && remoteUrl.isNotEmpty);

    if (_isImage && hasContent) {
      return ClipRRect(
        borderRadius: AppRadius.smRadius,
        child: AppImage.auto(
          key: ValueKey(
            '${_fileName}_${fileBytes?.length ?? file?.path ?? remoteUrl ?? ''}',
          ),
          source: fileBytes ?? file ?? remoteUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          onTap: _openPreviewDialog,
          errorWidget: _buildFileIconBadge(context, size),
        ),
      );
    }

    return _buildFileIconBadge(context, size);
  }

  Widget _buildFileIconBadge(BuildContext context, double size) {
    final colors = context.colors;
    final badgeColor = _isPdf
        ? colors.error
        : (_isVideo ? colors.info : (_isSvg ? colors.warning : colors.primary));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: badgeColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Center(
        child: Icon(
          _isPdf
              ? Icons.picture_as_pdf_rounded
              : (_isVideo
                    ? Icons.video_file_outlined
                    : (_isSvg
                          ? Icons.draw_outlined
                          : Icons.insert_drive_file_outlined)),
          size: AppSpacing.xxl,
          color: badgeColor,
        ),
      ),
    );
  }
}

/// Custom painter for crisp dotted / dashed border around rounded rectangles.
class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  const _DottedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 4.0,
    this.dashSpace = 4.0,
    this.radius = AppRadius.md,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.radius != radius;
  }
}
