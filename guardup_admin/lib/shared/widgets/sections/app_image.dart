import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/extensions/context.extension.dart';
import '../../../core/extensions/file_object.extension.dart';

/// Supported internal image representation types.
enum AppImageType { network, asset, file, memory, xFile, svgAsset, svgNetwork }

/// A unified, production-ready image widget that seamlessly handles
/// Network, Asset, File, Memory, and SVG images with built-in caching,
/// shimmers, error placeholders, and cross-platform web support.
class AppImage extends StatelessWidget {
  final AppImageType type;

  // Image sources
  final String? imageUrl;
  final String? assetPath;
  final io.File? file;
  final XFile? xFile;
  final Uint8List? memoryBytes;

  // Size & Layout
  final double? width;
  final double? height;
  final BoxFit fit;

  // Styling & Decoration
  final BorderRadius? borderRadius;
  final ImageProvider? fallbackImage;
  final Widget? errorWidget;
  final Widget? placeholder;
  final Color? color;
  final Color? backgroundColor;
  final BoxShape shape;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  // Behaviors & Animation
  final bool enableHero;
  final String? heroTag;
  final bool enableShimmer;
  final bool useCache;
  final Duration fadeDuration;
  final VoidCallback? onTap;

  const AppImage({
    super.key,
    required this.type,
    this.imageUrl,
    this.assetPath,
    this.file,
    this.xFile,
    this.memoryBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholder,
    this.color,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = true,
    this.useCache = true,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
  });

  // ---------------------------------------------------------------------------
  // FACTORY CONSTRUCTORS
  // ---------------------------------------------------------------------------

  const AppImage.network({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.placeholder,
    this.color,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = true,
    this.useCache = true,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
  }) : type = AppImageType.network,
       assetPath = null,
       file = null,
       xFile = null,
       memoryBytes = null;

  const AppImage.asset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.color,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.asset,
       imageUrl = null,
       file = null,
       xFile = null,
       memoryBytes = null,
       placeholder = null,
       useCache = false;

  const AppImage.file({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.file,
       imageUrl = null,
       assetPath = null,
       xFile = null,
       memoryBytes = null,
       placeholder = null,
       color = null,
       useCache = false;

  const AppImage.xFile({
    super.key,
    required this.xFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.xFile,
       imageUrl = null,
       assetPath = null,
       file = null,
       memoryBytes = null,
       placeholder = null,
       color = null,
       useCache = false;

  const AppImage.memory({
    super.key,
    required this.memoryBytes,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.memory,
       imageUrl = null,
       assetPath = null,
       file = null,
       xFile = null,
       placeholder = null,
       color = null,
       useCache = false;

  const AppImage.svgAsset({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.color,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.svgAsset,
       imageUrl = null,
       file = null,
       xFile = null,
       memoryBytes = null,
       placeholder = null,
       useCache = false;

  const AppImage.svgNetwork({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.color,
    this.backgroundColor,
    this.enableHero = false,
    this.heroTag,
    this.enableShimmer = false,
    this.useCache = true,
    this.fadeDuration = const Duration(milliseconds: 250),
    this.shape = BoxShape.rectangle,
    this.padding,
    this.margin,
    this.onTap,
    this.fallbackImage,
    this.errorWidget,
  }) : type = AppImageType.svgNetwork,
       assetPath = null,
       file = null,
       xFile = null,
       memoryBytes = null,
       placeholder = null;

  /// Convenience auto constructor that resolves the image type from [source].
  /// Supports String (network URL or asset path), XFile, io.File, or Uint8List bytes.
  factory AppImage.auto({
    Key? key,
    required dynamic source,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? errorWidget,
    Widget? placeholder,
    Color? color,
    Color? backgroundColor,
    bool enableHero = false,
    String? heroTag,
    bool enableShimmer = true,
    bool useCache = true,
    BoxShape shape = BoxShape.rectangle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    ImageProvider? fallbackImage,
  }) {
    if (source == null) {
      return AppImage.asset(
        key: key,
        assetPath: '',
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        errorWidget: errorWidget,
        color: color,
        backgroundColor: backgroundColor,
        enableHero: enableHero,
        heroTag: heroTag,
        enableShimmer: false,
        shape: shape,
        padding: padding,
        margin: margin,
        onTap: onTap,
        fallbackImage: fallbackImage,
      );
    }
    if (source is XFile) {
      return AppImage.xFile(
        key: key,
        xFile: source,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        errorWidget: errorWidget,
        backgroundColor: backgroundColor,
        enableHero: enableHero,
        heroTag: heroTag,
        enableShimmer: enableShimmer,
        shape: shape,
        padding: padding,
        margin: margin,
        onTap: onTap,
        fallbackImage: fallbackImage,
      );
    }
    if (source is Uint8List) {
      return AppImage.memory(
        key: key,
        memoryBytes: source,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        errorWidget: errorWidget,
        backgroundColor: backgroundColor,
        enableHero: enableHero,
        heroTag: heroTag,
        enableShimmer: enableShimmer,
        shape: shape,
        padding: padding,
        margin: margin,
        onTap: onTap,
        fallbackImage: fallbackImage,
      );
    }
    if (source is io.File) {
      return AppImage.file(
        key: key,
        file: source,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        errorWidget: errorWidget,
        backgroundColor: backgroundColor,
        enableHero: enableHero,
        heroTag: heroTag,
        enableShimmer: enableShimmer,
        shape: shape,
        padding: padding,
        margin: margin,
        onTap: onTap,
        fallbackImage: fallbackImage,
      );
    }
    final str = source?.toString() ?? '';
    final isNetwork = str.startsWith('http://') || str.startsWith('https://');
    if (isNetwork) {
      return AppImage.network(
        key: key,
        imageUrl: str,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        errorWidget: errorWidget,
        placeholder: placeholder,
        color: color,
        backgroundColor: backgroundColor,
        enableHero: enableHero,
        heroTag: heroTag,
        enableShimmer: enableShimmer,
        useCache: useCache,
        shape: shape,
        padding: padding,
        margin: margin,
        onTap: onTap,
        fallbackImage: fallbackImage,
      );
    }
    return AppImage.asset(
      key: key,
      assetPath: str,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      errorWidget: errorWidget,
      color: color,
      backgroundColor: backgroundColor,
      enableHero: enableHero,
      heroTag: heroTag,
      enableShimmer: enableShimmer,
      shape: shape,
      padding: padding,
      margin: margin,
      onTap: onTap,
      fallbackImage: fallbackImage,
    );
  }

  // ---------------------------------------------------------------------------
  // URL RESOLUTION & SVG COLOR
  // ---------------------------------------------------------------------------

  String? get _resolvedImageUrl {
    if (imageUrl == null || imageUrl!.trim().isEmpty) return imageUrl;
    return useCache ? imageUrl : imageUrl!.burstUrl;
  }

  ColorFilter? get _svgColorFilter =>
      color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null;

  // ---------------------------------------------------------------------------
  // BUILD METHOD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget child = _buildCoreImage(context);

    // Decorate Container
    child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        shape: shape,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    // Hero Transition
    if (enableHero && heroTag != null) {
      child = Hero(tag: heroTag!, child: child);
    }

    // Tap Interaction
    if (onTap != null) {
      child = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: child,
        ),
      );
    }

    return child;
  }

  // ---------------------------------------------------------------------------
  // CORE IMAGE BUILDER (Unified dispatch without code duplication)
  // ---------------------------------------------------------------------------

  Widget _buildCoreImage(BuildContext context) {
    final effectivePlaceholder =
        placeholder ??
        _ShimmerPlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
          enabled: enableShimmer,
        );

    switch (type) {
      case AppImageType.network:
      case AppImageType.svgNetwork:
        final url = _resolvedImageUrl;
        if (url == null || url.trim().isEmpty) {
          return _buildError(context);
        }
        if (type == AppImageType.svgNetwork || url.isSvg) {
          return SvgPicture.network(
            url,
            width: width,
            height: height,
            fit: fit,
            colorFilter: _svgColorFilter,
            placeholderBuilder: (_) => effectivePlaceholder,
            errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
          );
        }
        if (kIsWeb) {
          return Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            color: color,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return effectivePlaceholder;
            },
            errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
          );
        }
        return CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          color: color,
          fadeInDuration: fadeDuration,
          placeholder: (_, _) => effectivePlaceholder,
          errorWidget: (ctx, _, err) => _buildError(ctx, err, null),
        );

      case AppImageType.asset:
      case AppImageType.svgAsset:
        final path = assetPath ?? '';
        if (path.isEmpty) return _buildError(context);
        if (type == AppImageType.svgAsset || path.isSvg) {
          return SvgPicture.asset(
            path,
            width: width,
            height: height,
            fit: fit,
            colorFilter: _svgColorFilter,
            placeholderBuilder: (_) => effectivePlaceholder,
            errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
          );
        }
        return Image.asset(
          path,
          width: width,
          height: height,
          fit: fit,
          color: color,
          errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
        );

      case AppImageType.file:
        if (file == null) return _buildError(context);
        if (file!.isSvg) {
          try {
            return SvgPicture.memory(
              file!.readAsBytesSync(),
              width: width,
              height: height,
              fit: fit,
              colorFilter: _svgColorFilter,
              placeholderBuilder: (_) => effectivePlaceholder,
            );
          } catch (e, stack) {
            return _buildError(context, e, stack);
          }
        }
        return Image.file(
          file!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
        );

      case AppImageType.xFile:
        if (xFile == null) return _buildError(context);
        return FutureBuilder<Uint8List>(
          future: xFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return effectivePlaceholder;
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError(context, snapshot.error, snapshot.stackTrace);
            }
            final bytes = snapshot.data!;
            if (xFile!.isSvg || bytes.isSvg) {
              return SvgPicture.memory(
                bytes,
                width: width,
                height: height,
                fit: fit,
                colorFilter: _svgColorFilter,
                placeholderBuilder: (_) => effectivePlaceholder,
              );
            }
            return Image.memory(
              bytes,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
            );
          },
        );

      case AppImageType.memory:
        if (memoryBytes == null || memoryBytes!.isEmpty) {
          return _buildError(context);
        }
        if (memoryBytes!.isSvg) {
          return SvgPicture.memory(
            memoryBytes!,
            width: width,
            height: height,
            fit: fit,
            colorFilter: _svgColorFilter,
            placeholderBuilder: (_) => effectivePlaceholder,
          );
        }
        return Image.memory(
          memoryBytes!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildError(ctx, err, stack),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR BUILDER
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, [Object? error, StackTrace? stack]) {
    if (fallbackImage != null) {
      return Image(
        image: fallbackImage!,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return errorWidget ??
        QuickContainer(
          w: width,
          h: height,
          alignment: Alignment.center,
          color: context.colors.borderLight.withValues(alpha: 0.3),
          child: Icon(
            Icons.broken_image_outlined,
            color: context.colors.onSurfaceSecondary,
            size: (width != null && width! < 32) ? 16 : 22,
          ),
        );
  }
}

// =============================================================================
// SHIMMER PLACEHOLDER
// =============================================================================

class _ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool enabled;

  const _ShimmerPlaceholder({
    this.width,
    this.height,
    this.borderRadius,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderBox = QuickContainer(
      w: width,
      h: height,
      color: context.colors.borderLight.withValues(alpha: 0.6),
      radius: AppRadius.sm,
      borderRadius: borderRadius,
    );

    if (!enabled) return placeholderBox;

    return Shimmer.fromColors(
      baseColor: context.colors.borderLight.withValues(alpha: 0.6),
      highlightColor: context.colors.surface,
      child: placeholderBox,
    );
  }
}
