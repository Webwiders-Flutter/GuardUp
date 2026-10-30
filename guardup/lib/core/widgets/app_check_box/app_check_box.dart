import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';

class CustomCheckBox extends StatelessWidget {
  final bool value;

  final Function(bool?) onChanged;

  const CustomCheckBox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        height: 20,
        width: 20,
        decoration: BoxDecoration(
          color: value ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.secondary, width: 1.5),
        ),
        alignment: Alignment.center,
        child: value
            ? Image.asset(AppAssets.doubleIcon, height: 15, width: 15)
            : null,
      ),
    );
  }
}
