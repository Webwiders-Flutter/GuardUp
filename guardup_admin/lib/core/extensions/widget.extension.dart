import 'package:flutter/material.dart';

import '../../shared/widgets/feedbacks/widgets/app_dialog.dart';
import '../../shared/widgets/feedbacks/widgets/app_sheet.dart';

/// Extension on [Widget] allowing any widget to be presented directly
/// as a modern bottom sheet ([showSheet]) or modal dialog ([showDialog]).
extension WidgetFeedbackExtension on Widget {
  /// Presents this widget in a modern bottom sheet using [AppSheet].
  Future<T?> showSheet<T>(
    BuildContext context, {
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
    return AppSheet.show<T>(
      context: context,
      child: this,
      title: title,
      subtitle: subtitle,
      action: action,
      showHandle: showHandle,
      showHeader: showHeader,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      centerTitle: centerTitle,
      borderRadius: borderRadius,
      padding: padding,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      bottom: bottom,
      maxHeight: maxHeight,
      onActionTap: onActionTap,
    );
  }

  /// Presents this widget in a modern modal dialog using [AppDialogs].
  Future<T?> showDialog<T>(
    BuildContext context, {
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
    return AppDialogs.show<T>(
      context: context,
      child: this,
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: trailing,
      action: action,
      showHeader: showHeader,
      isDismissible: isDismissible,
      barrierDismissible: barrierDismissible,
      blurBackground: blurBackground,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      padding: padding,
      backgroundColor: backgroundColor,
      barrierColor: barrierColor,
      bottom: bottom,
      onActionTap: onActionTap,
    );
  }
}
