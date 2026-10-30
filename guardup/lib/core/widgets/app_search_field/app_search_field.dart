import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;

  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Center(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: AppColors.blackColor, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.whiteColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.headingTextFieldColor,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.headingTextFieldColor,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }
}
