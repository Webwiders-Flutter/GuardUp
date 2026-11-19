import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/extensions/context.extension.dart';
import 'package:guardup/core/extensions/spacing.extension.dart';
import 'package:guardup/core/extensions/textstyle_extension.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/app/theme/colors/color_accessor.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/shared/widgets/buttons/app_button.dart';

/// 404 Not Found screen displayed when a requested route doesn't exist.
class NotFoundScreen extends StatefulWidget {
  static const route = '/not-found';

  const NotFoundScreen({super.key});

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen>
    with TickerProviderStateMixin {
  /// Keeps the layout readable on tablets / web.
  static const double _contentMaxWidth = 520;
  static const double _bodyMaxWidth = 360;

  late final AnimationController _floatController;
  late final AnimationController _roadController;
  late final AnimationController _entranceController;

  late final Animation<double> _floatAnimation;

  // Staggered entrance animations
  late final Animation<double> _illustrationIn;
  late final Animation<double> _badgeIn;
  late final Animation<double> _titleIn;
  late final Animation<double> _bodyIn;
  late final Animation<double> _actionsIn;

  double get _illustrationWidth => (AppSpacing.xxxl * 8) + AppSpacing.xs;
  double get _illustrationHeight =>
      (AppSpacing.xxxl * 6) + AppSpacing.xxl + AppSpacing.xs;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatAnimation = Tween<double>(begin: -(AppSpacing.md), end: AppSpacing.md)
        .animate(
          CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
        );

    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _illustrationIn = _interval(0.00, 0.55);
    _badgeIn = _interval(0.25, 0.70);
    _titleIn = _interval(0.35, 0.80);
    _bodyIn = _interval(0.45, 0.90);
    _actionsIn = _interval(0.55, 1.00);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Respect the OS "reduce motion" accessibility setting.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion) {
      _floatController
        ..stop()
        ..value = 0.5;
      _roadController.stop();
      _entranceController.value = 1;
    } else {
      if (!_floatController.isAnimating) {
        _floatController.repeat(reverse: true);
      }
      if (!_roadController.isAnimating) _roadController.repeat();
      if (_entranceController.value == 0) _entranceController.forward();
    }
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _entranceController,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _floatController.dispose();
    _roadController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.xxxl + AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating Illustration
                  _Reveal(
                    animation: _illustrationIn,
                    child: _buildIllustration(colors),
                  ),

                  AppSpacing.xxxl.h,

                  // 404 Badge
                  _Reveal(
                    animation: _badgeIn,
                    child: QuickContainer(
                      px: AppSpacing.lg,
                      py: AppSpacing.sm - 2,
                      color: colors.primary.withValues(alpha: 0.12),
                      radius: AppRadius.full,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.35),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wrong_location_outlined,
                            size: AppSpacing.lg,
                            color: colors.primary,
                          ),
                          (AppSpacing.xs + 2).w,
                          Text(
                            'Error 404',
                            style: context.textTheme.labelMedium
                                ?.medium()
                                .textSpacing(1.2)
                                .colour(colors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSpacing.xl.h,

                  // Headline
                  _Reveal(
                    animation: _titleIn,
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Page Not Found',
                        style: context.textTheme.displaySmall
                            ?.weight(FontWeight.w800)
                            .colour(colors.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  AppSpacing.lg.h,

                  // Sub-text
                  _Reveal(
                    animation: _bodyIn,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _bodyMaxWidth,
                      ),
                      child: Text(
                        "Looks like this route took a wrong turn. The page "
                        "you're looking for doesn't exist or may have been moved.",
                        style: context.textTheme.bodyLarge
                            ?.regular()
                            .lineHeight(1.5)
                            .colour(colors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  (AppSpacing.xxl + AppSpacing.lg).h,

                  // CTAs
                  _Reveal(
                    animation: _actionsIn,
                    child: Row(
                      mainAxisAlignment: .center,
                      children: [
                        // Secondary CTA
                        AppButton(
                          text: 'Go Back',
                          type: ButtonType.secondaryPrimary,
                          isFlexible: true,
                          onPressed: _goBack,
                        ),

                        (AppSpacing.md + 2).w,

                        // Primary CTA
                        AppButton(
                          text: 'Go to Dashboard',
                          type: ButtonType.primary,
                          isFlexible: true,
                          onPressed: () => context.go(AppRoutes.home),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Illustration that scales down on narrow screens, floats, and casts a
  /// soft shadow that grows/shrinks with the float for a sense of depth.
  Widget _buildIllustration(AppThemeAccessor colors) {
    return Semantics(
      image: true,
      label: 'Illustration of a delivery truck stopped at a question-mark sign',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(_illustrationWidth, constraints.maxWidth);
          final scale = width / _illustrationWidth;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _floatAnimation.value * scale),
                  child: child,
                ),
                child: SizedBox(
                  width: width,
                  height: _illustrationHeight * scale,
                  child: FittedBox(
                    child: SizedBox(
                      width: _illustrationWidth,
                      height: _illustrationHeight,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          // Animated layer: background + moving road
                          painter: _RoadPainter(
                            colors: colors,
                            progress: _roadController,
                          ),
                          // Static layer: truck, sign, 404, dots
                          foregroundPainter: _NotFoundPainter(
                            colors: colors,
                            textTheme: context.textTheme,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              AppSpacing.sm.h,

              // Ground shadow
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, _) {
                  // 0 = highest point, 1 = lowest point
                  final t =
                      ((_floatAnimation.value + AppSpacing.md) /
                              (AppSpacing.md * 2))
                          .clamp(0.0, 1.0);

                  return Transform.scale(
                    scaleX: 0.8 + (0.2 * t),
                    child: SizedBox(
                      width: width * 0.55,
                      height: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(
                            alpha: 0.04 + (0.05 * t),
                          ),
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Fade + slide-up reveal used for the staggered entrance.
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Reveal({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Background circle + road with dashes that scroll to make the truck
/// look like it's driving. Repaints on every tick of [progress].
class _RoadPainter extends CustomPainter {
  final AppThemeAccessor colors;
  final Animation<double> progress;

  _RoadPainter({required this.colors, required this.progress})
    : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle
    canvas.drawCircle(
      Offset(w / 2, h / 2 + (AppSpacing.sm + 2)),
      (AppSpacing.xxxl * 3) + AppSpacing.xs,
      Paint()
        ..color = colors.primary.withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );

    // Road / ground
    final roadRect = Rect.fromLTWH(
      AppSpacing.sm + 2,
      h - (AppSpacing.xxl + AppSpacing.xl),
      w - (AppSpacing.xl),
      AppSpacing.xl,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(roadRect, Radius.circular(AppSpacing.sm + 2)),
      Paint()
        ..color = colors.outlineVariant
        ..style = PaintingStyle.fill,
    );

    // Road dashes (scrolling right → left, truck faces right)
    final step = AppSpacing.xxxl - 2;
    final shift = progress.value * step;
    final dashPaint = Paint()
      ..color = colors.onSurface
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        step,
        roadRect.top,
        w - (AppSpacing.xxl + AppSpacing.lg) + AppSpacing.lg,
        roadRect.bottom,
      ),
    );
    for (double x = -shift; x < w; x += step) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            h - ((AppSpacing.xxxl) + AppSpacing.xs + 1),
            AppSpacing.lg,
            AppSpacing.sm - 2,
          ),
          Radius.circular(AppSpacing.xs - 1),
        ),
        dashPaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.progress != progress;
}

/// Custom painter for rendering the static parts of the 404
/// transport-themed illustration (truck, sign, 404 text, dots).
class _NotFoundPainter extends CustomPainter {
  final AppThemeAccessor colors;
  final TextTheme textTheme;

  const _NotFoundPainter({required this.colors, required this.textTheme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cargo container
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.22,
          h - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 2),
          w * 0.48,
          AppSpacing.xxxl + AppSpacing.md + 2,
        ),
        Radius.circular(AppSpacing.xs + 1),
      ),
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.fill,
    );

    // Cab
    final cabPath = Path()
      ..moveTo(w * 0.70, h - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 2))
      ..lineTo(w * 0.70, h - (AppSpacing.xxxl * 3 + AppSpacing.md))
      ..quadraticBezierTo(
        w * 0.70,
        h - (AppSpacing.xxxl * 3 + AppSpacing.xxl),
        w * 0.78,
        h - (AppSpacing.xxxl * 3 + AppSpacing.xxl),
      )
      ..lineTo(w * 0.88, h - (AppSpacing.xxxl * 3 + AppSpacing.xs))
      ..quadraticBezierTo(
        w * 0.92,
        h - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 4),
        w * 0.90,
        h - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 2),
      )
      ..close();
    canvas.drawPath(
      cabPath,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.fill,
    );

    // Cab window
    final windowPath = Path()
      ..moveTo(w * 0.72, h - (AppSpacing.xxxl * 2 + AppSpacing.xxl))
      ..lineTo(w * 0.72, h - (AppSpacing.xxxl * 3 + AppSpacing.sm))
      ..quadraticBezierTo(
        w * 0.72,
        h - (AppSpacing.xxxl * 3 + AppSpacing.lg + 1),
        w * 0.78,
        h - (AppSpacing.xxxl * 3 + AppSpacing.lg + 1),
      )
      ..lineTo(w * 0.86, h - (AppSpacing.xxxl * 3 + 1))
      ..quadraticBezierTo(
        w * 0.88,
        h - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 3),
        w * 0.86,
        h - (AppSpacing.xxxl * 2 + AppSpacing.xxl),
      )
      ..close();
    canvas.drawPath(
      windowPath,
      Paint()
        ..color = colors.primary.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Cargo stripes
    final stripePaint = Paint()
      ..color = colors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final xPos = w * 0.27 + i * (w * 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xPos,
            h - (AppSpacing.xxxl * 2 + AppSpacing.xxl - 1),
            AppSpacing.sm,
            AppSpacing.xxl + AppSpacing.lg,
          ),
          Radius.circular(AppSpacing.xs),
        ),
        stripePaint,
      );
    }

    // Wheels
    final tyrePaint = Paint()
      ..color = colors.surfaceDim
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = colors.outlineVariant
      ..style = PaintingStyle.fill;
    final hubPaint = Paint()
      ..color = colors.primary
      ..style = PaintingStyle.fill;

    void drawWheel(double cx, double cy) {
      final center = Offset(cx, cy);
      canvas.drawCircle(center, AppSpacing.md + 2, tyrePaint);
      canvas.drawCircle(center, AppSpacing.sm + 1, rimPaint);
      canvas.drawCircle(center, AppSpacing.xs, hubPaint);
    }

    drawWheel(w * 0.35, h - AppSpacing.xxxl);
    drawWheel(w * 0.50, h - AppSpacing.xxxl);
    drawWheel(w * 0.82, h - AppSpacing.xxxl);

    // Sign post
    canvas.drawLine(
      Offset(w * 0.12, h - (AppSpacing.xxl + AppSpacing.xl)),
      Offset(w * 0.12, h - (AppSpacing.xxxl * 3 + AppSpacing.xxl)),
      Paint()
        ..color = colors.outlineVariant
        ..strokeWidth = AppSpacing.xs
        ..strokeCap = StrokeCap.round,
    );

    // Warning triangle sign (rounded corners for a softer look)
    final signPath = Path()
      ..moveTo(
        w * 0.12,
        h - (AppSpacing.xxxl * 4 + AppSpacing.xl + AppSpacing.xs + 1),
      )
      ..lineTo(
        w * 0.02,
        h - (AppSpacing.xxxl * 3 + AppSpacing.xxl + AppSpacing.xs + 1),
      )
      ..lineTo(
        w * 0.22,
        h - (AppSpacing.xxxl * 3 + AppSpacing.xxl + AppSpacing.xs + 1),
      )
      ..close();
    canvas.drawPath(
      signPath,
      Paint()
        ..color = colors.warning
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      signPath,
      Paint()
        ..color = colors.warning
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppSpacing.xs
        ..strokeJoin = StrokeJoin.round,
    );

    // "?" text on sign
    final qPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: textTheme.titleLarge
            ?.weight(FontWeight.w900)
            .colour(colors.onSurface)
            .decreaseSize(2)
            .lineHeight(1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    qPainter.paint(
      canvas,
      Offset(
        w * 0.12 - qPainter.width / 2,
        h - (AppSpacing.xxxl * 4 + AppSpacing.sm),
      ),
    );

    // Large faded 404 background text
    final fourhundredPainter = TextPainter(
      text: TextSpan(
        text: '404',
        style: textTheme.displayLarge
            ?.weight(FontWeight.w900)
            .colour(colors.primary.withValues(alpha: 0.7))
            .increaseSize(1)
            .lineHeight(1)
            .textSpacing(-2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    fourhundredPainter.paint(
      canvas,
      Offset(
        w / 2 - fourhundredPainter.width / 2,
        h / 2 - (AppSpacing.xxxl * 2 + AppSpacing.xxl + 2),
      ),
    );

    // Decorative dots
    final dots = [
      (
        w * 0.05,
        h * 0.15,
        AppSpacing.xs + 1.0,
        colors.primary.withValues(alpha: 0.4),
      ),
      (
        w * 0.95,
        h * 0.20,
        AppSpacing.sm - 1.0,
        colors.warning.withValues(alpha: 0.4),
      ),
      (
        w * 0.90,
        h * 0.55,
        AppSpacing.xs,
        colors.primary.withValues(alpha: 0.3),
      ),
      (
        w * 0.08,
        h * 0.60,
        AppSpacing.sm - 2.0,
        colors.primary.withValues(alpha: 0.2),
      ),
    ];
    for (final (x, y, r, color) in dots) {
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotFoundPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.textTheme != textTheme;
}
