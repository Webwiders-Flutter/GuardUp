import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:guardup/core/constants/app_assets.dart';
import 'package:guardup/core/network/connectivity_bloc.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';
import 'package:guardup/core/utils/extensions/size_extensions.dart';
import 'package:guardup/core/widgets/common/gradient_button.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.colorScheme.surface,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            AppAssets.noInternetAnimation,
            width: 250,
            height: 250,
            fit: BoxFit.contain,
          ),
          40.height,
          Text(
            context.l10n.noInternetTitle,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          16.height,
          Text(
            context.l10n.noInternetDesc,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          60.height,
          GradientButton(
            text: context.l10n.noInternetButton,
            onPressed: () {
              context.read<ConnectivityBloc>().add(ConnectivityStarted());
            },
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }
}
