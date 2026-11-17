import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '../../../../core/extensions/localization.extension.dart';

import '/app/theme/colors/color_accessor.dart';
import '/core/constants/app_durations.dart';
import '/core/constants/app_spacing.dart';
import '../../../../core/extensions/context.extension.dart';
import '../../../../core/extensions/spacing.extension.dart';
import '../../../../core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../inputs/app_media_picker_sheet.dart';

enum AppSheetHeaderAction { none, close, back }

final class AppSheet {
  AppSheet._();

  static Future<XFile?> showMediaPicker({
    required BuildContext context,
    bool isVideo = false,
  }) {
    return AppSheet.show<XFile?>(
      title: isVideo ? context.l10n.selectAVideo : context.l10n.selectAnImage,
      subtitle: isVideo
          ? context.l10n.chooseFromYourVideoLibraryOrTakeAVideo
          : context.l10n.chooseFromYourGalleryOrTakeAPhoto,
      // action: AppSheetHeaderAction.back,
      context: context,
      child: AppMediaPickerSheet(isVideo: isVideo),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    AppSheetHeaderAction action = AppSheetHeaderAction.none,
    bool showHandle = true,
    bool showHeader = true,
    bool isDismissible = true,
    bool isScrollControlled = true,
    bool useSafeArea = true,
    bool centerTitle = true,
    double borderRadius = 28,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? barrierColor,
    Widget? bottom,
    double? maxHeight,
    VoidCallback? onActionTap,
  }) {
    final theme = context.colors;

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: theme.transparent,
      barrierColor: barrierColor ?? theme.onSurface.withValues(alpha: 0.25),

      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);

        return AnimatedPadding(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: QuickContainer(
              maxH: maxHeight ?? mediaQuery.size.height * 0.92,
              color: backgroundColor ?? theme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(2 * AppSpacing.md),
              ),
              px: context.horizontalScreenPadding,
              pb: 2.hPercent(context),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle) ...[
                    AppSpacing.md.h,
                    QuickContainer(
                      w: AppSpacing.xxxl + AppSpacing.lg,
                      h: AppSpacing.xs,
                      color: theme.onSurfaceSecondary,
                      radius: AppRadius.full,
                    ),
                  ],

                  if (showHeader) ...[
                    AppSpacing.sm.h,
                    _SheetHeader(
                      title: title,
                      subtitle: subtitle,
                      isCenter: centerTitle,
                      leadingAction: action,
                      onLeadingPressed: onActionTap,
                    ),
                  ],
                  AppSpacing.sm.h,

                  Flexible(
                    child: SingleChildScrollView(
                      padding: padding ?? AppSpacing.xl.bPadding,
                      child: child,
                    ),
                  ),

                  ?bottom,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

final class _SheetHeader extends StatelessWidget {
  final String? title;
  final bool isCenter;
  final String? subtitle;
  final AppSheetHeaderAction leadingAction;
  final VoidCallback? onLeadingPressed;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.isCenter,
    required this.leadingAction,
    required this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBack = leadingAction == AppSheetHeaderAction.back;
    final bool hasClose = leadingAction == AppSheetHeaderAction.close;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasBack) ...[
          _button(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onLeadingPressed ?? () => context.pop(),
            theme: context.colors,
          ),
          AppSpacing.md.w,
        ] else if (isCenter && hasClose) ...[
          (AppSpacing.xxl + AppSpacing.xl - 2).w,
          AppSpacing.md.w,
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: isCenter
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  textAlign: isCenter ? TextAlign.center : TextAlign.start,
                  style: context.textTheme.headlineSmall?.decreaseSize(2),
                ),

              if (subtitle != null) ...[
                (AppSpacing.xs / 2).h,
                Text(
                  subtitle!,
                  textAlign: isCenter ? TextAlign.center : TextAlign.start,
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (hasClose) ...[
          AppSpacing.md.w,
          _button(
            icon: Icons.close,
            onPressed: onLeadingPressed ?? () => context.pop(),
            theme: context.colors,
          ),
        ] else if (isCenter && hasBack) ...[
          AppSpacing.md.w,
          (AppSpacing.xxl + AppSpacing.xl - 2).w,
        ],
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required VoidCallback onPressed,
    required AppThemeAccessor theme,
  }) {
    return AppButton(
      icon: icon,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      elevation: 0,
      width: AppSpacing.xxxl - 2,
      backgroundColor: theme.transparent,
      foregroundColor: theme.onSurface,
      borderRadius: AppRadius.fullRadius,
      fullWidth: false,
    );
  }
}
