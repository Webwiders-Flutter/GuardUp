import 'package:flutter/material.dart';
import 'package:flutter_dotted/flutter_dotted.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class UploadViewWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const UploadViewWidget({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: FlutterDotted(
              gap: 5,
              color: AppColors.secondary.withValues(alpha: 0.3),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 35,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Container(
                    //   padding: const EdgeInsets.all(10),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.secondary.withValues(alpha: 0.2),
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    //   child: const Icon(
                    //     Icons.upload,
                    //     color: AppColors.secondary,
                    //     size: 30,
                    //   ),
                    // ),
                    Image.asset(
                      "assets/icons/upload_square_solid_icon.png",
                      height: 50,
                      width: 50,
                      fit: BoxFit.contain,
                    ),
                    15.height,
                    AppText(
                      text,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: AppColors.headingTextFieldColor,
                      textAlign: TextAlign.center,
                    ),
                    30.height,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: AppColors.secondary,
                        ),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      child: AppText(
                        context.l10n.chooseFile,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: AppColors.secondary,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
