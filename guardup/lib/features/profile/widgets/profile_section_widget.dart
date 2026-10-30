import 'package:flutter/material.dart';
import 'package:guardup/core/constants/app_colors.dart';

class ProfileStatItem extends StatelessWidget {
  final String count;
  final String title;

  const ProfileStatItem({super.key, required this.count, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.headingTextFieldColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.color8D8D8D,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
