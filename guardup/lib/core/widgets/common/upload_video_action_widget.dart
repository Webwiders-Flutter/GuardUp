import 'package:flutter/material.dart';

class UploadVideoActionWidget extends StatelessWidget {
  final VoidCallback onTap;

  const UploadVideoActionWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        width: 45,
        margin: EdgeInsets.only(bottom: 25),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.3, -0.3),
            radius: 1.1,
            colors: [
              Color(0xFFFFE9A8), // Highlight
              Color(0xFFDEA641), // Main gold
              Color(0xFFC68A24), // Dark edge
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDEA641).withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
  // Widget build(BuildContext context) {
  //   return Positioned(
  //     right: 12,
  //     bottom: 40,
  //     child: GestureDetector(
  //       onTap: onTap,
  //       child: Container(
  //         height: 45,
  //         width: 45,
  //         decoration: BoxDecoration(
  //           color: AppColors.secondary,
  //           shape: BoxShape.circle,
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withValues(alpha: 0.3),
  //               blurRadius: 10,
  //               offset: const Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //         child: const Icon(Icons.add, size: 30, color: Colors.white),
  //       ),
  //     ),
  //   );
  // }
}
