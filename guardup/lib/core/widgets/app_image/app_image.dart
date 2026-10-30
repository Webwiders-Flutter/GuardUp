import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guardup/core/widgets/common/custom_loader.dart';

import '../../app_types/image_types.dart';

class AppImage extends StatelessWidget {
  /// Image URL for network or asset
  final String imageUrl;

  /// File image for mobile/local storage
  final File? imageFile;

  /// Memory image for web or bytes
  final Uint8List? imageBytes;

  /// File type
  final AppImageTypes appFileType;

  /// Height
  final double? height;

  /// Width
  final double? width;

  /// Image fit
  final BoxFit fit;

  /// Border radius
  final double borderRadius;

  /// Border
  final Border? border;

  /// Background color
  final Color? backgroundColor;

  /// Loader visible
  final bool showLoader;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Margin
  final EdgeInsetsGeometry? margin;

  /// Alignment
  final AlignmentGeometry? alignment;

  /// Box shape
  final BoxShape shape;

  /// Ink effect
  final VoidCallback? onTap;

  /// Error widget
  final Widget? errorWidget;

  /// Placeholder widget
  final Widget? placeholderWidget;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.appFileType = AppImageTypes.network,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.border,
    this.backgroundColor,
    this.showLoader = false,
    this.padding,
    this.margin,
    this.alignment,
    this.shape = BoxShape.rectangle,
    this.onTap,
    this.errorWidget,
    this.placeholderWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        padding: padding,
        alignment: alignment,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: shape,
          border: border,
          borderRadius: shape == BoxShape.circle
              ? null
              : BorderRadius.circular(borderRadius),
        ),
        child: ClipRRect(
          borderRadius: shape == BoxShape.circle
              ? BorderRadius.zero
              : BorderRadius.circular(borderRadius),

          child: _buildImage(context),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    switch (appFileType) {
      case AppImageTypes.asset:
        if (imageUrl.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
          );
        }
        return Image.asset(
          imageUrl,
          fit: fit,
          errorBuilder: (_, _, _) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );

      case AppImageTypes.file:
        if (imageFile == null) {
          return errorWidget ?? _defaultErrorWidget();
        }

        return Image.file(
          imageFile!,
          fit: fit,
          errorBuilder: (_, _, _) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );

      case AppImageTypes.memory:
        if (imageBytes == null) {
          return errorWidget ?? _defaultErrorWidget();
        }

        return Image.memory(
          imageBytes!,
          fit: fit,
          errorBuilder: (_, _, _) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );

      case AppImageTypes.network:
        if (imageUrl.toLowerCase().endsWith('.svg') ||
            imageUrl.toLowerCase().contains('.svg?')) {
          return SvgPicture.network(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
            placeholderBuilder: (BuildContext context) =>
                placeholderWidget ??
                (showLoader ? const CustomLoader() : const SizedBox()),
          );
        }

        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) {
            if (placeholderWidget != null) {
              return placeholderWidget!;
            }

            return showLoader ? const CustomLoader() : const SizedBox();
          },
          errorWidget: (context, url, error) {
            return errorWidget ?? _defaultErrorWidget();
          },
        );
    }
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }
}
