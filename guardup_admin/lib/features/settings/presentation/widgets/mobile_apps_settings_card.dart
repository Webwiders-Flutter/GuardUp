import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_text_field.dart';
import '/shared/widgets/sections/info_banner.dart';

/// Card for configuring mobile application release versions, update messages, and store links.
class MobileAppsSettingsCard extends StatelessWidget {
  final GlobalKey<FormState>? formKey;

  // iOS Controllers
  final TextEditingController latestIosVersionController;
  final TextEditingController minimumIosVersionController;
  final TextEditingController iosUpdateMessageController;
  final TextEditingController iosAppUrlController;

  // Android Controllers
  final TextEditingController latestAndroidVersionController;
  final TextEditingController minimumAndroidVersionController;
  final TextEditingController androidUpdateMessageController;
  final TextEditingController androidAppUrlController;

  final VoidCallback onChanged;

  const MobileAppsSettingsCard({
    super.key,
    this.formKey,
    required this.latestIosVersionController,
    required this.minimumIosVersionController,
    required this.iosUpdateMessageController,
    required this.iosAppUrlController,
    required this.latestAndroidVersionController,
    required this.minimumAndroidVersionController,
    required this.androidUpdateMessageController,
    required this.androidAppUrlController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Side-by-side or stacked platform cards
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildIosCard(context)),
                    AppSpacing.xl.w,
                    Expanded(child: _buildAndroidCard(context)),
                  ],
                )
              else ...[
                _buildIosCard(context),
                AppSpacing.lg.h,
                _buildAndroidCard(context),
              ],

              AppSpacing.xl.h,

              // Informational Architecture Guide Box
              InfoBanner(
                heading: 'Version Enforcement Mechanics',
                iconData: Icons.info_outline_rounded,
                color: colors.primary,
                descriptionOverride: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBulletItem(
                      context,
                      title: 'Minimum Version',
                      description: 'Any client running below this version is strictly blocked and prompted to update using the configured update message.',
                    ),
                    _buildBulletItem(
                      context,
                      title: 'Latest Version',
                      description: 'Clients between the Minimum and Latest version will see a non-blocking "Update Available" reminder banner.',
                    ),
                    _buildBulletItem(
                      context,
                      title: 'Update Message',
                      description: 'Custom announcement shown to users on the update screen explaining why an update is recommended or required.',
                    ),
                    _buildBulletItem(
                      context,
                      title: 'Store URLs',
                      description: 'Users tapping "Update Now" will be automatically redirected to the provided Apple App Store or Google Play Store links.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulletItem(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: context.textTheme.bodySmall
                    ?.colour(colors.onSurfaceSecondary)
                    .lineHeight(1.45),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: context.textTheme.bodySmall?.semiBold().colour(
                      colors.onSurface,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosCard(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.black.withValues(alpha: 0.06),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  Icons.apple_rounded,
                  size: AppSpacing.xxl,
                  color: colors.black,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apple iOS App',
                      style: context.textTheme.titleMedium?.semiBold().colour(
                        colors.onSurface,
                      ),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      'App Store distribution & release policy',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.xl.h,

          // Version inputs in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      text: 'Latest Version',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: latestIosVersionController,
                      validator: (value) => Validators.version(
                        context,
                        value,
                        fieldName: 'Latest iOS Version',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1.2.0',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      text: 'Minimum Version',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: minimumIosVersionController,
                      validator: (value) => Validators.version(
                        context,
                        value,
                        fieldName: 'Minimum iOS Version',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1.0.0',
                        prefixIcon: Icon(Icons.lock_clock_rounded),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.lg.h,

          // iOS Update Message
          const AppFieldLabel(
            text: 'Update Message / Release Notes',
            isRequired: true,
          ),
          AppSpacing.xs.h,
          AppTextField(
            controller: iosUpdateMessageController,
            maxLines: 3,
            validator: (value) => Validators.required(
              context,
              value,
              fieldName: 'iOS Update Message',
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. A new version of the app is available. Please update to continue using Supplr.',
              prefixIcon: Icon(Icons.announcement_outlined),
            ),
            onChanged: (_) => onChanged(),
          ),

          AppSpacing.lg.h,

          // App Store URL with launch test button
          const AppFieldLabel(text: 'Apple App Store URL', isRequired: false),
          AppSpacing.xs.h,
          AppTextField(
            controller: iosAppUrlController,
            validator: (value) => Validators.url(
              context,
              value,
              isOptional: true,
              fieldName: 'Apple App Store URL',
            ),
            decoration: const InputDecoration(
              hintText: 'https://apps.apple.com/app/...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            onChanged: (_) => onChanged(),
          ),
          AppSpacing.sm.h,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: 'Test App Store Link',
              fullWidth: false,
              type: ButtonType.text,
              size: ButtonSize.small,
              leading: const Icon(
                Icons.open_in_new_rounded,
                size: AppSpacing.md,
              ),
              onPressed: () {
                final url = iosAppUrlController.text.trim();
                if (url.isNotEmpty) {
                  AppLauncher.openWebsite(url);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidCard(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  Icons.android_rounded,
                  size: AppSpacing.xxl,
                  color: colors.success,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Android App',
                      style: context.textTheme.titleMedium?.semiBold().colour(
                        colors.onSurface,
                      ),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      'Google Play Store distribution & release policy',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.xl.h,

          // Version inputs in a row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      text: 'Latest Version',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: latestAndroidVersionController,
                      validator: (value) => Validators.version(
                        context,
                        value,
                        fieldName: 'Latest Android Version',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1.2.0',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      text: 'Minimum Version',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: minimumAndroidVersionController,
                      validator: (value) => Validators.version(
                        context,
                        value,
                        fieldName: 'Minimum Android Version',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 1.0.0',
                        prefixIcon: Icon(Icons.lock_clock_rounded),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AppSpacing.lg.h,

          // Android Update Message
          const AppFieldLabel(
            text: 'Update Message / Release Notes',
            isRequired: true,
          ),
          AppSpacing.xs.h,
          AppTextField(
            controller: androidUpdateMessageController,
            maxLines: 3,
            validator: (value) => Validators.required(
              context,
              value,
              fieldName: 'Android Update Message',
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. A new version of the app is available. Please update to continue using Supplr.',
              prefixIcon: Icon(Icons.announcement_outlined),
            ),
            onChanged: (_) => onChanged(),
          ),

          AppSpacing.lg.h,

          // Play Store URL with launch test button
          const AppFieldLabel(text: 'Google Play Store URL', isRequired: false),
          AppSpacing.xs.h,
          AppTextField(
            controller: androidAppUrlController,
            validator: (value) => Validators.url(
              context,
              value,
              isOptional: true,
              fieldName: 'Google Play Store URL',
            ),
            decoration: const InputDecoration(
              hintText: 'https://play.google.com/store/apps/...',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            onChanged: (_) => onChanged(),
          ),
          AppSpacing.sm.h,
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: 'Test Play Store Link',
              type: ButtonType.text,
              fullWidth: false,
              size: ButtonSize.small,
              leading: const Icon(
                Icons.open_in_new_rounded,
                size: AppSpacing.md,
              ),
              onPressed: () {
                final url = androidAppUrlController.text.trim();
                if (url.isNotEmpty) {
                  AppLauncher.openWebsite(url);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
