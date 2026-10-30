import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final String? Function(T?)? validator;
  final BorderSide borderSide;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? dropdownColor;
  final Color? iconColor;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.borderSide = const BorderSide(
      color: Color(0xFFE0E0E0),
    ), // Colors.grey.shade300
    this.borderRadius = 12.0,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 14,
    ),
    this.textStyle,
    this.hintStyle,
    this.dropdownColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: dropdownColor,
      style:
          textStyle ??
          context.textTheme.bodySmall?.copyWith(color: AppColors.blackColor),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: iconColor ?? AppColors.blackColor.withValues(alpha: 0.5),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            hintStyle ??
            context.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: AppColors.hintTextFieldColor,
            ),
        filled: true,
        fillColor: AppColors.fillColor,
        contentPadding: contentPadding,
        prefixIconConstraints: prefixIcon != null
            ? const BoxConstraints(minWidth: 45, minHeight: 45)
            : null,
        prefixIcon: prefixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: AppColors.secondary, width: 1),
        ),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
