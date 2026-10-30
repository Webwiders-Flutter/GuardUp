import 'package:flutter/material.dart';

class AppColors {
  // static const Color primary = Color(0xFF081026);
  static const Color primary = Color(0xFFDEA641);
  static const Color secondary = Color(0xFFDEA641);
  static const Color mainBackgroundColor = Color(0xFF081026);
  static const Color lightBackgroundColor = Color(0xFF132030);
  static const Color primaryLight = Color(0xFFFF7290);
  static const Color primaryDark = Color(0xFF8E0038);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF6F6F6);
  static const Color surfaceLight = Colors.white;
  static const Color blackColor = Color(0xff000000);
  static const Color greyColor = Colors.grey;

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color fillColor = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textHintLight = Color(0xFFBDBDBD);

  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Specifics from Figma
  static const Color inputFill = Color(0xFFF8F8F8);
  static const Color divider = Color(0xFFEEEEEE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bottom Navigation
  static const Color whiteColor = Colors.white;
  static const Color bottomNavBackground = Color(0xFFF9F1F1);
  static const Color headingTextFieldColor = Color(0xFFABABAB);
  static const Color hintTextFieldColor = Color(0xFF7B7B7B);
  static const Color colorC9C9C9 = Color(0xFFC9C9C9);
  static const Color color132030 = Color(0xFF132030);
  static const Color color081026 = Color(0xFF081026);
  static const Color color8D8D8D = Color(0xFF8D8D8D);
  static const Color color525252 = Color(0xFF525252);
  static const Color colorFF8D28 = Color(0xFFFF8D28);
  static const Color color0088FF = Color(0xFF0088FF);
  static const Color color34C759 = Color(0xFF34C759);
  static const Color colorAAA6B9 = Color(0xFFAAA6B9);
  static const Color colorDEA641 = Color(0xFFDEA641);
}
