import 'package:flutter/material.dart';

import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: AppImage.asset(
          assetPath: Assets.images.splash.path,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
