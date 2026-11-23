import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/features/settings/data/models/admin_settings.model.dart';
import '/features/settings/di/admin_settings.providers.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/misc/app_logo.dart';

/// Public, unauthenticated download landing screen for the GuardUp mobile app.
///
/// Route: `/download`
///
/// Serves as the fallback landing page when a user opens `https://<domain>/download`
/// on desktop, or on a mobile device where the app is not yet installed.
///
/// Dynamically reads live Play Store and App Store URLs from [adminSettingsControllerProvider].
class PublicDownloadScreen extends ConsumerWidget {
  /// Route path of this screen.
  static const route = '/download';

  const PublicDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settingsAsync = ref.watch(adminSettingsControllerProvider);
    final settings = settingsAsync.value ?? AdminSettingsModel.initial();

    final androidUrl = settings.androidAppUrl?.trim() ?? '';
    final iosUrl = settings.iosAppUrl?.trim() ?? '';

    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Scaffold(
      backgroundColor: colors.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxxl,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.xlRadius,
                border: Border.all(
                  color: colors.borderLight.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Logo
                  const AppLogo(size: 80),
                  AppSpacing.lg.h,

                  // App Title
                  Text(
                    'GuardUp',
                    style: context.textTheme.headlineMedium?.bold().colour(
                      colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.xs.h,

                  // Tagline & Description
                  Text(
                    'Personal security and verified bodyguard protection at your fingertips.',
                    style: context.textTheme.bodyMedium?.colour(
                      colors.onSurfaceSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.xxl.h,

                  // Google Play Store Button
                  if (isIOS)
                    _buildAppStoreButton(context, iosUrl, isPrimary: true)
                  else
                    _buildPlayStoreButton(context, androidUrl, isPrimary: true),

                  AppSpacing.md.h,

                  if (isIOS)
                    _buildPlayStoreButton(
                      context,
                      androidUrl,
                      isPrimary: false,
                    )
                  else
                    _buildAppStoreButton(context, iosUrl, isPrimary: false),

                  AppSpacing.xl.h,

                  // Sub-caption
                  Text(
                    'Available for iOS and Android devices.',
                    style: context.textTheme.bodySmall?.colour(
                      colors.onSurfaceSecondary.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayStoreButton(
    BuildContext context,
    String url, {
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return AppButton.fill(
        text: 'Download on Google Play',
        icon: Icons.android_rounded,
        size: ButtonSize.medium,
        fullWidth: true,
        onPressed: url.isNotEmpty ? () => AppLauncher.openWebsite(url) : null,
      );
    }
    return AppButton.outline(
      text: 'Download on Google Play',
      icon: Icons.android_rounded,
      type: ButtonType.secondaryOff,
      size: ButtonSize.medium,
      fullWidth: true,
      onPressed: url.isNotEmpty ? () => AppLauncher.openWebsite(url) : null,
    );
  }

  Widget _buildAppStoreButton(
    BuildContext context,
    String url, {
    required bool isPrimary,
  }) {
    if (isPrimary) {
      return AppButton.fill(
        text: 'Download on App Store',
        icon: Icons.apple_rounded,
        size: ButtonSize.medium,
        fullWidth: true,
        onPressed: url.isNotEmpty ? () => AppLauncher.openWebsite(url) : null,
      );
    }
    return AppButton.outline(
      text: 'Download on App Store',
      icon: Icons.apple_rounded,
      type: ButtonType.secondaryOff,
      size: ButtonSize.medium,
      fullWidth: true,
      onPressed: url.isNotEmpty ? () => AppLauncher.openWebsite(url) : null,
    );
  }
}
