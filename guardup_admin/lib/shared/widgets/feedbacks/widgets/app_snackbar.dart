import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/layout.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '../feedback.service.dart';
import '../../admin_layout/app_side_panel.dart';

enum SnackbarType { success, error, warning, info }

/// Screen alignment position for desktop/tablet notifications.
enum SnackbarPosition {
  bottomRight,
  bottomCenter,
  bottomLeft,
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
          iconColor: colors.white,
          iconBackgroundColor: colors.white.withValues(alpha: 0.18),
          borderColor: colors.white.withValues(alpha: 0.22),
          actionColor: colors.white,
          icon: Icons.check_circle_rounded,
        );

      case SnackbarType.error:
        return (
          backgroundColor: colors.error,
          iconColor: colors.white,
          iconBackgroundColor: colors.white.withValues(alpha: 0.18),
          borderColor: colors.white.withValues(alpha: 0.22),
          actionColor: colors.white,
          icon: Icons.error_rounded,
        );

      case SnackbarType.warning:
        return (
          backgroundColor: colors.warning,
          iconColor: colors.white,
          iconBackgroundColor: colors.white.withValues(alpha: 0.18),
          borderColor: colors.white.withValues(alpha: 0.22),
          actionColor: colors.white,
          icon: Icons.warning_rounded,
        );

      case SnackbarType.info:
        return (
          backgroundColor: colors.primary,
          iconColor: colors.white,
          iconBackgroundColor: colors.white.withValues(alpha: 0.18),
          borderColor: colors.white.withValues(alpha: 0.22),
          actionColor: colors.secondaryLight,
          icon: Icons.info_rounded,
        );
    }
  }
}

class AppSnackbar {
  /// Displays a responsive toast/snackbar using [LayoutExtension].
  ///
  /// - When a sidebar is open ([AppSidePanel.isOpen]):
  ///   Renders as a compact snackbar at the top so it never hides behind the panel.
  /// - When no sidebar is open:
  ///   Renders as the standard floating snackbar at [position] (default: bottomRight).
  static void show({
    required String message,
    String? title,
    SnackbarType type = SnackbarType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    SnackbarPosition position = SnackbarPosition.bottomRight,
    double? maxWidth,
    bool showCloseButton = true,
  }) {
    final context = FeedbackService.messengerKey.currentContext;
    if (context == null) return;

    final isSidebarOpen = AppSidePanel.isOpen;
    final theme = SnackBarTheme.of(context);
    final style = SnackbarStyles.getStyle(type, context);

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: isSidebarOpen ? AppRadius.mdRadius : AppRadius.lgRadius,
      ),
      margin: _resolveMargin(
        context,
        position: position,
        maxWidth: maxWidth,
        isSidebarOpen: isSidebarOpen,
      ),
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      backgroundColor: context.colors.transparent,
      content: _AppSnackbarContent(
        message: message,
        title: title,
        style: style,
        actionLabel: actionLabel,
        onAction: onAction,
        textStyle: theme.contentTextStyle,
        showCloseButton: showCloseButton,
        isCompact: isSidebarOpen,
      ),
    );

    FeedbackService.showSnackbar(snackBar);
  }

  /// Calculates responsive margins based on [LayoutExtension] breakpoints
  /// and whether a side panel is currently open.
  static EdgeInsetsGeometry _resolveMargin(
    BuildContext context, {
    required SnackbarPosition position,
    required bool isSidebarOpen,
    double? maxWidth,
  }) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;
    final double effectiveMaxWidth =
        maxWidth ?? (isSidebarOpen ? 360.0 : 420.0);
    final double snackbarWidth = math.min(
      effectiveMaxWidth,
      screenWidth - (AppSpacing.xxxl + AppSpacing.lg),
    );

    // If sidebar is open, position the snackbar at the top so it's always in view
    if (isSidebarOpen) {
      final topOffset = MediaQuery.of(context).padding.top + AppSpacing.lg;
      final bottomMargin = math.max(0.0, screenHeight - topOffset - 64.0);

      if (context.isMobile) {
        return EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: bottomMargin,
        );
      }

      return EdgeInsets.only(
        left: screenWidth - snackbarWidth - AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: bottomMargin,
      );
    }

    if (context.isMobile) {
      return const EdgeInsets.all(AppSpacing.lg);
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

  static void error(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    SnackbarPosition position = SnackbarPosition.bottomRight,
    double? maxWidth,
    bool showCloseButton = true,
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
    );
  }

  static void success(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    SnackbarPosition position = SnackbarPosition.bottomRight,
    double? maxWidth,
    bool showCloseButton = true,
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
    );
  }

  static void warning(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    SnackbarPosition position = SnackbarPosition.bottomRight,
    double? maxWidth,
    bool showCloseButton = true,
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
    );
  }

  static void info(
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    SnackbarPosition position = SnackbarPosition.bottomRight,
    double? maxWidth,
    bool showCloseButton = true,
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
      py: isCompact ? AppSpacing.sm + 1 : AppSpacing.md + 2,
      color: style.backgroundColor.withValues(alpha: 0.96),
      radius: isCompact ? AppRadius.md : AppRadius.lg,
      border: Border.all(color: style.borderColor, width: 1.0),
      shadows: [
        BoxShadow(
          color: colors.black.withValues(alpha: 0.16),
          blurRadius: AppSpacing.lg,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colors.black.withValues(alpha: 0.08),
          blurRadius: AppSpacing.xs,
          offset: const Offset(0, 1),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon with circular background
          Container(
            padding: EdgeInsets.all(
              isCompact ? AppSpacing.xs : AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: style.iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              style.icon,
              color: style.iconColor,
              size: isCompact ? AppSpacing.lg : AppSpacing.xl,
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
                            ?.size(
                              isCompact ? AppSpacing.md : AppSpacing.md + 0.5,
                            )
                            .colour(colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (AppSpacing.xs / 2).h,
                ],
                Text(
                  message,
                  style:
                      (textStyle ??
                              (isCompact
                                  ? context.textTheme.bodySmall?.semiBold()
                                  : context.textTheme.bodyMedium?.medium()) ??
                              ThemeData.fallback().textTheme.bodyMedium!)
                          .size(isCompact ? AppSpacing.md - 1 : AppSpacing.md)
                          .colour(textStyle?.color ?? colors.white)
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
                    horizontal: isCompact ? AppSpacing.sm : AppSpacing.sm + 2,
                    vertical: isCompact ? AppSpacing.xs / 2 : AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.smRadius,
                  ),
                  child: Text(
                    actionLabel!,
                    style:
                        (isCompact
                                ? context.textTheme.labelSmall?.bold()
                                : context.textTheme.labelMedium?.bold())
                            ?.colour(style.actionColor ?? colors.white),
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
                borderRadius: AppRadius.fullRadius,
                child: Padding(
                  padding: EdgeInsets.all(
                    isCompact ? AppSpacing.xs / 2 : AppSpacing.xs,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: isCompact ? AppSpacing.md : AppSpacing.lg,
                    color: colors.white.withValues(alpha: 0.8),
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
