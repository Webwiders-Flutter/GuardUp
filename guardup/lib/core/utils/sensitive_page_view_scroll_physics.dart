import 'package:flutter/material.dart';

class SensitivePageViewScrollPhysics extends PageScrollPhysics {
  final double velocityThreshold;
  final double distanceThreshold;

  const SensitivePageViewScrollPhysics({
    super.parent,
    this.velocityThreshold = 5.0,
    this.distanceThreshold = 0.1,
  });

  @override
  SensitivePageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SensitivePageViewScrollPhysics(
      parent: buildParent(ancestor),
      velocityThreshold: velocityThreshold,
      distanceThreshold: distanceThreshold,
    );
  }

  // Override the default spring to make the snapping animation faster
  // @override
  // SpringDescription get spring => const SpringDescription(
  //   mass: 40.0, // Reduced mass for quicker acceleration
  //   stiffness: 300.0, // Increased stiffness for faster snapping
  //   damping: 25.0, // Appropriate damping to prevent bouncing
  // );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // If out of range, defer to parent for standard bounce/clamp
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = toleranceFor(position);
    final double page = position.pixels / position.viewportDimension;
    final double fractional = page - page.floorToDouble();

    double targetPage = page.roundToDouble();

    // 1. High sensitivity for fast swipes (velocity threshold)
    if (velocity < -velocityThreshold) {
      targetPage = (page - 0.5).roundToDouble();
    } else if (velocity > velocityThreshold) {
      targetPage = (page + 0.5).roundToDouble();
    } else {
      // 2. High sensitivity for slow drags (distance threshold)
      if (fractional > distanceThreshold && fractional <= 0.5) {
        targetPage = page.floorToDouble() + 1.0;
      } else if (fractional < (1.0 - distanceThreshold) && fractional >= 0.5) {
        targetPage = page.floorToDouble();
      }
    }

    final double target = targetPage * position.viewportDimension;

    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }

    return null;
  }
}
