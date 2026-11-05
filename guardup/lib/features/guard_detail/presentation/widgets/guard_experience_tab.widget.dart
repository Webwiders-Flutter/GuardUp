import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// "Experience" tab content highlighting operative tenure and specialized security services.
class GuardExperienceTabWidget extends StatelessWidget {
  final String yearsExperience;
  final String specializationTitle;
  final List<String> services;

  const GuardExperienceTabWidget({
    super.key,
    this.yearsExperience = '8+ Years',
    this.specializationTitle = 'Executive Protection',
    this.services = const ['Premium car', 'Licensed armed', 'Corporate visits'],
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Experience Hero Card
          QuickContainer(
            w: double.infinity,
            p: AppSpacing.md,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: context.colors.onPrimary,
            border: Border.all(
              color: context.colors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience',
                      style: context.textTheme.labelMedium?.colour(
                        context.colors.onSurfaceVariant,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.briefcase,
                      size: 18,
                      color: context.colors.gold,
                    ),
                  ],
                ),
                AppSpacing.xs.h,
                Text(
                  yearsExperience,
                  style: context.textTheme.headlineSmall?.bold().colour(
                    context.colors.gold,
                  ),
                ),
                AppSpacing.xs.h,
                Text(
                  specializationTitle,
                  style: context.textTheme.bodySmall?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.lg.h,

          // Services Section
          Text(
            'Services',
            style: context.textTheme.labelLarge?.bold().colour(
              context.colors.onSurface,
            ),
          ),
          AppSpacing.sm.h,

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: context.colors.onPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: context.colors.borderColor.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Text(
                  service,
                  style: context.textTheme.labelSmall
                      ?.copyWith(fontSize: 11)
                      .colour(context.colors.onSurface),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
