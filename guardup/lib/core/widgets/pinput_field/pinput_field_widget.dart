import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:guardup/core/constants/app_colors.dart';

class PinputFieldWidget extends StatelessWidget {
  final TextEditingController pinController;
  final int length;
  const PinputFieldWidget({
    super.key,
    required this.pinController,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Pinput(
        length: length,
        controller: pinController,
        separatorBuilder: (index) => const SizedBox(width: 8),
        hapticFeedbackType: HapticFeedbackType.lightImpact,

        defaultPinTheme: PinTheme(
          width: 50,
          height: 56,

          textStyle: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),

          decoration: BoxDecoration(
            color: AppColors.fillColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),

        focusedPinTheme: PinTheme(
          width: 75,
          height: 56,

          textStyle: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),

          decoration: BoxDecoration(
            color: AppColors.fillColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),

        submittedPinTheme: PinTheme(
          width: 65,
          height: 50,

          textStyle: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),

          decoration: BoxDecoration(
            color: AppColors.fillColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),

            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),

        onCompleted: (pin) {
          debugPrint('onCompleted: $pin');
        },

        onChanged: (value) {
          debugPrint('onChanged: $value');
        },
      ),
    );
  }
}
