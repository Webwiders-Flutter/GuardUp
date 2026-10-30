import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/features/auth/presentation/bloc/auth_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackgroundColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordRecoveryState) {
            context.go(AppRouter.createNewPassword);
            return;
          }
          if (state is AuthenticatedState) {
            // final currentRoute =
            //     AppRouter.router.routerDelegate.currentConfiguration.uri.path;

            // final user = state.user;

            context.go(AppRouter.dashboardScreen);

            // sl<GetProfileUseCase>().call(state.user.id).then((result) {
            //   if (context.mounted) {
            //     result.fold(
            //       (failure) => context.go(AppRouter.dashboardScreen),
            //       (fullProfile) {
            //         if (fullProfile.interests.isEmpty &&
            //             fullProfile.preferredDestinations.isEmpty) {
            //           context.go(AppRouter.preferencesOnboarding);
            //         } else {
            //           context.go(AppRouter.dashboardScreen);
            //         }
            //       },
            //     );
            //   }
            // });
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            100.height,
            Center(
              child: Image.asset(
                height: 185,
                width: 253,
                fit: BoxFit.contain,
                AppAssets.appLogo,
              ),
            ),

            Expanded(
              child: Center(
                child: Image.asset(
                  height: 279,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  AppAssets.backgroundImage,
                ),
              ),
            ),
            Image.asset(
              height: 175,
              width: double.infinity,
              fit: BoxFit.contain,
              AppAssets.splashImage,
            ),
          ],
        ),
      ),
    );
  }
}
