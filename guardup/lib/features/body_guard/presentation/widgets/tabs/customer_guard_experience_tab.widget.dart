import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';

/// Customer View "Experience" Tab: Highlights operative tenure, service specializations, and tactical credentials.
class CustomerGuardExperienceTabWidget extends StatelessWidget {
  final String yearsExperience;
  final String specializationTitle;
  final List<String> services;

  const CustomerGuardExperienceTabWidget({
    super.key,
    this.yearsExperience = '5+ Years',
    this.specializationTitle = 'Licensed Armed, Corporate Visits',
    this.services = const [
      'VIP Close Protection',
      'Armed Escort',
      'Tactical Driver',
      'Asset Security',
    ],
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
                      color: context.colors.primary,
                    ),
                  ],
                ),
                AppSpacing.xs.h,
                Text(
                  yearsExperience,
                  style: context.textTheme.titleMedium?.bold().colour(
                    context.colors.onSurface,
                  ),
                ),
                AppSpacing.xxs.h,
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

          // Services & Certifications List
          Text(
            'SPECIALIZED SERVICES',
            style: context.textTheme.labelMedium
                ?.bold()
                .copyWith(letterSpacing: 0.8)
                .colour(context.colors.onSurfaceVariant),
          ),
          AppSpacing.sm.h,

          if (services.isEmpty)
            Text(
              'No specialized services listed.',
              style: context.textTheme.bodySmall?.colour(
                context.colors.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: services.map((service) {
                return QuickContainer(
                  px: 12,
                  py: 8,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: context.colors.surfaceContainer,
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: context.colors.primary,
                      ),
                      AppSpacing.xs.w,
                      Text(
                        service,
                        style: context.textTheme.bodySmall?.bold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          AppSpacing.xxl.h,
        ],
      ),
    );
  }
}
