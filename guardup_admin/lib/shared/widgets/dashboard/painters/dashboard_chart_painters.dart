import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/dashboard_stats_models.dart';

/// Custom painter for rendering interactive Donut / Ring charts with slice gaps,
/// rounded stroke caps, and interactive hover expansion.
class DashboardDonutPainter extends CustomPainter {
  final List<StatMetricItem> items;
  final double total;
  final double animationProgress;
  final int? hoveredIndex;
  final double strokeWidth;
  final Color Function(int index) colorResolver;
  final Color trackColor;

  DashboardDonutPainter({
    required this.items,
    required this.total,
    required this.animationProgress,
    required this.hoveredIndex,
    required this.strokeWidth,
    required this.colorResolver,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        (math.min(size.width, size.height) - strokeWidth - 12) / 2;
    if (maxRadius <= 0) return;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, maxRadius, trackPaint);

    if (items.isEmpty || total <= 0) return;

    // Angle gap between slices
    final hasMultiple = items.where((e) => e.value > 0).length > 1;
    final gapRadians = hasMultiple ? 0.05 : 0.0;
    final totalGap = items.length * gapRadians;
    final availableAngle = (2 * math.pi - totalGap).clamp(0.0, 2 * math.pi);

    var currentAngle = -math.pi / 2; // Start from top 12 o'clock

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.value <= 0) continue;

      final proportion = item.value / total;
      final sweepAngle = proportion * availableAngle * animationProgress;

      final isHovered = hoveredIndex == i;
      final sliceColor = colorResolver(i);

      // Glow effect for hovered slice
      if (isHovered) {
        final glowPaint = Paint()
          ..color = sliceColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 8.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: maxRadius),
          currentAngle,
          sweepAngle,
          false,
          glowPaint,
        );
      }

      final slicePaint = Paint()
        ..color = sliceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? (strokeWidth + 4.0) : strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxRadius),
        currentAngle,
        sweepAngle,
        false,
        slicePaint,
      );

      currentAngle += sweepAngle + (hasMultiple ? gapRadians : 0.0);
    }
  }

  @override
  bool shouldRepaint(covariant DashboardDonutPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.total != total ||
        oldDelegate.items != items;
  }
}

/// Custom painter for rendering solid Pie charts with slice separation and hover effects.
class DashboardPiePainter extends CustomPainter {
  final List<StatMetricItem> items;
  final double total;
  final double animationProgress;
  final int? hoveredIndex;
  final Color Function(int index) colorResolver;
  final Color trackColor;

  DashboardPiePainter({
    required this.items,
    required this.total,
    required this.animationProgress,
    required this.hoveredIndex,
    required this.colorResolver,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (math.min(size.width, size.height) - 16) / 2;
    if (baseRadius <= 0) return;

    if (items.isEmpty || total <= 0) {
      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, baseRadius, trackPaint);
      return;
    }

    final hasMultiple = items.where((e) => e.value > 0).length > 1;
    final gapRadians = hasMultiple ? 0.03 : 0.0;
    final totalGap = items.length * gapRadians;
    final availableAngle = (2 * math.pi - totalGap).clamp(0.0, 2 * math.pi);

    var currentAngle = -math.pi / 2;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.value <= 0) continue;

      final proportion = item.value / total;
      final sweepAngle = proportion * availableAngle * animationProgress;
      final isHovered = hoveredIndex == i;
      final sliceColor = colorResolver(i);

      final sliceRadius = isHovered ? baseRadius + 4 : baseRadius;

      // Glow behind hovered slice
      if (isHovered) {
        final glowPaint = Paint()
          ..color = sliceColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: sliceRadius + 4),
          currentAngle,
          sweepAngle,
          true,
          glowPaint,
        );
      }

      final slicePaint = Paint()
        ..color = sliceColor
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: sliceRadius),
        currentAngle,
        sweepAngle,
        true,
        slicePaint,
      );

      currentAngle += sweepAngle + (hasMultiple ? gapRadians : 0.0);
    }
  }

  @override
  bool shouldRepaint(covariant DashboardPiePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.total != total ||
        oldDelegate.items != items;
  }
}

/// Helper utility for detecting which chart arc/slice contains a local cursor offset.
class ChartArcHitTester {
  ChartArcHitTester._();

  /// Tests hit for a donut / ring chart.
  static int? hitTestDonut({
    required Offset localPosition,
    required Size size,
    required List<StatMetricItem> items,
    required double total,
    required double strokeWidth,
  }) {
    if (items.isEmpty || total <= 0) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final midRadius =
        (math.min(size.width, size.height) - strokeWidth - 12) / 2;
    final innerRadius = midRadius - (strokeWidth / 2) - 6;
    final outerRadius = midRadius + (strokeWidth / 2) + 8;

    if (distance < innerRadius || distance > outerRadius) {
      return null;
    }

    return _findSliceIndexForOffset(dx, dy, items, total);
  }

  /// Tests hit for a solid pie chart.
  static int? hitTestPie({
    required Offset localPosition,
    required Size size,
    required List<StatMetricItem> items,
    required double total,
  }) {
    if (items.isEmpty || total <= 0) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final maxRadius = (math.min(size.width, size.height) - 16) / 2 + 6;
    if (distance > maxRadius) return null;

    return _findSliceIndexForOffset(dx, dy, items, total);
  }

  static int? _findSliceIndexForOffset(
    double dx,
    double dy,
    List<StatMetricItem> items,
    double total,
  ) {
    // Angle in [-pi, pi]
    var angle = math.atan2(dy, dx);
    // Shift top (12 o'clock = -pi/2) to angle 0
    angle += math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    final hasMultiple = items.where((e) => e.value > 0).length > 1;
    final gapRadians = hasMultiple ? 0.05 : 0.0;
    final totalGap = items.length * gapRadians;
    final availableAngle = (2 * math.pi - totalGap).clamp(0.0, 2 * math.pi);

    var currentAngle = 0.0;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.value <= 0) continue;

      final sweepAngle = (item.value / total) * availableAngle;
      final sliceEnd = currentAngle + sweepAngle;

      if (angle >= currentAngle && angle <= sliceEnd) {
        return i;
      }

      currentAngle = sliceEnd + (hasMultiple ? gapRadians : 0.0);
    }

    return null;
  }
}
