import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/config/admin_settings/admin_settings.dart';
import '/core/services/launcher/app_launcher.service.dart';
import '/shared/widgets/buttons/app_button.dart';

/// Full-screen non-dismissible view when a mandatory update is required.
class ForceUpdateScreen extends StatelessWidget {
  final AdminSettingsModel? settings;
  final String currentVersion;
  final String targetVersion;
  final String? updateMessage;
  final VoidCallback? onUpdateNow;

  const ForceUpdateScreen({
    super.key,
    this.settings,
    required this.currentVersion,
    required this.targetVersion,
    this.updateMessage,
    this.onUpdateNow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  // Rocket / Update Icon
                  QuickContainer(
                    w: AppSpacing.xxxl * 3,
                    h: AppSpacing.xxxl * 3,
                    radius: AppRadius.full,
                    color: context.colors.primary.withValues(alpha: 0.1),
                    border: Border.all(
                      color: context.colors.primary.withValues(alpha: 0.25),
                      width: AppSpacing.xs / 2,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.system_security_update_rounded,
                      size: AppSpacing.xxxl + AppSpacing.lg,
                      color: context.colors.primary,
                    ),
                  ),
                  AppSpacing.xl.h,

                  // Badge
                  QuickContainer(
                    px: AppSpacing.md,
                    py: AppSpacing.xs,
                    radius: AppRadius.full,
                    color: context.colors.primary.withValues(alpha: 0.1),
                    child: Text(
                      l10n.mandatoryUpdate,
                      style: context.textTheme.labelSmall?.bold().colour(
                        context.colors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.md.h,

                  // Heading
                  Text(
                    l10n.timeToUpdate,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineSmall?.bold().colour(
                      context.colors.onSurface,
                    ),
                  ),
                  AppSpacing.sm.h,

                  // Subtitle
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: (AppSpacing.xxxl * 12) + AppSpacing.lg,
                    ),
                    child: Text(
                      updateMessage != null && updateMessage!.trim().isNotEmpty
                          ? updateMessage!
                          : l10n.forceUpdateDefaultMessage(targetVersion),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  AppSpacing.xl.h,

                  // Version Compare Box
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.xxxl * 10,
                    ),
                    child: QuickContainer(
                      p: AppSpacing.md,
                      radius: AppRadius.md,
                      color: context.colors.surface,
                      border: Border.all(
                        color: context.colors.borderColor.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                l10n.yourVersion,
                                style: context.textTheme.labelSmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.xs.h,
                              Text(
                                'v$currentVersion',
                                style: context.textTheme.bodyMedium
                                    ?.semiBold()
                                    .colour(context.colors.error),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: AppSpacing.xl,
                            color: context.colors.onSurfaceVariant,
                          ),
                          Column(
                            children: [
                              Text(
                                l10n.requiredVersion,
                                style: context.textTheme.labelSmall?.colour(
                                  context.colors.onSurfaceVariant,
                                ),
                              ),
                              AppSpacing.xs.h,
                              Text(
                                'v$targetVersion',
                                style: context.textTheme.bodyMedium
                                    ?.semiBold()
                                    .colour(context.colors.success),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSpacing.xl.h,

                  // Update Now Button
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.xxxl * 10,
                    ),
                    child: AppButton(
                      text: l10n.updateNow,
                      leading: const Icon(Icons.download_rounded),
                      onPressed: onUpdateNow,
                    ),
                  ),
                  AppSpacing.lg.h,

                  // Contact support link if stuck
                  if (settings != null)
                    TextButton.icon(
                      onPressed: () {
                        AppLauncher.openWhatsApp(
                          phone: settings!.supportWhatsappPhoneNumber,
                          message: l10n.forceUpdateWhatsAppMessage(
                            targetVersion,
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.help_outline_rounded,
                        size: AppSpacing.lg + 2,
                      ),
                      label: Text(
                        l10n.havingTroubleUpdating,
                        style: context.textTheme.bodyMedium?.colour(
                          context.colors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
