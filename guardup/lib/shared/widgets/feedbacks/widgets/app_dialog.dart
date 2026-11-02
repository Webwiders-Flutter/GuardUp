import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_durations.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/number.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';

enum AppDialogHeaderAction { none, close, back }

/// Standardized enterprise dialog framework mirroring [AppSheet] for modal dialogs.
///
/// Provides:
/// - Smooth backdrop blur & cubic entrance transition
/// - Responsive max-width & max-height constraints
/// - Standardized header, scrollable body, and action footer
/// - Document preview helper ([AppDialogs.showDocumentPreview])
/// - Raw dialog builder ([AppDialogs.showRaw])
final class AppDialogs {
  AppDialogs._();

  /// Displays a standardized modal dialog with optional header, scrollable body,
  /// and bottom action area.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    Widget? icon,
    Widget? trailing,
    AppDialogHeaderAction action = AppDialogHeaderAction.close,
    bool showHeader = true,
    bool isDismissible = true,
    bool barrierDismissible = true,
    bool blurBackground = true,
    double maxWidth = 540,
    double? maxHeight,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? barrierColor,
    Widget? bottom,
    VoidCallback? onActionTap,
  }) {
    final colors = context.colors;

    return showRaw<T>(
      context: context,
      barrierDismissible: barrierDismissible && isDismissible,
      barrierColor: barrierColor ?? colors.black.withValues(alpha: 0.40),
      blurBackground: blurBackground,
      child: Builder(
        builder: (dialogContext) {
          final mediaQuery = MediaQuery.of(dialogContext);
          final responsiveMaxWidth = mediaQuery.size.width < maxWidth
              ? mediaQuery.size.width * 0.94
              : maxWidth;
          final responsiveMaxHeight =
              maxHeight ?? mediaQuery.size.height * 0.88;

          return Dialog(
            backgroundColor: colors.transparent,
            surfaceTintColor: colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: QuickContainer(
              maxW: responsiveMaxWidth,
              maxH: responsiveMaxHeight,
              color: backgroundColor ?? colors.surface,
              radius: AppRadius.lg,
              border: Border.all(color: colors.borderLight, width: 1),
              shadows: [
                BoxShadow(
                  color: colors.black.withValues(alpha: 0.15),
                  blurRadius: AppSpacing.xxl,
                  offset: const Offset(0, 10),
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────
                  if (showHeader)
                    _DialogHeader(
                      title: title,
                      subtitle: subtitle,
                      icon: icon,
                      trailing: trailing,
                      action: action,
                      onActionTap:
                          onActionTap ??
                          () => Navigator.of(dialogContext).pop(),
                    ),

                  // ── Body ───────────────────────────────────────────
                  Flexible(
                    child: SingleChildScrollView(
                      padding: padding ?? AppSpacing.lg.allPadding,
                      child: child,
                    ),
                  ),

                  // ── Optional Bottom Footer ─────────────────────────
                  if (bottom != null) ...[
                    Divider(height: 1, color: colors.borderLight),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: bottom,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Displays a raw dialog with backdrop blur and entrance animation, giving
  /// the caller full control over the inner layout (used by [AppPopup]).
  static Future<T?> showRaw<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool blurBackground = true,
    Duration duration = AppDurations.fast,
  }) {
    final colors = context.colors;

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dialog',
      barrierColor: barrierColor ?? colors.black.withValues(alpha: 0.40),
      transitionDuration: duration,
      pageBuilder: (dialogContext, _, _) => Stack(
        children: [
          if (blurBackground)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const SizedBox.expand(),
              ),
            ),
          child,
        ],
      ),
      transitionBuilder: (_, anim, _, dialogChild) {
        final curvedAnim = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curvedAnim),
            child: dialogChild,
          ),
        );
      },
    );
  }
}

/// Alias for [AppDialogs] for ergonomics.
typedef AppDialog = AppDialogs;

/// Standardized dialog header widget.
class _DialogHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;
  final AppDialogHeaderAction action;
  final VoidCallback onActionTap;

  const _DialogHeader({
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    required this.action,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[icon!, AppSpacing.sm.w],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty)
                  Text(
                    title!,
                    style: context.textTheme.titleMedium?.semiBold().colour(
                      colors.onSurface,
                    ),
                  ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  AppSpacing.xxs.h,
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall?.colour(
                      colors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[AppSpacing.sm.w, trailing!],
          if (action != AppDialogHeaderAction.none) ...[
            AppSpacing.xs.w,
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: onActionTap,
                borderRadius: AppRadius.full.toBorderRadius,
                child: Container(
                  padding: AppSpacing.xs.allPadding,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action == AppDialogHeaderAction.close
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    size: AppSizes.iconMd,
                    color: colors.onSurfaceSecondary,
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
