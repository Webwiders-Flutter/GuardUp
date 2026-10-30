import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? leadingWidth;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.showBackButton = false,
    this.flexibleSpace,
    this.bottom,
    this.backgroundColor = AppColors.mainBackgroundColor,
    this.titleColor,
    this.leadingWidth,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      leadingWidth: leadingWidth,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      title:
          titleWidget ??
          Text(
            title ?? '',
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleLarge?.copyWith(
              color: titleColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
      actions: actions,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton &&
        (Navigator.of(context).canPop() || onBackPressed != null)) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: titleColor ?? AppColors.whiteColor,
        ),
        onPressed: () {
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return null;
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
