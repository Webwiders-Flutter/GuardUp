import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/settings/settings.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/shared/widgets/buttons/app_button.dart';

/// Full-screen view shown when the platform is marked as under maintenance.
class AppMaintenanceScreen extends StatelessWidget {
  final AdminSettingsModel? settings;
  final bool isChecking;
  final VoidCallback? onCheckAgain;

  const AppMaintenanceScreen({
    super.key,
    this.settings,
    this.isChecking = false,
    this.onCheckAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = settings?.maintenanceTitle?.isNotEmpty == true
        ? settings!.maintenanceTitle!
        : l10n.maintenanceTitle;
    final message = settings?.maintenanceMessage?.isNotEmpty == true
        ? settings!.maintenanceMessage!
        : l10n.maintenanceMessage;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.xl.allPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Maintenance Icon Badge
                  QuickContainer(
                    w: AppSpacing.xxxl * 3,
                    h: AppSpacing.xxxl * 3,
                    radius: AppRadius.full,
                    color: context.colors.warning.withValues(alpha: 0.12),
                    border: Border.all(
                      color: context.colors.warning.withValues(alpha: 0.3),
                      width: AppSpacing.xs / 2,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.engineering_rounded,
                      size: AppSpacing.xxxl + AppSpacing.lg,
                      color: context.colors.warning,
                    ),
                  ),
                  AppSpacing.xl.h,

                  // Status Badge
                  QuickContainer(
                    px: AppSpacing.md,
                    py: AppSpacing.xs,
                    radius: AppRadius.full,
                    color: context.colors.warning.withValues(alpha: 0.15),
                    child: Text(
                      l10n.maintenanceInProgress,
                      style: context.textTheme.labelSmall?.bold().colour(
                        context.colors.warning,
                      ),
                    ),
                  ),
                  AppSpacing.md.h,

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                  AppSpacing.sm.h,

                  // Message
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: (AppSpacing.xxxl * 13) + 4,
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AppSpacing.xxl.h,

                  // Check Again Button
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.xxxl * 10,
                    ),
                    child: AppButton(
                      text: l10n.checkAgain,
                      leading: const Icon(Icons.refresh_rounded),
                      isLoading: isChecking,
                      onPressed: onCheckAgain,
                    ),
                  ),
                  AppSpacing.xxl.h,

                  // Support Section
                  if (settings != null) ...[
                    Divider(
                      color: context.colors.borderColor.withValues(alpha: 0.4),
                    ),
                    AppSpacing.md.h,
                    Text(
                      l10n.needUrgentAssistance,
                      style: context.textTheme.bodySmall?.semiBold().colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    if (settings!.supportHours != null &&
                        settings!.supportHours!.isNotEmpty) ...[
                      (AppSpacing.xs / 2).h,
                      Text(
                        settings!.supportHours!,
                        style: context.textTheme.labelSmall?.colour(
                          context.colors.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                    AppSpacing.md.h,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // WhatsApp
                        IconButton.filledTonal(
                          onPressed: () {
                            AppLauncher.openWhatsApp(
                              phone: settings!.supportWhatsappPhoneNumber,
                              message: l10n.maintenanceWhatsAppMessage,
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        AppSpacing.md.w,
                        // Call
                        IconButton.filledTonal(
                          onPressed: () {
                            AppLauncher.callPhone(
                              settings!.supportCallPhoneNumber,
                            );
                          },
                          icon: const Icon(Icons.phone_outlined),
                        ),
                        AppSpacing.md.w,
                        // Email
                        IconButton.filledTonal(
                          onPressed: () {
                            AppLauncher.sendEmail(
                              email: settings!.supportEmail,
                              subject: l10n.maintenanceEmailSubject,
                            );
                          },
                          icon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
