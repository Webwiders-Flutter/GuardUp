import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_container_shape.dart';

// ── Shared path builder ────────────────────────────────────────────────────

Path _buildBorderPath(
  Size size,
  double strokeWidth,
  AppContainerShape shape,
  BorderRadius? borderRadius,
) {
  final half = strokeWidth / 2;
  final rect = Rect.fromLTWH(
    half,
    half,
    size.width - strokeWidth,
    size.height - strokeWidth,
  );
  switch (shape) {
    case AppContainerShape.circle:
      return Path()..addOval(rect);
    case AppContainerShape.stadium:
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.max(size.width, size.height)),
        ),
      );
    case AppContainerShape.rectangle:
      if (borderRadius != null) {
        return Path()..addRRect(borderRadius.toRRect(rect));
      }
      return Path()..addRect(rect);
  }
}

// ── Dashed border ──────────────────────────────────────────────────────────

/// Paints a dashed border around the container.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.shape,
    this.borderRadius,
    this.dashLength = 8.0,
    this.gapLength = 5.0,
  });

  final Color color;
  final double strokeWidth;
  final AppContainerShape shape;
  final BorderRadius? borderRadius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = _buildBorderPath(size, strokeWidth, shape, borderRadius);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              math.min(distance + len, metric.length),
            ),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.shape != shape ||
      old.borderRadius != borderRadius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ── Dotted border ──────────────────────────────────────────────────────────

/// Paints a dotted border around the container.
///
/// Each dot is a filled shape placed at regular intervals along the border path.
/// - When [dotWidth] == [dotHeight] (or [dotHeight] is null), dots are circles.
/// - When [dotWidth] != [dotHeight], dots are rectangles aligned to the path tangent.
class DottedBorderPainter extends CustomPainter {
  const DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.shape,
    this.borderRadius,
    this.dotWidth = 3.0,
    this.dotHeight,
    this.dotSpacing = 5.0,
  });

  final Color color;

  /// Overall border thickness (inset from the widget edge).
  final double strokeWidth;

  final AppContainerShape shape;
  final BorderRadius? borderRadius;

  /// Width (and diameter when circular) of each dot.
  final double dotWidth;

  /// Height of each dot. When null or equal to [dotWidth], dots are circular.
  final double? dotHeight;

  /// Gap between the trailing edge of one dot and the leading edge of the next.
  final double dotSpacing;

  bool get _isCircular => dotHeight == null || dotHeight == dotWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = _buildBorderPath(size, strokeWidth, shape, borderRadius);
    final dh = dotHeight ?? dotWidth;
    final step = dotWidth + dotSpacing;

    for (final metric in path.computeMetrics()) {
      double distance = dotWidth / 2; // start centred on first dot
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          if (_isCircular) {
            canvas.drawCircle(tangent.position, dotWidth / 2, paint);
          } else {
            canvas.save();
            canvas.translate(tangent.position.dx, tangent.position.dy);
            canvas.rotate(tangent.angle);
            canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: dotWidth, height: dh),
              paint,
            );
            canvas.restore();
          }
        }
        distance += step;
      }
    }
  }

  @override
  bool shouldRepaint(DottedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.shape != shape ||
      old.borderRadius != borderRadius ||
      old.dotWidth != dotWidth ||
      old.dotHeight != dotHeight ||
      old.dotSpacing != dotSpacing;
}
