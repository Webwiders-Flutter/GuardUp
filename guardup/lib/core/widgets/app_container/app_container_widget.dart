import 'package:flutter/material.dart';
import 'app_container_painter.dart';
import 'app_container_shape.dart';

/// A highly flexible, production-ready container widget — a supercharged
/// replacement for Flutter's built-in [Container].
///
/// Supports shapes, per-corner radius shortcuts, gradients, dashed/dotted
/// borders, animations, loading states, tap interactions with ripple, and
/// concise padding/margin shorthand.
///
/// Example:
/// ```dart
/// QuickContainer(
///   p: 16,
///   radius: 20,
///   color: Colors.white,
///   shadow: true,
///   onTap: () {},
///   child: Text('Hello'),
/// )
/// ```
///
/// Per-corner radius example:
/// ```dart
/// QuickContainer(
///   radiusTL: 24,  // top-left only
///   radiusBR: 24,  // bottom-right only
///   color: Colors.blue,
/// )
/// ```
///
/// Dotted border example:
/// ```dart
/// QuickContainer(
///   dotted: true,
///   borderColor: Colors.red,
///   dotWidth: 4,
///   dotSpacing: 6,
///   radius: 12,
/// )
/// ```
class AppContainer extends StatefulWidget {
  const AppContainer({
    super.key,
    this.child,
    // ── Size ──────────────────────────────────────────────────────────────
    this.w,
    this.h,
    this.minW,
    this.minH,
    this.maxW,
    this.maxH,
    // ── Padding ───────────────────────────────────────────────────────────
    this.p,
    this.px,
    this.py,
    this.pt,
    this.pb,
    this.pl,
    this.pr,
    // ── Margin ────────────────────────────────────────────────────────────
    this.m,
    this.mx,
    this.my,
    this.mt,
    this.mb,
    this.ml,
    this.mr,
    // ── Background ────────────────────────────────────────────────────────
    this.color,
    this.gradient,
    this.image,
    this.blendMode,
    // ── Shape ─────────────────────────────────────────────────────────────
    this.shape = AppContainerShape.rectangle,
    this.radius,
    this.radiusTL,
    this.radiusTR,
    this.radiusBL,
    this.radiusBR,
    this.borderRadius,
    // ── Border ────────────────────────────────────────────────────────────
    this.border,
    this.borderColor,
    this.borderWidth,
    // dashed
    this.dashed = false,
    this.dashLength = 8.0,
    this.gapLength = 5.0,
    // dotted
    this.dotted = false,
    this.dotWidth = 3.0,
    this.dotHeight,
    this.dotSpacing = 5.0,
    // ── Shadow ────────────────────────────────────────────────────────────
    this.shadow = false,
    this.shadows,
    // ── Interaction ───────────────────────────────────────────────────────
    this.onTap,
    this.onLongPress,
    this.ripple = false,
    this.disabled = false,
    // ── Animation ─────────────────────────────────────────────────────────
    this.animated = false,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    // ── Misc ──────────────────────────────────────────────────────────────
    this.alignment,
    this.clipBehavior = Clip.antiAlias,
    this.safeArea = false,
    this.loading = false,
  });

  // ── Child ───────────────────────────────────────────────────────────────
  final Widget? child;

  // ── Size ────────────────────────────────────────────────────────────────
  final double? w;
  final double? h;
  final double? minW;
  final double? minH;
  final double? maxW;
  final double? maxH;

  // ── Padding ─────────────────────────────────────────────────────────────
  /// All-sides padding. Overridden by [px]/[py] or individual sides.
  final double? p;
  final double? px;
  final double? py;
  final double? pt;
  final double? pb;
  final double? pl;
  final double? pr;

  // ── Margin ──────────────────────────────────────────────────────────────
  /// All-sides margin. Overridden by [mx]/[my] or individual sides.
  final double? m;
  final double? mx;
  final double? my;
  final double? mt;
  final double? mb;
  final double? ml;
  final double? mr;

  // ── Background ──────────────────────────────────────────────────────────
  final Color? color;
  final Gradient? gradient;
  final DecorationImage? image;
  final BlendMode? blendMode;

  // ── Shape ───────────────────────────────────────────────────────────────
  /// Shape of the container. Defaults to [AppContainerShape.rectangle].
  final AppContainerShape shape;

  /// Uniform corner radius shorthand — [BorderRadius.circular].
  /// Used as the fallback value for any unspecified per-corner radius.
  /// Only applies when [shape] is [AppContainerShape.rectangle].
  final double? radius;

  /// Top-left corner radius. Overrides [radius] for this corner.
  final double? radiusTL;

  /// Top-right corner radius. Overrides [radius] for this corner.
  final double? radiusTR;

  /// Bottom-left corner radius. Overrides [radius] for this corner.
  final double? radiusBL;

  /// Bottom-right corner radius. Overrides [radius] for this corner.
  final double? radiusBR;

  /// Fully explicit per-corner radius. Highest priority — overrides all radius shortcuts.
  /// Only applies when [shape] is [AppContainerShape.rectangle].
  final BorderRadius? borderRadius;

  // ── Border ──────────────────────────────────────────────────────────────
  /// Fully custom border object. Overrides [borderColor]/[borderWidth].
  /// Not used when [dashed] or [dotted] is true.
  final BoxBorder? border;

  /// Border color (used for solid, dashed, and dotted borders).
  final Color? borderColor;

  /// Border / stroke width.
  final double? borderWidth;

  // dashed ────────────────────────────────────────────────────────────────
  /// Draw a dashed border. Takes priority over [dotted].
  final bool dashed;

  /// Length of each dash segment.
  final double dashLength;

  /// Gap between dash segments.
  final double gapLength;

  // dotted ────────────────────────────────────────────────────────────────
  /// Draw a dotted border. Ignored when [dashed] is true.
  final bool dotted;

  /// Width (and diameter when circular) of each dot.
  final double dotWidth;

  /// Height of each dot. When null or equal to [dotWidth], dots are circles.
  /// When different from [dotWidth], dots become rectangles aligned to the path.
  final double? dotHeight;

  /// Gap between consecutive dots.
  final double dotSpacing;

  // ── Shadow ──────────────────────────────────────────────────────────────
  final bool shadow;
  final List<BoxShadow>? shadows;

  // ── Interaction ─────────────────────────────────────────────────────────
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Use Material ink ripple instead of plain [GestureDetector].
  final bool ripple;

  /// Reduces opacity to 50 % and blocks all interaction.
  final bool disabled;

  // ── Animation ───────────────────────────────────────────────────────────
  final bool animated;
  final Duration duration;
  final Curve curve;

  // ── Misc ────────────────────────────────────────────────────────────────
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;
  final bool safeArea;
  final bool loading;

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final Animation<double> _shimmerAlpha;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _shimmerAlpha = Tween<double>(
      begin: 0.25,
      end: 0.65,
    ).animate(CurvedAnimation(parent: _shimmer, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  EdgeInsets get _padding => EdgeInsets.only(
    left: widget.pl ?? widget.px ?? widget.p ?? 0,
    right: widget.pr ?? widget.px ?? widget.p ?? 0,
    top: widget.pt ?? widget.py ?? widget.p ?? 0,
    bottom: widget.pb ?? widget.py ?? widget.p ?? 0,
  );

  EdgeInsets get _margin => EdgeInsets.only(
    left: widget.ml ?? widget.mx ?? widget.m ?? 0,
    right: widget.mr ?? widget.mx ?? widget.m ?? 0,
    top: widget.mt ?? widget.my ?? widget.m ?? 0,
    bottom: widget.mb ?? widget.my ?? widget.m ?? 0,
  );

  /// Resolves the effective [BorderRadius] based on priority:
  ///
  /// 1. [borderRadius] — explicit full object, highest priority.
  /// 2. Per-corner shortcuts ([radiusTL], [radiusTR], [radiusBL], [radiusBR]),
  ///    each falling back to [radius] for unspecified corners.
  /// 3. [radius] — uniform fallback.
  /// 4. [BorderRadius.zero] — no rounding.
  BorderRadius? get _effectiveBorderRadius {
    switch (widget.shape) {
      case AppContainerShape.circle:
        return null;
      case AppContainerShape.stadium:
        return BorderRadius.circular(9999);
      case AppContainerShape.rectangle:
        // 1. Explicit full BorderRadius wins.
        if (widget.borderRadius != null) return widget.borderRadius;

        // 2. Any per-corner shortcut → build BorderRadius.only.
        final tl = widget.radiusTL;
        final tr = widget.radiusTR;
        final bl = widget.radiusBL;
        final br = widget.radiusBR;
        if (tl != null || tr != null || bl != null || br != null) {
          final fallback = widget.radius ?? 0;
          return BorderRadius.only(
            topLeft: Radius.circular(tl ?? fallback),
            topRight: Radius.circular(tr ?? fallback),
            bottomLeft: Radius.circular(bl ?? fallback),
            bottomRight: Radius.circular(br ?? fallback),
          );
        }

        // 3. Uniform radius.
        if (widget.radius != null) return BorderRadius.circular(widget.radius!);

        return BorderRadius.zero;
    }
  }

  BoxShape get _boxShape => widget.shape == AppContainerShape.circle
      ? BoxShape.circle
      : BoxShape.rectangle;

  BoxBorder? _resolveBorder(BuildContext context) {
    // Custom painters handle dashed/dotted — no BoxDecoration border needed.
    if (widget.dashed || widget.dotted) return null;
    if (widget.border != null) return widget.border;
    if (widget.borderColor != null || widget.borderWidth != null) {
      return Border.all(
        color: widget.borderColor ?? Theme.of(context).dividerColor,
        width: widget.borderWidth ?? 1.0,
      );
    }
    return null;
  }

  List<BoxShadow>? get _effectiveShadows {
    if (widget.shadows != null) return widget.shadows;
    if (widget.shadow) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return null;
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final br = _effectiveBorderRadius;
    final bs = _boxShape;
    return BoxDecoration(
      color: widget.gradient == null
          ? (widget.color ?? Colors.transparent)
          : null,
      gradient: widget.gradient,
      image: widget.image,
      shape: bs,
      borderRadius: bs == BoxShape.circle ? null : br,
      border: _resolveBorder(context),
      boxShadow: _effectiveShadows,
      backgroundBlendMode: widget.blendMode,
    );
  }

  BoxConstraints? get _constraints {
    if (widget.minW == null &&
        widget.minH == null &&
        widget.maxW == null &&
        widget.maxH == null) {
      return null;
    }
    return BoxConstraints(
      minWidth: widget.minW ?? 0,
      minHeight: widget.minH ?? 0,
      maxWidth: widget.maxW ?? double.infinity,
      maxHeight: widget.maxH ?? double.infinity,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final decoration = _buildDecoration(context);
    final br = _effectiveBorderRadius;

    // 1. Core container (no margin — margin is applied as an outer Padding so
    //    dashed/dotted CustomPaint sits flush with the visual bounds).
    Widget result;
    if (widget.animated) {
      result = AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        width: widget.w,
        height: widget.h,
        padding: _padding,
        constraints: _constraints,
        alignment: widget.alignment,
        decoration: decoration,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      );
    } else {
      result = Container(
        width: widget.w,
        height: widget.h,
        padding: _padding,
        constraints: _constraints,
        alignment: widget.alignment,
        decoration: decoration,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      );
    }

    // 2. Custom border overlay — dashed takes priority over dotted.
    final borderColor = widget.borderColor ?? Theme.of(context).dividerColor;
    final borderWidth = widget.borderWidth ?? 1.5;

    if (widget.dashed) {
      result = CustomPaint(
        painter: DashedBorderPainter(
          color: borderColor,
          strokeWidth: borderWidth,
          shape: widget.shape,
          borderRadius: br,
          dashLength: widget.dashLength,
          gapLength: widget.gapLength,
        ),
        child: result,
      );
    } else if (widget.dotted) {
      result = CustomPaint(
        painter: DottedBorderPainter(
          color: borderColor,
          strokeWidth: borderWidth,
          shape: widget.shape,
          borderRadius: br,
          dotWidth: widget.dotWidth,
          dotHeight: widget.dotHeight,
          dotSpacing: widget.dotSpacing,
        ),
        child: result,
      );
    }

    // 3. Loading shimmer overlay.
    if (widget.loading) {
      result = Stack(
        fit: StackFit.passthrough,
        children: [
          result,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerAlpha,
              builder: (_, _) => Container(
                decoration: BoxDecoration(
                  shape: _boxShape,
                  borderRadius: _boxShape == BoxShape.circle ? null : br,
                  color: Colors.white.withValues(alpha: _shimmerAlpha.value),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 4. Tap interaction.
    final interactive =
        (widget.onTap != null || widget.onLongPress != null) &&
        !widget.disabled &&
        !widget.loading;
    if (widget.onTap != null || widget.onLongPress != null) {
      if (widget.ripple) {
        result = Material(
          color: Colors.transparent,
          borderRadius: br,
          child: InkWell(
            onTap: interactive ? widget.onTap : null,
            onLongPress: interactive ? widget.onLongPress : null,
            borderRadius: br,
            customBorder: widget.shape == AppContainerShape.circle
                ? const CircleBorder()
                : null,
            child: result,
          ),
        );
      } else {
        result = GestureDetector(
          onTap: interactive ? widget.onTap : null,
          onLongPress: interactive ? widget.onLongPress : null,
          child: result,
        );
      }
    }

    // 5. Disabled opacity.
    if (widget.disabled) {
      result = Opacity(opacity: 0.5, child: result);
    }

    // 6. Margin.
    final margin = _margin;
    if (margin != EdgeInsets.zero) {
      result = Padding(padding: margin, child: result);
    }

    // 7. Safe area.
    if (widget.safeArea) {
      result = SafeArea(child: result);
    }

    return result;
  }
}
