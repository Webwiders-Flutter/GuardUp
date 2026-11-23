import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/file_object.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '../../sections/app_image.dart';

/// Full-screen viewer for images and documents.
///
/// - Images open on a dark backdrop and can be zoomed / panned
///   (scroll, pinch, double-click, toolbar buttons or `+` / `-` / `0` keys).
/// - Raster images are never upscaled beyond their natural size, so small
///   images such as icons stay sharp. SVGs are fitted to the screen.
/// - Documents (PDF etc.) show a card with an "Open document" action.
/// - Close with the ✕ button or `Esc`.
///
/// ```dart
/// AppFileViewer.show(context: context, title: 'Icon', fileUrl: url);
/// ```
class AppFileViewer extends StatefulWidget {
  final XFile? file;
  final String? fileUrl;
  final String title;

  const AppFileViewer({super.key, this.file, this.fileUrl, required this.title})
    : assert(
        (file != null) ^ (fileUrl != null),
        'Either file or fileUrl must be provided, and only one can be provided at a time.',
      );

  /// Opens the viewer full screen on top of everything (root navigator).
  static Future<void> show({
    required BuildContext context,
    required String title,
    XFile? file,
    String? fileUrl,
  }) {
    return showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          AppFileViewer(title: title, file: file, fileUrl: fileUrl),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  State<AppFileViewer> createState() => _AppFileViewerState();
}

class _AppFileViewerState extends State<AppFileViewer>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1;
  static const double _maxScale = 6;
  static const double _zoomStep = 1.5;
  static const double _doubleTapScale = 2.5;

  static const Color _foreground = Colors.white;
  static final Color _foregroundMuted = Colors.white.withValues(alpha: 0.7);
  static final Color _controlFill = Colors.white.withValues(alpha: 0.1);

  final TransformationController _transform = TransformationController();
  late final AnimationController _animation;
  Animation<Matrix4>? _matrixTween;
  final ValueNotifier<double> _scale = ValueNotifier<double>(1);
  final FocusNode _focusNode = FocusNode();

  Size _viewportSize = Size.zero;
  TapDownDetails? _doubleTapDetails;

  String get _fileName => widget.file?.fileName.isNotEmpty == true
      ? widget.file!.fileName
      : widget.fileUrl?.fileName ?? '';

  bool get _isImage =>
      widget.file.isImage || widget.fileUrl.isImage || _fileName.isImage;

  bool get _isSvg => _fileName.isSvg;

  bool get _hasUrl => widget.fileUrl != null && widget.fileUrl!.isNotEmpty;

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
    _scale.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ZOOM
  // ---------------------------------------------------------------------------

  void _onTransformChanged() {
    _scale.value = _transform.value.getMaxScaleOnAxis();
  }

  void _animateTo(Matrix4 target) {
    _matrixTween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurveTween(curve: Curves.easeOutCubic).animate(_animation));
    _animation.forward(from: 0);
  }

  /// Zooms to [targetScale], keeping [focalPoint] (viewport coordinates)
  /// fixed on screen.
  void _zoomTo(double targetScale, Offset focalPoint) {
    final current = _transform.value;
    final currentScale = current.getMaxScaleOnAxis();
    final scale = targetScale.clamp(_minScale, _maxScale);
    if (scale <= _minScale) {
      _animateTo(Matrix4.identity());
      return;
    }

    // Point in child coordinates currently under the focal point.
    final translation = current.getTranslation();
    final childPoint = Offset(
      (focalPoint.dx - translation.x) / currentScale,
      (focalPoint.dy - translation.y) / currentScale,
    );

    // Keep that point under the focal point, then clamp so no gap shows.
    final size = _viewportSize;
    final dx = (focalPoint.dx - childPoint.dx * scale).clamp(
      size.width - size.width * scale,
      0.0,
    );
    final dy = (focalPoint.dy - childPoint.dy * scale).clamp(
      size.height - size.height * scale,
      0.0,
    );

    _animateTo(
      Matrix4.identity()
        ..translateByDouble(dx, dy, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1),
    );
  }

  Offset get _viewportCenter =>
      Offset(_viewportSize.width / 2, _viewportSize.height / 2);

  void _zoomIn() => _zoomTo(_scale.value * _zoomStep, _viewportCenter);
  void _zoomOut() => _zoomTo(_scale.value / _zoomStep, _viewportCenter);
  void _resetZoom() => _animateTo(Matrix4.identity());

  void _onDoubleTap() {
    if (_scale.value > _minScale + 0.01) {
      _resetZoom();
    } else {
      _zoomTo(
        _doubleTapScale,
        _doubleTapDetails?.localPosition ?? _viewportCenter,
      );
    }
  }

  void _close() => Navigator.of(context).maybePop();

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        if (_isImage) ...{
          const SingleActivator(LogicalKeyboardKey.equal): _zoomIn,
          const SingleActivator(LogicalKeyboardKey.add): _zoomIn,
          const SingleActivator(LogicalKeyboardKey.numpadAdd): _zoomIn,
          const SingleActivator(LogicalKeyboardKey.minus): _zoomOut,
          const SingleActivator(LogicalKeyboardKey.numpadSubtract): _zoomOut,
          const SingleActivator(LogicalKeyboardKey.digit0): _resetZoom,
          const SingleActivator(LogicalKeyboardKey.numpad0): _resetZoom,
        },
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: _isImage
                      ? _buildImageArea(context)
                      : _buildDocumentArea(context),
                ),
                if (_isImage) _buildBottomHint(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final textTheme = context.textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.semiBold().colour(_foreground),
                ),
                if (_fileName.isNotEmpty && _fileName != widget.title)
                  Text(
                    _fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.colour(_foregroundMuted),
                  ),
              ],
            ),
          ),
          if (_isImage) ...[
            _ToolbarButton(
              icon: Icons.zoom_out_rounded,
              tooltip: 'Zoom out (−)',
              onPressed: _zoomOut,
            ),
            ValueListenableBuilder<double>(
              valueListenable: _scale,
              builder: (context, scale, _) => SizedBox(
                width: AppSpacing.xxxl + AppSpacing.md,
                child: Text(
                  '${(scale * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.medium().colour(
                    _foregroundMuted,
                  ),
                ),
              ),
            ),
            _ToolbarButton(
              icon: Icons.zoom_in_rounded,
              tooltip: 'Zoom in (+)',
              onPressed: _zoomIn,
            ),
            AppSpacing.xs.w,
            _ToolbarButton(
              icon: Icons.fit_screen_rounded,
              tooltip: 'Fit to screen (0)',
              onPressed: _resetZoom,
            ),
          ],
          if (_hasUrl) ...[
            AppSpacing.xs.w,
            _ToolbarButton(
              icon: Icons.open_in_new_rounded,
              tooltip: 'Open in new tab',
              onPressed: () => AppLauncher.launchUrlString(widget.fileUrl!),
            ),
          ],
          AppSpacing.md.w,
          _ToolbarButton(
            icon: Icons.close_rounded,
            tooltip: 'Close (Esc)',
            filled: true,
            onPressed: _close,
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportSize = constraints.biggest;

        return GestureDetector(
          onDoubleTapDown: (details) => _doubleTapDetails = details,
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transform,
            minScale: _minScale,
            maxScale: _maxScale,
            child: SizedBox.fromSize(
              size: _viewportSize,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: AppImage.auto(
                  source: widget.fileUrl ?? widget.file,
                  // Raster: natural size at most (sharp). SVG: fill screen.
                  fit: _isSvg ? BoxFit.contain : BoxFit.scaleDown,
                  enableShimmer: false,
                  placeholder: const Center(
                    child: CircularProgressIndicator(color: _foreground),
                  ),
                  errorWidget: _buildError(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        kIsWeb
            ? 'Scroll or double-click to zoom · Drag to move · Esc to close'
            : 'Pinch or double tap to zoom · Drag to move',
        textAlign: TextAlign.center,
        style: context.textTheme.labelSmall?.colour(_foregroundMuted),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 56, color: _foregroundMuted),
          AppSpacing.md.h,
          Text(
            'Failed to load image preview',
            style: context.textTheme.bodyMedium?.colour(_foreground),
          ),
          if (_hasUrl) ...[
            AppSpacing.sm.h,
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: _foreground),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open link in browser'),
              onPressed: () => AppLauncher.launchUrlString(widget.fileUrl!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentArea(BuildContext context) {
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: _controlFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.fileUrl.isPdf || widget.file.isPdf
                    ? Icons.picture_as_pdf_rounded
                    : Icons.insert_drive_file_rounded,
                size: AppSpacing.xxxl + AppSpacing.lg,
                color: _foreground,
              ),
            ),
            AppSpacing.lg.h,
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                _fileName.isNotEmpty ? _fileName : widget.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.semiBold().colour(_foreground),
              ),
            ),
            if (widget.file != null)
              FutureBuilder<String>(
                future: widget.file!.getFormattedSize(),
                initialData: widget.file!.formattedSize,
                builder: (context, snapshot) {
                  final size = snapshot.data ?? '';
                  if (size.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      size,
                      style: textTheme.bodySmall?.colour(_foregroundMuted),
                    ),
                  );
                },
              ),
            AppSpacing.xl.h,
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _foreground,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open document'),
              onPressed: () {
                if (widget.file != null) {
                  AppLauncher.launchFile(widget.file!.path);
                } else if (_hasUrl) {
                  AppLauncher.launchUrlString(widget.fileUrl!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Round icon button used in the viewer's top bar.
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: filled
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
        hoverColor: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}
