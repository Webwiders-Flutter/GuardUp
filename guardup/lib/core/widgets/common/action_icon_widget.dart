import 'package:flutter/material.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class ActionIconWidget extends StatelessWidget {
  final IconData icon;
  final String? image;
  final String label;
  final VoidCallback? onTap;
  final Color iconColor;
  final double? iconSize;

  const ActionIconWidget({
    super.key,
    required this.icon,
    this.image,
    this.iconSize,
    required this.label,
    this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          image != null
              ? Image.asset(
                  image!,
                  color: iconColor,
                  width: iconSize ?? 28,
                  height: iconSize ?? 28,
                )
              : Icon(icon, color: iconColor, size: iconSize ?? 30),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            AppText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}

class CommentIconWidget extends StatelessWidget {
  final IconData label;
  final VoidCallback? onTap;
  final double? size;

  const CommentIconWidget({
    super.key,
    required this.label,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white, width: 0.5),
            ),
            child: Icon(label, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
