import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/app_text/app_text.dart';

class UploadedFileItemWidget extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const UploadedFileItemWidget({
    super.key,
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          context.pushNamed(
            AppRouter.documentViewer,
            extra: {
              'url': file.path,
              'title': file.path.split('/').last,
              'isFile': true,
            },
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
          decoration: BoxDecoration(
            color: AppColors.color132030,
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(color: AppColors.color525252, width: 0.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                height: 40,
                width: 40,
                fit: BoxFit.contain,
                AppAssets.globalIcon02,
              ),
              15.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      file.path.split('/').last,
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: AppColors.headingTextFieldColor,
                    ),
                    AppText(
                      "${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB",
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: AppColors.headingTextFieldColor,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close,
                  color: AppColors.whiteColor,
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
