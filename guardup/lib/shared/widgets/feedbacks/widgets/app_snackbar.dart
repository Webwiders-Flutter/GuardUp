import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_sizes.dart';
import '/core/extensions/number.extension.dart';

import '/app/routes/app_router.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/layout.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '../feedback.service.dart';

enum SnackbarType { success, error, warning, info }

/// Screen alignment position for desktop/tablet notifications.
enum SnackbarPosition {
  bottomRight,
  bottomLeft,
  bottomCenter,
  topRight,
  topCenter,
}

/// UI specification record for snackbar appearances.
typedef SnackbarStyle = ({
  Color backgroundColor,
  Color iconColor,
  Color iconBackgroundColor,
  Color borderColor,
  Color? actionColor,
  IconData icon,
});

class SnackbarStyles {
  static SnackbarStyle getStyle(SnackbarType type, BuildContext context) {
    final colors = context.colors;
    switch (type) {
      case SnackbarType.success:
        return (
          backgroundColor: colors.success,
          iconColor: colors.onSurface,
          iconBackgroundColor: colors.onSurface.withValues(alpha: 0.18),
          borderColor: colors.onSurface.withValues(alpha: 0.22),
          actionColor: colors.onSurface,
          icon: Icons.check_circle_rounded,
        );

      case SnackbarType.error:
        return (
          backgroundColor: colors.error,
          iconColor: colors.onSurface,
          iconBackgroundColor: colors.onSurface.withValues(alpha: 0.18),
          borderColor: colors.onSurface.withValues(alpha: 0.22),
          actionColor: colors.onSurface,
          icon: Icons.error_rounded,
        );

      case SnackbarType.warning:
        return (
          backgroundColor: colors.warning,
          iconColor: colors.onSurface,
          iconBackgroundColor: colors.onSurface.withValues(alpha: 0.18),
          borderColor: colors.onSurface.withValues(alpha: 0.22),
          actionColor: colors.onSurface,
          icon: Icons.warning_rounded,
        );

      case SnackbarType.info:
        return (
          backgroundColor: colors.primary,
          iconColor: colors.onSurface,
          iconBackgroundColor: colors.onSurface.withValues(alpha: 0.18),
          borderColor: colors.onSurface.withValues(alpha: 0.22),
          actionColor: colors.secondaryContainer,
          icon: Icons.info_rounded,
        );
    }
  }
}

class AppSnackbar {
  static OverlayEntry? _activeOverlayEntry;
  static Timer? _overlayTimer;

  /// Removes any active floating overlay snackbar.
  static void hideOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _activeOverlayEntry?.remove();
    _activeOverlayEntry = null;
  }

  /// Displays a responsive toast/snackbar using [LayoutExtension].
  ///
  /// Set [useOverlay] to `true` to render above bottom sheets, dialogs, and modal routes.
  static void show({
    required String message,
    String? title,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbar,
    SnackbarPosition position = SnackbarPosition.bottomCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool isCompact = false,
    bool useOverlay = false,
    BuildContext? context,
  }) {
    FeedbackService.clearSnackbars();

    final targetContext =
        context ?? FeedbackService.messengerKey.currentContext;
    if (targetContext == null) return;

    final bool isTop =
        position == SnackbarPosition.topCenter ||
        position == SnackbarPosition.topRight;

    if (useOverlay || isTop) {
      showOverlay(
        context: targetContext,
        message: message,
        title: title,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        position: position,
        maxWidth: maxWidth,
        showCloseButton: showCloseButton,
        isCompact: isCompact,
      );
      return;
    }

    final theme = SnackBarTheme.of(targetContext);
    final style = SnackbarStyles.getStyle(type, targetContext);

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lg.toBorderRadius),
      margin: _resolveMargin(
        targetContext,
        position: position,
        maxWidth: maxWidth,
      ),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: targetContext.colors.transparent,
      content: _AppSnackbarContent(
        message: message,
        title: title,
        style: style,
        actionLabel: actionLabel,
        onAction: onAction,
        textStyle: theme.contentTextStyle,
        showCloseButton: showCloseButton,
        isCompact: isCompact,
      ),
    );

    FeedbackService.showSnackbar(snackBar);
  }

  /// Displays a snackbar inside an [OverlayEntry] so it appears above bottom sheets, dialogs, and modal routes.
  static void showOverlay({
    required BuildContext context,
    required String message,
    String? title,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbar,
    SnackbarPosition position = SnackbarPosition.topCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool isCompact = false,
  }) {
    hideOverlay();

    final overlayState =
        Overlay.maybeOf(context) ??
        AppRouter.rootNavigatorKey.currentState?.overlay ??
        (FeedbackService.messengerKey.currentContext != null
            ? Overlay.maybeOf(FeedbackService.messengerKey.currentContext!)
            : null);

    if (overlayState == null) {
      final targetContext = context.mounted
          ? context
          : FeedbackService.messengerKey.currentContext;
      if (targetContext == null) return;
      final theme = SnackBarTheme.of(targetContext);
      final style = SnackbarStyles.getStyle(type, targetContext);

      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg.toBorderRadius,
        ),
        margin: _resolveMargin(
          targetContext,
          position: position,
          maxWidth: maxWidth,
        ),
        padding: EdgeInsets.zero,
        clipBehavior: Clip.none,
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        backgroundColor: targetContext.colors.transparent,
        content: _AppSnackbarContent(
          message: message,
          title: title,
          style: style,
          actionLabel: actionLabel,
          onAction: onAction,
          textStyle: theme.contentTextStyle,
          showCloseButton: showCloseButton,
          isCompact: isCompact,
        ),
      );

      FeedbackService.showSnackbar(snackBar);
      return;
    }

    final style = SnackbarStyles.getStyle(type, context);
    final theme = SnackBarTheme.of(context);
    final overlayMargin = _resolveOverlayMargin(
      context,
      position: position,
      maxWidth: maxWidth,
    );

    _activeOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: Material(
              type: MaterialType.transparency,
              child: SafeArea(
                child: Padding(
                  padding: overlayMargin,
                  child: Align(
                    alignment: _resolveAlignment(position),
                    child: _AppSnackbarContent(
                      message: message,
                      title: title,
                      style: style,
                      actionLabel: actionLabel,
                      onAction: () {
                        hideOverlay();
                        onAction?.call();
                      },
                      textStyle: theme.contentTextStyle,
                      showCloseButton: showCloseButton,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_activeOverlayEntry!);
    _overlayTimer = Timer(duration, hideOverlay);
  }

  /// Calculates responsive margins for floating Scaffold SnackBar.
  static EdgeInsetsGeometry _resolveMargin(
    BuildContext context, {
    required SnackbarPosition position,
    double? maxWidth,
  }) {
    final screenWidth = context.screenWidth;
    final double effectiveMaxWidth = maxWidth ?? 420.0;
    final double snackbarWidth = math.min(
      effectiveMaxWidth,
      screenWidth - (AppSpacing.xxxl + AppSpacing.lg),
    );

    if (context.isMobile) {
      return AppSpacing.lg.allPadding;
    }

    switch (position) {
      case SnackbarPosition.bottomRight:
        return EdgeInsets.only(
          left: screenWidth - snackbarWidth - AppSpacing.xxl,
          right: AppSpacing.xxl,
          bottom: AppSpacing.xxl,
        );
      case SnackbarPosition.bottomLeft:
        return EdgeInsets.only(
          left: AppSpacing.xxl,
          right: screenWidth - snackbarWidth - AppSpacing.xxl,
          bottom: AppSpacing.xxl,
        );
      case SnackbarPosition.bottomCenter:
      case SnackbarPosition.topRight:
      case SnackbarPosition.topCenter:
        final horizontalInset = (screenWidth - snackbarWidth) / 2.0;
        return EdgeInsets.only(
          left: horizontalInset,
          right: horizontalInset,
          bottom: AppSpacing.xxl,
        );
    }
  }

  /// Calculates margins for OverlayEntry snackbars (positioned above bottom sheets/dialogs).
  static EdgeInsetsGeometry _resolveOverlayMargin(
    BuildContext context, {
    required SnackbarPosition position,
    double? maxWidth,
  }) {
    final screenWidth = context.screenWidth;
    final double effectiveMaxWidth = maxWidth ?? 420.0;
    final double snackbarWidth = math.min(
      effectiveMaxWidth,
      screenWidth - (AppSpacing.xxxl + AppSpacing.lg),
    );

    final double topMargin = kToolbarHeight + AppSpacing.sm;

    if (context.isMobile) {
      switch (position) {
        case SnackbarPosition.topCenter:
        case SnackbarPosition.topRight:
          return EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: topMargin,
          );
        case SnackbarPosition.bottomCenter:
        case SnackbarPosition.bottomLeft:
        case SnackbarPosition.bottomRight:
          return const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
          );
      }
    }

    final horizontalInset = (screenWidth - snackbarWidth) / 2.0;

    switch (position) {
      case SnackbarPosition.topCenter:
        return EdgeInsets.only(
          left: horizontalInset,
          right: horizontalInset,
          top: topMargin,
        );
      case SnackbarPosition.topRight:
        return EdgeInsets.only(
          left: screenWidth - snackbarWidth - AppSpacing.xxl,
          right: AppSpacing.xxl,
          top: topMargin,
        );
      case SnackbarPosition.bottomRight:
        return EdgeInsets.only(
          left: screenWidth - snackbarWidth - AppSpacing.xxl,
          right: AppSpacing.xxl,
          bottom: AppSpacing.xxl,
        );
      case SnackbarPosition.bottomLeft:
        return EdgeInsets.only(
          left: AppSpacing.xxl,
          right: screenWidth - snackbarWidth - AppSpacing.xxl,
          bottom: AppSpacing.xxl,
        );
      case SnackbarPosition.bottomCenter:
        return EdgeInsets.only(
          left: horizontalInset,
          right: horizontalInset,
          bottom: AppSpacing.xxl,
        );
    }
  }

  static Alignment _resolveAlignment(SnackbarPosition position) {
    switch (position) {
      case SnackbarPosition.topCenter:
        return Alignment.topCenter;
      case SnackbarPosition.topRight:
        return Alignment.topRight;
      case SnackbarPosition.bottomCenter:
        return Alignment.bottomCenter;
      case SnackbarPosition.bottomLeft:
        return Alignment.bottomLeft;
      case SnackbarPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  static void error(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbar,
    SnackbarPosition position = SnackbarPosition.topCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool useOverlay = false,
    BuildContext? context,
  }) {
    show(
      message: message,
      title: title,
      type: SnackbarType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      position: position,
      maxWidth: maxWidth,
      showCloseButton: showCloseButton,
      useOverlay: useOverlay,
      context: context,
    );
  }

  static void success(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbarShort,
    SnackbarPosition position = SnackbarPosition.topCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool useOverlay = false,
    BuildContext? context,
  }) {
    show(
      message: message,
      title: title,
      type: SnackbarType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      position: position,
      maxWidth: maxWidth,
      showCloseButton: showCloseButton,
      useOverlay: useOverlay,
      context: context,
    );
  }

  static void warning(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbar,
    SnackbarPosition position = SnackbarPosition.topCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool useOverlay = false,
    BuildContext? context,
  }) {
    show(
      message: message,
      title: title,
      type: SnackbarType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      position: position,
      maxWidth: maxWidth,
      showCloseButton: showCloseButton,
      useOverlay: useOverlay,
      context: context,
    );
  }

  static void info(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = AppDurations.snackbarShort,
    SnackbarPosition position = SnackbarPosition.topCenter,
    double? maxWidth,
    bool showCloseButton = true,
    bool useOverlay = false,
    BuildContext? context,
  }) {
    show(
      message: message,
      title: title,
      type: SnackbarType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      position: position,
      maxWidth: maxWidth,
      showCloseButton: showCloseButton,
      useOverlay: useOverlay,
      context: context,
    );
  }
}

class _AppSnackbarContent extends StatelessWidget {
  final String message;
  final String? title;
  final SnackbarStyle style;
  final String? actionLabel;
  final VoidCallback? onAction;
  final TextStyle? textStyle;
  final bool showCloseButton;
  final bool isCompact;

  const _AppSnackbarContent({
    required this.message,
    required this.style,
    this.title,
    this.actionLabel,
    this.onAction,
    this.textStyle,
    this.showCloseButton = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      px: isCompact ? AppSpacing.md : AppSpacing.lg,
      py: isCompact ? AppSpacing.smd : AppSpacing.mlg,
      color: style.backgroundColor.withValues(alpha: 0.96),
      radius: isCompact ? AppRadius.md : AppRadius.lg,
      border: Border.all(color: style.borderColor, width: 1.0),
      shadows: [
        BoxShadow(
          color: colors.surfaceDim.withValues(alpha: 0.16),
          blurRadius: AppSpacing.lg,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colors.surfaceDim.withValues(alpha: 0.08),
          blurRadius: AppSpacing.xs,
          offset: const Offset(0, 1),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with circular background
          Container(
            padding: (isCompact ? AppSpacing.xs : AppSpacing.ssm).allPadding,
            decoration: BoxDecoration(
              color: style.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              style.icon,
              color: style.iconColor,
              size: isCompact ? AppSizes.iconSmd : AppSizes.iconMd,
            ),
          ),
          (isCompact ? AppSpacing.sm : AppSpacing.md).w,

          // Message & optional title
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    style:
                        (isCompact
                                ? context.textTheme.labelMedium?.bold()
                                : context.textTheme.titleSmall?.bold())
                            ?.size(isCompact ? 12 : 13)
                            .colour(colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.xxs.h,
                ],
                Text(
                  message,
                  style:
                      (textStyle ??
                              (isCompact
                                  ? context.textTheme.bodySmall?.semiBold()
                                  : context.textTheme.bodyMedium?.medium()) ??
                              ThemeData.fallback().textTheme.bodyMedium!)
                          .size(isCompact ? 11 : 12)
                          .colour(textStyle?.color ?? colors.onSurface)
                          .lineHeight(1.3),
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action button
          if (actionLabel != null && actionLabel!.trim().isNotEmpty) ...[
            AppSpacing.sm.w,
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  FeedbackService.clearSnackbars();
                  onAction?.call();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? AppSpacing.sm : AppSpacing.smd,
                    vertical: isCompact ? AppSpacing.xxs : AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.15),
                    borderRadius: AppRadius.sm.toBorderRadius,
                  ),
                  child: Text(
                    actionLabel!,
                    style:
                        (isCompact
                                ? context.textTheme.labelSmall?.bold()
                                : context.textTheme.labelMedium?.bold())
                            ?.colour(style.actionColor ?? colors.onSurface),
                  ),
                ),
              ),
            ),
          ],

          // Close button
          if (showCloseButton) ...[
            (isCompact ? AppSpacing.xs : AppSpacing.sm).w,
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: FeedbackService.clearSnackbars,
                borderRadius: AppRadius.full.toBorderRadius,
                child: Padding(
                  padding:
                      (isCompact ? AppSpacing.xxs : AppSpacing.xs).allPadding,
                  child: Icon(
                    Icons.close_rounded,
                    size: isCompact ? AppSizes.iconSm : AppSizes.iconMd,
                    color: colors.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
