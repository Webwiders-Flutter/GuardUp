import 'package:flutter/material.dart';
import 'package:guardup/core/constants/enums/visa_application_status.dart';

class StatusBadge extends StatelessWidget {
  final VisaApplicationStatus status;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.getLabel(context).toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
