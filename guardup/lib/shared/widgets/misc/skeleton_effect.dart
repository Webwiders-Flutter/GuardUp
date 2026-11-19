import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '/app/theme/colors/app_colors.dart';
import '/core/constants/app_durations.dart';
import '/core/extensions/context.extension.dart';

/// Centralized factory providing standardized [PaintingEffect] presets for [Skeletonizer]
/// aligned with [AppColors] design tokens.
///
/// Example:
/// ```dart
/// Skeletonizer(
///   effect: SkeletonEffect.shimmer(
///     duration: const Duration(milliseconds: 800),
///   ),
///   child: ...,
/// )
/// ```
abstract final class SkeletonEffect {
  SkeletonEffect._();

  /// Standard shimmer effect using [AppColors.surfaceContainer] and [AppColors.surfaceContainerHigh].
  static PaintingEffect shimmer({
    Color? baseColor,
    Color? highlightColor,
    AlignmentGeometry begin = const AlignmentDirectional(-1.0, -0.3),
    AlignmentGeometry end = const AlignmentDirectional(1.0, 0.3),
    Duration duration = AppDurations.slower,
  }) {
    return ShimmerEffect(
      baseColor: baseColor ?? AppColors.surfaceContainer,
      highlightColor: highlightColor ?? AppColors.surfaceContainerHigh,
      begin: begin,
      end: end,
      duration: duration,
    );
  }

  /// Theme-aware shimmer resolving dynamically from [context.colors].
  static PaintingEffect adaptiveShimmer(
    BuildContext context, {
    Color? baseColor,
    Color? highlightColor,
    AlignmentGeometry begin = const AlignmentDirectional(-1.0, -0.3),
    AlignmentGeometry end = const AlignmentDirectional(1.0, 0.3),
    Duration duration = AppDurations.slower,
  }) {
    final colors = context.colors;

    return ShimmerEffect(
      baseColor: baseColor ?? colors.surfaceContainer,
      highlightColor: highlightColor ?? colors.surfaceContainerHigh,
      begin: begin,
      end: end,
      duration: duration,
    );
  }

  /// Smooth breathing pulse effect lerping between [from] and [to] surfaces.
  static PaintingEffect pulse({
    Color from = AppColors.surfaceContainer,
    Color to = AppColors.surfaceContainerHigh,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return PulseEffect(
      from: from,
      to: to,
      duration: duration,
    );
  }

  /// Static solid container effect with zero animation overhead.
  static PaintingEffect solid({
    Color color = AppColors.surfaceContainer,
  }) {
    return SolidColorEffect(
      color: color,
    );
  }
}
