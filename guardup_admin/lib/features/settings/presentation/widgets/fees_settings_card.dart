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

/// Enterprise Card for managing GuardUp platform service fees and commission schedules.
class FeesSettingsCard extends StatelessWidget {
  final GlobalKey<FormState>? formKey;
  final TextEditingController bodyguardFeeController;
  final TextEditingController companyFeeController;
  final VoidCallback onChanged;

  const FeesSettingsCard({
    super.key,
    this.formKey,
    required this.bodyguardFeeController,
    required this.companyFeeController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Card 1: Platform Service Fee Rates ───────────────────────────────
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
                        Row(
                          children: [
                            Text(
                              'Platform Service Fees',
                              style: context.textTheme.titleMedium?.semiBold(),
                            ),
                          ],
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'Configure base platform service fees applied across independent bodyguards and corporate security company bookings.',
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

              // Form fields
              Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 600;

                        final bodyguardField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppFieldLabel(
                              text: 'Bodyguard Platform Fee',
                              isRequired: true,
                            ),
                            AppSpacing.xs.h,
                            AppTextField(
                              controller: bodyguardFeeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) => Validators.required(
                                context,
                                value,
                                fieldName: 'Bodyguard Platform Fee',
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              onChanged: (_) => onChanged(),
                            ),
                            AppSpacing.xs.h,
                            Text(
                              'Flat platform fee applied to each independent bodyguard booking.',
                              style: context.textTheme.bodySmall
                                  ?.size(11.5)
                                  .colour(colors.onSurfaceSecondary),
                            ),
                          ],
                        );

                        final companyField = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppFieldLabel(
                              text: 'Security Company Fee',
                              isRequired: true,
                            ),
                            AppSpacing.xs.h,
                            AppTextField(
                              controller: companyFeeController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) => Validators.required(
                                context,
                                value,
                                fieldName: 'Security Company Fee',
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                prefixIcon: Icon(Icons.attach_money_rounded),
                              ),
                              onChanged: (_) => onChanged(),
                            ),
                            AppSpacing.xs.h,
                            Text(
                              'Platform commission fee applied per security company partner booking.',
                              style: context.textTheme.bodySmall
                                  ?.size(11.5)
                                  .colour(colors.onSurfaceSecondary),
                            ),
                          ],
                        );

                        if (isCompact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bodyguardField,
                              AppSpacing.lg.h,
                              companyField,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: bodyguardField),
                            AppSpacing.xl.w,
                            Expanded(child: companyField),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        AppSpacing.xl.h,

        // ── Card 2: Fee Schedule Information & Operational Notes ─────────────
        QuickContainer(
          p: AppSpacing.xl,
          radius: AppRadius.lg,
          color: colors.surface,
          border: Border.all(color: colors.borderLight.withValues(alpha: 0.8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.info.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: AppSpacing.xl,
                      color: colors.info,
                    ),
                  ),
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Billing Logic & Fee Allocation',
                          style: context.textTheme.titleMedium?.semiBold(),
                        ),
                        AppSpacing.xs.h,
                        Text(
                          'How platform service charges are calculated and disbursed to providers.',
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

              // Informational breakdown cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 640;

                  final bodyguardSummary = Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.backgroundLight,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security_outlined,
                              size: AppSpacing.md + 2,
                              color: colors.primary,
                            ),
                            AppSpacing.xs.w,
                            Text(
                              'Individual Bodyguards',
                              style: context.textTheme.bodyMedium?.semiBold(),
                            ),
                          ],
                        ),
                        AppSpacing.sm.h,
                        Text(
                          'Independent operatives receive their assigned hourly / assignment rate. GuardUp collects the Bodyguard Platform Fee on booking checkout.',
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  );

                  final companySummary = Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.backgroundLight,
                      borderRadius: AppRadius.mdRadius,
                      border: Border.all(color: colors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: AppSpacing.md + 2,
                              color: colors.secondary,
                            ),
                            AppSpacing.xs.w,
                            Text(
                              'Security Companies',
                              style: context.textTheme.bodyMedium?.semiBold(),
                            ),
                          ],
                        ),
                        AppSpacing.sm.h,
                        Text(
                          'Registered security companies dispatch verified guards from their fleet. The Company Fee is applied as platform service commission per contract.',
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      children: [
                        bodyguardSummary,
                        AppSpacing.md.h,
                        companySummary,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: bodyguardSummary),
                      AppSpacing.lg.w,
                      Expanded(child: companySummary),
                    ],
                  );
                },
              ),

              AppSpacing.lg.h,

              // Notice Callout
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.08),
                  borderRadius: AppRadius.mdRadius,
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppSpacing.lg,
                      color: colors.warning,
                    ),
                    AppSpacing.md.w,
                    Expanded(
                      child: Text(
                        'Updates to platform fees immediately apply to new checkout sessions and quotations. Active or in-progress bookings retain their confirmed pricing.',
                        style: context.textTheme.bodySmall?.colour(
                          colors.onSurface,
                        ),
                      ),
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
