import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/company_bodyguards/di/company_bodyguards.providers.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/features/users/data/models/company.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/state/app_state_view.dart';
import 'company_bodyguard_avatar.widget.dart';
import 'company_bodyguard_review.panel.dart';

/// Bodyguards a company added in the app (no login of their own). Each one is
/// reviewed separately: open it to check its documents and approve / reject.
class CompanyBodyguardsSection extends ConsumerWidget {
  const CompanyBodyguardsSection({super.key, required this.company});

  final CompanyModel company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBodyguards = ref.watch(companyBodyguardsProvider(company.id));

    return asyncBodyguards.when(
      skipLoadingOnReload: true,
      loading: () => const AppDetailSection(
        title: 'Company Bodyguards',
        subtitle: 'Loading…',
        icon: Icons.groups_outlined,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => AppDetailSection(
        title: 'Company Bodyguards',
        subtitle: 'Could not load the bodyguards',
        icon: Icons.groups_outlined,
        child: AppStateView(
          type: AppViewType.error,
          message: 'Failed to load bodyguards',
          subtitle: error.toString(),
          actionText: 'Retry',
          onAction: () => ref.invalidate(companyBodyguardsProvider(company.id)),
        ),
      ),
      data: (bodyguards) {
        final awaiting = bodyguards
            .where((b) => b.status.isPendingApproval)
            .length;
        return AppDetailSection(
          title: 'Company Bodyguards',
          subtitle: bodyguards.isEmpty
              ? 'No bodyguards added yet'
              : '${bodyguards.length} added'
                    '${awaiting > 0 ? ' • $awaiting awaiting review' : ''}',
          icon: Icons.groups_outlined,
          child: bodyguards.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'This company has not added any bodyguards yet.',
                    style: context.textTheme.bodyMedium?.colour(
                      context.colors.onSurfaceSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bodyguards.length,
                  separatorBuilder: (_, _) => AppSpacing.sm.h,
                  itemBuilder: (context, index) => _BodyguardRow(
                    bodyguard: bodyguards[index],
                    onOpen: () => CompanyBodyguardReviewPanel.show(
                      context: context,
                      bodyguardId: bodyguards[index].id,
                      showCompanyLink: false,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _BodyguardRow extends StatelessWidget {
  const _BodyguardRow({required this.bodyguard, required this.onOpen});

  final BodyguardModel bodyguard;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rate = bodyguard.hourlyRate ?? 0;

    return InkWell(
      onTap: onOpen,
      borderRadius: AppRadius.smRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.backgroundLight,
          borderRadius: AppRadius.smRadius,
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          children: [
            CompanyBodyguardAvatar(bodyguard: bodyguard, size: 40),
            AppSpacing.md.w,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bodyguard.name.isNotEmpty ? bodyguard.name : 'Unnamed',
                    style: context.textTheme.bodyMedium?.bold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  (AppSpacing.xs / 2).h,
                  Text(
                    rate > 0 ? '${rate.toUsdAmount} / hr' : 'Rate not set',
                    style: context.textTheme.bodySmall?.colour(
                      colors.onSurfaceSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!bodyguard.isActive) ...[
              AppChip(
                title: 'Switched off',
                color: colors.onSurfaceSecondary,
                size: AppChipSize.small,
              ),
              AppSpacing.sm.w,
            ],
            AppChip(
              title: bodyguard.status.label(),
              color: bodyguard.status.color(context),
              size: AppChipSize.small,
            ),
            AppSpacing.sm.w,
            AppButton.outline(
              text: bodyguard.status.isUnderReview ? 'Review' : 'View',
              size: .small,
              type: bodyguard.status.isUnderReview ? .warning : .primary,
              fullWidth: false,
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}
