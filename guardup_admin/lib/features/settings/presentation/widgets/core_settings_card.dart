import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/core/utils/validators.dart';
import '/shared/widgets/inputs/app_input_label.dart';
import '/shared/widgets/inputs/app_text_field.dart';

/// Card for managing Core platform settings & maintenance mode.
class CoreSettingsCard extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final TextEditingController titleController;
  final TextEditingController messageController;
  final ValueNotifier<bool> isUnderMaintenanceNotifier;
  final VoidCallback onChanged;

  const CoreSettingsCard({
    super.key,
    this.formKey,
    required this.titleController,
    required this.messageController,
    required this.isUnderMaintenanceNotifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Maintenance Mode Controls ──
        QuickContainer(
          p: AppSpacing.xl,
          radius: AppRadius.lg,
          color: colors.surface,
          border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      size: AppSpacing.xl,
                      color: colors.warning,
                    ),
                  ),
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Maintenance Mode',
                          style: context.textTheme.titleMedium?.semiBold(),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'Temporarily restrict client mobile app access during database migrations or infrastructure maintenance.',
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.md.w,
                  // Adaptive Switch
                  ValueListenableBuilder<bool>(
                    valueListenable: isUnderMaintenanceNotifier,
                    builder: (context, isUnderMaintenance, _) {
                      return Transform.scale(
                        scale: 0.7,
                        child: Switch.adaptive(
                          value: isUnderMaintenance,
                          activeTrackColor: colors.warning,
                          onChanged: (val) {
                            isUnderMaintenanceNotifier.value = val;
                            onChanged();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
              AppSpacing.xl.h,

              // Form fields
              Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppFieldLabel(
                      text: 'Maintenance Screen Title',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: titleController,
                      validator: (value) => Validators.required(
                        context,
                        value,
                        fieldName: 'Maintenance Screen Title',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. App Under Maintenance',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                      onChanged: (_) => onChanged(),
                    ),

                    AppSpacing.lg.h,

                    const AppFieldLabel(
                      text: 'Maintenance Message / User Notice',
                      isRequired: true,
                    ),
                    AppSpacing.xs.h,
                    AppTextField(
                      controller: messageController,
                      maxLines: 3,
                      validator: (value) => Validators.required(
                        context,
                        value,
                        fieldName: 'Maintenance Message',
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. We are currently upgrading our systems. Please check back shortly.',
                        prefixIcon: Icon(Icons.announcement_outlined),
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        AppSpacing.xl.h,
      ],
    );
  }
}
