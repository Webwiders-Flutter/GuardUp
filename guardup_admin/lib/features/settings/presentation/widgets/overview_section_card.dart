import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/shared/widgets/buttons/app_button.dart';
import '../../data/models/admin_settings.model.dart';
import '../models/settings_section.enum.dart';

/// Executive overview card displaying a high-level snapshot of all platform settings.
class OverviewSectionCard extends StatelessWidget {
  final AdminSettingsModel settings;
  final ValueChanged<SettingsSection> onNavigateToSection;

  const OverviewSectionCard({
    super.key,
    required this.settings,
    required this.onNavigateToSection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Maintenance Status Hero Card ──
            _buildMaintenanceHero(context),

            AppSpacing.xl.h,

            // ── Section 2: Mobile Apps Snapshot & Support Snapshot ──
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildMobileAppsSnapshot(context)),
                  AppSpacing.xl.w,
                  Expanded(child: _buildSupportSnapshot(context)),
                ],
              )
            else ...[
              _buildMobileAppsSnapshot(context),
              AppSpacing.lg.h,
              _buildSupportSnapshot(context),
            ],

            AppSpacing.xl.h,

            // ── Section 3: Platform Fees Snapshot ──
            _buildPlatformFeesSnapshot(context),

            AppSpacing.xl.h,
          ],
        );
      },
    );
  }

  Widget _buildMaintenanceHero(BuildContext context) {
    final colors = context.colors;
    final isMaintenance = settings.isUnderMaintenance;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: isMaintenance
          ? colors.error.withValues(alpha: 0.05)
          : colors.success.withValues(alpha: 0.05),
      border: Border.all(
        color: isMaintenance
            ? colors.error.withValues(alpha: 0.3)
            : colors.success.withValues(alpha: 0.3),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isMaintenance
                      ? colors.error.withValues(alpha: 0.15)
                      : colors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMaintenance
                      ? Icons.warning_amber_rounded
                      : Icons.verified_user_outlined,
                  size: AppSpacing.xxl,
                  color: isMaintenance ? colors.error : colors.success,
                ),
              ),
              AppSpacing.lg.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMaintenance
                          ? 'Emergency Maintenance Active'
                          : 'Platform Operating Normally',
                      style: context.textTheme.titleSmall?.bold().colour(
                        isMaintenance ? colors.error : colors.success,
                      ),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      isMaintenance
                          ? (settings.maintenanceTitle ??
                                'App Under Maintenance')
                          : 'Customer apps, bodyguard personnel & security companies are live.',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.md.w,
              // Switch
              AppButton(
                fullWidth: false,
                text: 'Manage Maintenance Notice',
                type: ButtonType.secondaryOff,
                size: ButtonSize.small,
                leading: const Icon(Icons.edit_rounded, size: AppSpacing.md),
                onPressed: () => onNavigateToSection(SettingsSection.core),
              ),
            ],
          ),

          if (isMaintenance &&
              settings.maintenanceMessage?.trim().isNotEmpty == true) ...[
            AppSpacing.md.h,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(color: colors.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                settings.maintenanceMessage!,
                style: context.textTheme.bodySmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileAppsSnapshot(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                size: AppSpacing.xl,
                color: colors.primary,
              ),
              AppSpacing.md.w,
              Expanded(
                child: Text(
                  'Mobile Releases',
                  style: context.textTheme.titleMedium?.semiBold().colour(
                    colors.onSurface,
                  ),
                ),
              ),
              AppButton(
                fullWidth: false,
                text: 'Edit',
                type: ButtonType.text,
                size: ButtonSize.small,
                onPressed: () =>
                    onNavigateToSection(SettingsSection.mobileApps),
              ),
            ],
          ),

          AppSpacing.lg.h,

          // iOS Row
          _buildReleaseRow(
            context,
            icon: Icons.apple_rounded,
            platformName: 'Apple iOS',
            latestVersion: settings.latestIosVersion,
            minVersion: settings.minimumIosVersion,
            updateMessage: settings.updateMessageIos,
            url: settings.iosAppUrl,
          ),

          AppSpacing.md.h,
          const Divider(height: 1),
          AppSpacing.md.h,

          // Android Row
          _buildReleaseRow(
            context,
            icon: Icons.android_rounded,
            platformName: 'Google Android',
            latestVersion: settings.latestAndroidVersion,
            minVersion: settings.minimumAndroidVersion,
            updateMessage: settings.updateMessageAndroid,
            url: settings.androidAppUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseRow(
    BuildContext context, {
    required IconData icon,
    required String platformName,
    required String latestVersion,
    required String minVersion,
    String? updateMessage,
    String? url,
  }) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.xxl, color: colors.onSurface),
        AppSpacing.md.w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platformName,
                style: context.textTheme.bodyMedium?.semiBold().colour(
                  colors.onSurface,
                ),
              ),
              AppSpacing.xs.h,
              Text(
                'Latest: v$latestVersion • Minimum: v$minVersion',
                style: context.textTheme.bodySmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
              if (updateMessage != null && updateMessage.trim().isNotEmpty) ...[
                AppSpacing.xs.h,
                Text(
                  updateMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.colour(
                    colors.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (url != null && url.isNotEmpty)
          AppButton.outline(
            size: .small,
            type: .primary,
            tooltip: 'Open Store Page',
            icon: Icons.open_in_new_rounded,
            onPressed: () => AppLauncher.openWebsite(url),
          ),
      ],
    );
  }

  Widget _buildSupportSnapshot(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                size: AppSpacing.xl,
                color: colors.secondary,
              ),
              AppSpacing.md.w,
              Expanded(
                child: Text(
                  'Support & Help Desk',
                  style: context.textTheme.titleMedium?.semiBold().colour(
                    colors.onSurface,
                  ),
                ),
              ),
              AppButton(
                fullWidth: false,
                text: 'Edit',
                type: ButtonType.text,
                size: ButtonSize.small,
                onPressed: () => onNavigateToSection(SettingsSection.support),
              ),
            ],
          ),

          AppSpacing.lg.h,

          // Email
          _buildSupportItem(
            context,
            icon: Icons.mail_outline_rounded,
            label: 'Support Email',
            value: settings.supportEmail,
            onTap: () => AppLauncher.sendEmail(email: settings.supportEmail),
          ),

          AppSpacing.md.h,

          // Voice Call
          _buildSupportItem(
            context,
            icon: Icons.phone_outlined,
            label: 'Helpline Phone',
            value: settings.supportCallPhoneNumber,
            onTap: () => AppLauncher.callPhone(settings.supportCallPhoneNumber),
          ),

          AppSpacing.md.h,

          // WhatsApp
          _buildSupportItem(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp Support',
            value: settings.supportWhatsappPhoneNumber,
            onTap: () => AppLauncher.openWhatsApp(
              phone: settings.supportWhatsappPhoneNumber,
            ),
          ),

          if (settings.supportHours != null &&
              settings.supportHours!.isNotEmpty) ...[
            AppSpacing.md.h,
            Text(
              'Operating Hours: ${settings.supportHours}',
              style: context.textTheme.bodySmall?.colour(
                colors.onSurfaceSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;

    return Row(
      children: [
        Icon(icon, size: AppSpacing.lg, color: colors.onSurfaceSecondary),
        AppSpacing.md.w,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.labelSmall?.colour(
                  colors.onSurfaceSecondary,
                ),
              ),
              Text(
                value,
                style: context.textTheme.bodyMedium?.medium().colour(
                  colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        AppButton.outline(
          size: .small,
          type: .primary,
          tooltip: 'Test Contact',
          icon: Icons.launch_rounded,
          onPressed: onTap,
        ),
      ],
    );
  }

  Widget _buildPlatformFeesSnapshot(BuildContext context) {
    final colors = context.colors;

    return QuickContainer(
      p: AppSpacing.xl,
      radius: AppRadius.lg,
      color: colors.surface,
      border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(
                  Icons.payments_outlined,
                  size: AppSpacing.xl,
                  color: colors.primary,
                ),
              ),
              AppSpacing.md.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Service Fees',
                      style: context.textTheme.titleMedium?.semiBold(),
                    ),
                    AppSpacing.xs.h,
                    Text(
                      'Configured standard base commission and platform fee schedule.',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                text: 'Edit Fees',
                fullWidth: false,
                type: ButtonType.secondaryOff,
                size: ButtonSize.small,
                leading: const Icon(Icons.edit_outlined, size: AppSpacing.md),
                onPressed: () => onNavigateToSection(SettingsSection.fees),
              ),
            ],
          ),
          AppSpacing.xl.h,
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.backgroundLight,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bodyguard Fee',
                        style: context.textTheme.labelSmall?.colour(
                          colors.onSurfaceSecondary,
                        ),
                      ),
                      AppSpacing.xs.h,
                      Text(
                        '\$${settings.bodyguardFee.toStringAsFixed(2)}',
                        style: context.textTheme.titleLarge?.bold().colour(
                          colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.lg.w,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.backgroundLight,
                    borderRadius: AppRadius.mdRadius,
                    border: Border.all(color: colors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company Fee',
                        style: context.textTheme.labelSmall?.colour(
                          colors.onSurfaceSecondary,
                        ),
                      ),
                      AppSpacing.xs.h,
                      Text(
                        '\$${settings.companyFee.toStringAsFixed(2)}',
                        style: context.textTheme.titleLarge?.bold().colour(
                          colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
