import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/file_object.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/string.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_dialog.dart';
import '/shared/widgets/feedbacks/widgets/app_sheet.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/app_image.dart';

import 'package:url_launcher/url_launcher.dart';

/// Interactive document preview sheet for images and PDF/document files.
///
/// Images can be previewed in bottom sheet/dialog and expanded into full-screen via [openInViewer].
/// Document files (PDF, Word, Excel, etc.) open externally only.
class AppFilePreviewSheet extends StatelessWidget {
  final XFile? file;
  final String? fileUrl;
  final Uint8List? bytes;
  final String title;

  const AppFilePreviewSheet({
    super.key,
    this.file,
    this.fileUrl,
    this.bytes,
    required this.title,
  }) : assert(
         (file != null) || (fileUrl != null) || (bytes != null),
         'Either file, fileUrl, or bytes must be provided.',
       );

  // ---------------------------------------------------------------------------
  // Presentation Openers
  // ---------------------------------------------------------------------------

  /// Displays the [AppFilePreviewSheet] in a bottom sheet using [AppSheet].
  static Future<void> show({
    required BuildContext context,
    required String title,
    XFile? file,
    String? fileUrl,
    Uint8List? bytes,
  }) {
    return AppSheet.show<void>(
      context: context,
      title: title,
      action: AppSheetHeaderAction.close,
      child: AppFilePreviewSheet(
        file: file,
        fileUrl: fileUrl,
        bytes: bytes,
        title: title,
      ),
    );
  }

  /// Displays the [AppFilePreviewSheet] in a modal dialog using [AppDialogs].
  static Future<void> showDialog({
    required BuildContext context,
    required String title,
    XFile? file,
    String? fileUrl,
    Uint8List? bytes,
    bool barrierDismissible = true,
  }) {
    return AppDialogs.show(
      context: context,
      title: title,
      barrierDismissible: barrierDismissible,
      child: AppFilePreviewSheet(
        file: file,
        fileUrl: fileUrl,
        bytes: bytes,
        title: title,
      ),
    );
  }

  /// Opens an image in full screen in the private [_ViewerScreen].
  /// If the target is a document, opens it externally via [AppLauncher].
  static Future<T?> openInViewer<T>(
    BuildContext context, {
    required String title,
    XFile? file,
    String? fileUrl,
    Uint8List? bytes,
  }) {
    final isImg =
        bytes.isSvg || file.isImage || fileUrl.isImage || title.isImage;

    // Documents do not open in the in-app viewer; they open externally only.
    if (!isImg) {
      if (file != null) {
        if (file.path.isUrl) {
          AppLauncher.launchUrlString(file.path);
        } else {
          AppLauncher.launchFile(file.path);
        }
      } else if (fileUrl != null) {
        AppLauncher.launchUrlString(fileUrl);
      } else {
        AppSnackbar.info('No document path available');
      }
      return Future.value(null);
    }

    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => _ViewerScreen(
          title: title,
          file: file,
          fileUrl: fileUrl,
          bytes: bytes,
        ),
      ),
    );
  }

  /// Convenience lowercase alias matching [openInViewer].
  static Future<T?> openInviewer<T>(
    BuildContext context, {
    required String title,
    XFile? file,
    String? fileUrl,
    Uint8List? bytes,
  }) => openInViewer<T>(
    context,
    title: title,
    file: file,
    fileUrl: fileUrl,
    bytes: bytes,
  );

  /// Backward-compatible alias for [openInViewer].
  static Future<T?> openViewer<T>(
    BuildContext context, {
    required String title,
    XFile? file,
    String? fileUrl,
    Uint8List? bytes,
  }) => openInViewer<T>(
    context,
    title: title,
    file: file,
    fileUrl: fileUrl,
    bytes: bytes,
  );

  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------

  bool get _isImage =>
      bytes.isSvg || file.isImage || fileUrl.isImage || _fileName.isImage;

  bool get _isPdf => file.isPdf || fileUrl.isPdf || _fileName.isPdf;

  String get _fileName {
    if (file?.fileName.isNotEmpty == true) return file!.fileName;
    if (fileUrl?.fileName.isNotEmpty == true) return fileUrl!.fileName;
    return title;
  }

  IconData get _documentIcon {
    final clean = _fileName.toLowerCase().split('?').first.split('#').first;
    if (_isPdf || clean.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (clean.endsWith('.doc') ||
        clean.endsWith('.docx') ||
        clean.endsWith('.odt') ||
        clean.endsWith('.odf') ||
        clean.endsWith('.rtf') ||
        clean.endsWith('.txt')) {
      return Icons.description_rounded;
    }
    if (clean.endsWith('.xls') ||
        clean.endsWith('.xlsx') ||
        clean.endsWith('.ods') ||
        clean.endsWith('.csv')) {
      return Icons.table_chart_rounded;
    }
    if (clean.endsWith('.ppt') ||
        clean.endsWith('.pptx') ||
        clean.endsWith('.odp')) {
      return Icons.slideshow_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _documentColor(BuildContext context) {
    final clean = _fileName.toLowerCase().split('?').first.split('#').first;
    if (_isPdf || clean.endsWith('.pdf')) return context.colors.error;
    if (clean.endsWith('.doc') ||
        clean.endsWith('.docx') ||
        clean.endsWith('.odt') ||
        clean.endsWith('.odf')) {
      return Colors.blue;
    }
    if (clean.endsWith('.xls') ||
        clean.endsWith('.xlsx') ||
        clean.endsWith('.ods') ||
        clean.endsWith('.csv')) {
      return Colors.green;
    }
    if (clean.endsWith('.ppt') || clean.endsWith('.pptx')) {
      return Colors.orange;
    }
    return context.colors.primary;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.horizontalEdgeInsets,
      child: Column(
        mainAxisSize: .min,
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
        GestureDetector(
          onTap: () => _openInViewer(context),
          child: ClipRRect(
            borderRadius: AppRadius.md.toBorderRadius,
            child: QuickContainer(
              color: context.colors.borderLight.withValues(alpha: 0.3),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: AppImage.auto(
                  source: bytes ?? fileUrl ?? file,
                  fit: BoxFit.contain,
                  height: 60.hPercent(context),
                  errorWidget: Center(
                    child: Text(
                      'Failed to load image preview',
                      style: context.textTheme.bodySmall?.colour(
                        context.colors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!kIsWeb) ...[
          AppSpacing.xs.h,
          Text(
            'Pinch or double tap to zoom • Tap to open full screen',
            style: context.textTheme.labelSmall?.colour(
              context.colors.onSurfaceSecondary,
            ),
          ),
        ],
        AppSpacing.md.h,
        AppButton(
          text: 'View Full Screen',
          leading: const Icon(Icons.fullscreen_rounded),
          onPressed: () => _openInViewer(context),
        ),
      ],
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final docColor = _documentColor(context);
    final docIcon = _documentIcon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSpacing.md.h,
        InkWell(
          onTap: () => _openExternally(context),
          borderRadius: AppRadius.full.toBorderRadius,
          child: QuickContainer(
            p: AppSpacing.xl,
            color: docColor.withValues(alpha: 0.12),
            shape: QuickContainerShape.circle,
            child: Icon(docIcon, size: AppSizes.iconGiant, color: docColor),
          ),
        ),
        AppSpacing.md.h,
        InkWell(
          onTap: () => _openExternally(context),
          borderRadius: AppRadius.sm.toBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              _fileName.isNotEmpty ? _fileName : title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.semiBold().colour(
                context.colors.onSurface,
              ),
            ),
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
          onPressed: () => _openExternally(context),
        ),
      ],
    );
  }

  void _openInViewer(BuildContext context) {
    final nav = Navigator.of(context);
    nav.pop();
    openInViewer(
      nav.context,
      title: title.isNotEmpty ? title : _fileName,
      file: file,
      fileUrl: fileUrl,
      bytes: bytes,
    );
  }

  void _openExternally(BuildContext context) {
    if (file != null) {
      if (file!.path.isUrl) {
        AppLauncher.launchUrlString(file!.path);
      } else {
        AppLauncher.launchFile(file!.path);
      }
    } else if (fileUrl != null) {
      AppLauncher.launchUrlString(fileUrl!);
    } else {
      AppSnackbar.info('No document path available');
    }
  }
}
// =============================================================================
// Private Full-Screen Viewer Screen
// =============================================================================

class _ViewerScreen extends StatefulWidget {
  final String title;
  final XFile? file;
  final String? fileUrl;
  final Uint8List? bytes;

  const _ViewerScreen({
    required this.title,
    this.file,
    this.fileUrl,
    this.bytes,
  });

  @override
  State<_ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<_ViewerScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformController;
  late final AnimationController _animController;
  Animation<Matrix4>? _resetAnimation;
  bool _isZoomed = false;

  String? get _targetPath =>
      widget.fileUrl ??
      (widget.file?.path.isUrl == true ? widget.file!.path : widget.file?.path);

  dynamic get _imageSource =>
      widget.bytes ?? _targetPath ?? widget.file ?? widget.fileUrl;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(_onTransformationChanged);

    _animController =
        AnimationController(vsync: this, duration: AppDurations.fast)
          ..addListener(() {
            if (_resetAnimation != null) {
              _transformController.value = _resetAnimation!.value;
            }
          });
  }

  void _onTransformationChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final targetMatrix = currentScale > 1.5
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(2.5, 2.5, 1.0);

    _resetAnimation =
        Matrix4Tween(
          begin: _transformController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    _animController.forward(from: 0);
  }

  void _resetZoom() {
    _resetAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0);
  }

  Future<void> _openExternally(BuildContext context) async {
    final target = _targetPath;
    if (target != null && target.isNotEmpty) {
      if (target.isUrl) {
        await AppLauncher.launchUrlString(
          target,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await AppLauncher.launchFile(
          target,
          mode: LaunchMode.externalApplication,
        );
      }
    } else {
      AppSnackbar.info('No image path available to open');
    }
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.backgroundLight,
      appBar: AppAppBar.primary(
        title: widget.title,
        showBackIcon: true,
        actions: [
          if (_targetPath != null && _targetPath!.isNotEmpty) ...[
            IconButton(
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: AppSizes.iconMd,
              ),
              tooltip: 'Open Externally',
              onPressed: () => _openExternally(context),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformController,
                  minScale: 0.8,
                  maxScale: 5.0,
                  clipBehavior: Clip.hardEdge,
                  child: Center(
                    child: AppImage.auto(
                      source: _imageSource,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: AppSizes.iconHuge,
                              color: context.colors.error,
                            ),
                            AppSpacing.md.h,
                            Text(
                              'Failed to load image',
                              style: context.textTheme.bodyMedium?.colour(
                                context.colors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Floating pinch/zoom indicator
              Positioned(
                bottom: AppSpacing.md,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: AppDurations.fast,
                    opacity: _isZoomed ? 0.9 : 0.75,
                    child: QuickContainer(
                      px: AppSpacing.md,
                      py: AppSpacing.xs,
                      radius: AppRadius.full,
                      color: context.colors.black.withValues(alpha: 0.75),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isZoomed ? Icons.zoom_out : Icons.zoom_in,
                            color: Colors.white,
                            size: AppSizes.iconSm,
                          ),
                          AppSpacing.xs.w,
                          Text(
                            _isZoomed
                                ? 'Double-tap to reset'
                                : 'Pinch or double-tap to zoom',
                            style: context.textTheme.labelSmall
                                ?.semiBold()
                                .colour(Colors.white),
                          ),
                          if (_isZoomed) ...[
                            AppSpacing.xs.w,
                            GestureDetector(
                              onTap: _resetZoom,
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: AppSizes.iconSm,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
