import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '/app/theme/colors/color_accessor.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../core/extensions/context.extension.dart';
import '../../core/extensions/spacing.extension.dart';
import '../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/features/dashboard/presentation/screens/dashboard.screen.dart';

/// 404 Not Found screen displayed when a requested route doesn't exist.
class NotFoundScreen extends StatefulWidget {
  const NotFoundScreen({super.key});

  @override
  State<NotFoundScreen> createState() => _NotFoundScreenState();
}

class _NotFoundScreenState extends State<NotFoundScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _fadeController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -(AppSpacing.md), end: AppSpacing.md)
        .animate(
          CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
        );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xxxl,
                vertical: AppSpacing.xxxl + AppSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Floating Illustration
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: (AppSpacing.xxxl * 8) + AppSpacing.xs,
                      height:
                          (AppSpacing.xxxl * 6) +
                          AppSpacing.xxl +
                          AppSpacing.xs,
                      child: CustomPaint(
                        painter: _NotFoundPainter(
                          colors: colors,
                          textTheme: context.textTheme,
                        ),
                      ),
                    ),
                  ),

                  (AppSpacing.xxxl + AppSpacing.lg).h,

                  // 404 Badge
                  QuickContainer(
                    px: AppSpacing.lg,
                    py: AppSpacing.sm - 2,
                    color: colors.secondary.withValues(alpha: 0.12),
                    radius: AppRadius.full,
                    border: Border.all(
                      color: colors.secondary.withValues(alpha: 0.35),
                    ),
                    child: Text(
                      'Error 404',
                      style: context.textTheme.labelMedium
                          ?.medium()
                          .colour(colors.secondary)
                          .textSpacing(1.2),
                    ),
                  ),

                  AppSpacing.xl.h,

                  // Headline
                  Text(
                    'Page Not Found',
                    style: context.textTheme.displaySmall
                        ?.weight(FontWeight.w800)
                        .colour(colors.primary),
                    textAlign: TextAlign.center,
                  ),

                  AppSpacing.lg.h,

                  // Sub-text
                  Text(
                    "The page you're looking for doesn't exist\nor may have been moved.",
                    style: context.textTheme.bodyLarge?.regular().colour(
                      colors.onSurfaceSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  (AppSpacing.xxl + AppSpacing.lg).h,

                  // Primary CTA
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      // Secondary CTA
                      AppButton(
                        text: 'Go Back',
                        type: ButtonType.secondaryOff,
                        fullWidth: false,
                        size: ButtonSize.large,
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(DashboardScreen.route);
                          }
                        },
                      ),
                      (AppSpacing.md + 2).w,

                      AppButton(
                        text: 'Go to Dashboard',
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                        fullWidth: false,
                        onPressed: () => context.go(DashboardScreen.route),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering the 404 transport-themed illustration.
class _NotFoundPainter extends CustomPainter {
  final AppThemeAccessor colors;
  final TextTheme textTheme;

  const _NotFoundPainter({required this.colors, required this.textTheme});

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
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          AppSpacing.sm + 2,
          h - (AppSpacing.xxl + AppSpacing.xl),
          w - (AppSpacing.xl),
          AppSpacing.xl,
        ),
        Radius.circular(AppSpacing.sm + 2),
      ),
      Paint()
        ..color = colors.borderExtraLight
        ..style = PaintingStyle.fill,
    );

    // Road dashes
    final dashPaint = Paint()
      ..color = colors.white
      ..style = PaintingStyle.fill;
    for (
      double x = AppSpacing.xxxl - 2;
      x < w - (AppSpacing.xxl + AppSpacing.lg);
      x += (AppSpacing.xxxl - 2)
    ) {
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
        ..color = colors.secondary.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Cargo stripes
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
        Paint()
          ..color = colors.secondary.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }

    // Wheels
    void drawWheel(double cx, double cy) {
      canvas.drawCircle(
        Offset(cx, cy),
        AppSpacing.md + 2,
        Paint()
          ..color = colors.backgroundDark
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        AppSpacing.sm + 1,
        Paint()
          ..color = colors.borderDark
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        AppSpacing.xs,
        Paint()
          ..color = colors.secondary
          ..style = PaintingStyle.fill,
      );
    }

    drawWheel(w * 0.35, h - AppSpacing.xxxl);
    drawWheel(w * 0.50, h - AppSpacing.xxxl);
    drawWheel(w * 0.82, h - AppSpacing.xxxl);

    // Sign post
    canvas.drawLine(
      Offset(w * 0.12, h - (AppSpacing.xxl + AppSpacing.xl)),
      Offset(w * 0.12, h - (AppSpacing.xxxl * 3 + AppSpacing.xxl)),
      Paint()
        ..color = colors.borderDark
        ..strokeWidth = AppSpacing.xs
        ..strokeCap = StrokeCap.round,
    );

    // Warning triangle sign
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

    // "?" text on sign
    final qPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: textTheme.titleLarge
            ?.weight(FontWeight.w900)
            .colour(colors.white)
            .size(AppSpacing.lg)
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
            .colour(colors.primary.withValues(alpha: 0.07))
            .size((AppSpacing.xxxl * 2) - 6)
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
        colors.secondary.withValues(alpha: 0.4),
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
        colors.secondary.withValues(alpha: 0.3),
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
      oldDelegate.colors != colors;
}
