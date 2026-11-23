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
        _ZoomableImageViewport(
          source: fileUrl ?? file,
          isSvg: _fileName.isSvg,
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
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open link in browser'),
                      onPressed: () => AppLauncher.launchUrlString(fileUrl!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        AppSpacing.xs.h,
        Text(
          kIsWeb
              ? 'Scroll or double-click to zoom · drag to move'
              : 'Pinch or double tap to zoom',
          style: context.textTheme.labelSmall?.colour(
            context.colors.onSurfaceSecondary,
          ),
        ),
        AppSpacing.md.h,
        if (fileUrl != null && fileUrl!.isNotEmpty)
          AppButton(
            text: 'Open Full Resolution in New Tab',
            leading: const Icon(Icons.open_in_new_rounded, size: 18),
            onPressed: () => AppLauncher.launchUrlString(fileUrl!),
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

/// Fixed-size, clipped viewport that shows an image at a sensible size and
/// lets the user zoom / pan inside it.
///
/// - Raster images are never upscaled beyond their natural size
///   ([BoxFit.scaleDown]), so small images (e.g. icons) stay sharp.
/// - SVGs are vector, so they are fitted to the viewport ([BoxFit.contain]).
/// - The viewport size is fixed, so zooming never changes the dialog layout.
/// - Double tap / double click toggles zoom; a reset button shows when zoomed.
class _ZoomableImageViewport extends StatefulWidget {
  final Object? source;
  final bool isSvg;
  final Widget errorWidget;

  const _ZoomableImageViewport({
    required this.source,
    required this.isSvg,
    required this.errorWidget,
  });

  @override
  State<_ZoomableImageViewport> createState() => _ZoomableImageViewportState();
}

class _ZoomableImageViewportState extends State<_ZoomableImageViewport>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1;
  static const double _maxScale = 5;
  static const double _doubleTapScale = 2.5;
  static const double _maxViewportHeight = 1080;

  final TransformationController _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _matrixTween;
  final ValueNotifier<bool> _isZoomed = ValueNotifier<bool>(false);
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final tween = _matrixTween;
          if (tween != null) _transform.value = tween.value;
        });
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    _animation.dispose();
    _isZoomed.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    _isZoomed.value = _transform.value.getMaxScaleOnAxis() > _minScale + 0.01;
  }

  void _animateTo(Matrix4 target) {
    _matrixTween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurveTween(curve: Curves.easeOutCubic).animate(_animation));
    _animation.forward(from: 0);
  }

  void _resetZoom() => _animateTo(Matrix4.identity());

  void _onDoubleTap() {
    if (_isZoomed.value) {
      _resetZoom();
      return;
    }
    // Zoom in around the tapped point.
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    final dx = -position.dx * (_doubleTapScale - 1);
    final dy = -position.dy * (_doubleTapScale - 1);
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final viewportHeight = 60
        .hPercent(context)
        .clamp(240.0, _maxViewportHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;

        return ClipRRect(
          borderRadius: AppRadius.mdRadius,
          child: QuickContainer(
            w: viewportWidth,
            h: viewportHeight,
            color: colors.borderLight.withValues(alpha: 0.3),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onDoubleTapDown: (details) => _doubleTapDetails = details,
                    onDoubleTap: _onDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transform,
                      minScale: _minScale,
                      maxScale: _maxScale,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: AppImage.auto(
                          // Size comes from the viewport's tight constraints.
                          source: widget.source,
                          fit: widget.isSvg ? BoxFit.contain : BoxFit.scaleDown,
                          errorWidget: widget.errorWidget,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isZoomed,
                    builder: (context, isZoomed, _) {
                      if (!isZoomed) return const SizedBox.shrink();
                      return Tooltip(
                        message: 'Reset zoom',
                        child: Material(
                          color: colors.surface.withValues(alpha: 0.9),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.zoom_out_map_rounded),
                            iconSize: 18,
                            color: colors.onSurface,
                            onPressed: _resetZoom,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
