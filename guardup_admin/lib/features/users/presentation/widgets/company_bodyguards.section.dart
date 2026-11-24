import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guardup_admin/shared/widgets/buttons/app_button.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/number.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/features/users/data/models/company.model.dart';
import '/features/users/data/models/user_document.model.dart';
import '/features/users/di/users.providers.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_detail_section.dart';
import '/shared/widgets/sections/app_image.dart';
import '/shared/widgets/state/app_state_view.dart';
import 'bodyguard_details.section.dart';
import 'review.widgets.dart';
import 'user_availability.section.dart';

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
                    onOpen: () => BodyguardReviewPanel.show(
                      context: context,
                      companyId: company.id,
                      bodyguardId: bodyguards[index].id,
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
            _BodyguardAvatar(bodyguard: bodyguard, size: 40),
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

class _BodyguardAvatar extends StatelessWidget {
  const _BodyguardAvatar({required this.bodyguard, required this.size});

  final BodyguardModel bodyguard;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = bodyguard.profileImageUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary.withValues(alpha: 0.1),
      ),
      child: url != null && url.isNotEmpty
          ? ClipOval(
              child: AppImage.network(imageUrl: url, width: size, height: size),
            )
          : Center(
              child: Text(
                bodyguard.name.isNotEmpty
                    ? bodyguard.name.characters.first.toUpperCase()
                    : 'B',
                style: context.textTheme.titleSmall?.bold().colour(
                  colors.primary,
                ),
              ),
            ),
    );
  }
}

/// Side panel to review one company-managed bodyguard: profile, documents
/// (approve / reject each), then approve / reject the bodyguard, or block /
/// unblock an approved one. Reads the bodyguard from the company's list, so
/// it refreshes after every action.
class BodyguardReviewPanel extends ConsumerWidget {
  const BodyguardReviewPanel({
    super.key,
    required this.companyId,
    required this.bodyguardId,
  });

  final String companyId;
  final String bodyguardId;

  static Future<void> show({
    required BuildContext context,
    required String companyId,
    required String bodyguardId,
  }) {
    return AppSidePanel.show<void>(
      context: context,
      title: 'Bodyguard Review',
      subtitle: 'Profile, documents and verification of a company bodyguard',
      width: 60.wPercent(context),
      showFooter: false,
      body: BodyguardReviewPanel(
        companyId: companyId,
        bodyguardId: bodyguardId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBodyguards = ref.watch(companyBodyguardsProvider(companyId));

    return SizedBox(
      height: context.screenHeight,
      child: asyncBodyguards.when(
        skipLoadingOnReload: true,
        loading: () => const AppStateView(type: AppViewType.loading),
        error: (error, _) => AppStateView(
          type: AppViewType.error,
          message: 'Failed to load bodyguard',
          subtitle: error.toString(),
          actionText: 'Retry',
          onAction: () => ref.invalidate(companyBodyguardsProvider(companyId)),
        ),
        data: (bodyguards) {
          final bodyguard = bodyguards
              .where((b) => b.id == bodyguardId)
              .firstOrNull;
          if (bodyguard == null) {
            return const AppStateView(
              type: AppViewType.empty,
              message: 'This bodyguard no longer exists',
            );
          }
          return _BodyguardReviewBody(
            companyId: companyId,
            bodyguard: bodyguard,
          );
        },
      ),
    );
  }
}

class _BodyguardReviewBody extends ConsumerWidget {
  const _BodyguardReviewBody({
    required this.companyId,
    required this.bodyguard,
  });

  final String companyId;
  final BodyguardModel bodyguard;

  String get _name => bodyguard.name.isNotEmpty ? bodyguard.name : 'Bodyguard';

  void _report(WidgetRef ref, String success, String failure) {
    ref
        .read(bodyguardReviewControllerProvider(companyId))
        .handleResult(successMessage: success, fallbackErrorMessage: failure);
  }

  Future<void> _onApprove(BuildContext context, WidgetRef ref) async {
    await ref
        .read(bodyguardReviewControllerProvider(companyId).notifier)
        .approve(bodyguard.id);
    if (context.mounted) {
      _report(ref, '$_name has been approved', 'Failed to approve bodyguard');
    }
  }

  Future<void> _onReject(BuildContext context, WidgetRef ref) async {
    final result = await AppPopup.showRejectWithReason(
      context,
      title: 'Reject $_name',
      message: 'The company will be notified with this reason.',
      confirmLabel: 'Reject Bodyguard',
    );
    final reason = result?.data;
    if (result?.action != PopupAction.confirm ||
        reason == null ||
        !context.mounted) {
      return;
    }
    await ref
        .read(bodyguardReviewControllerProvider(companyId).notifier)
        .reject(bodyguard.id, reason);
    if (context.mounted) {
      _report(ref, '$_name has been rejected', 'Failed to reject bodyguard');
    }
  }

  Future<void> _onToggleBlock(
    BuildContext context,
    WidgetRef ref, {
    required bool block,
  }) async {
    final result = block
        ? await AppPopup.showBlockConfirmation(context, itemName: _name)
        : await AppPopup.showUnblockConfirmation(context, itemName: _name);
    if (result?.action != PopupAction.confirm || !context.mounted) return;

    await ref
        .read(bodyguardReviewControllerProvider(companyId).notifier)
        .setBlocked(bodyguard.id, blocked: block);
    if (context.mounted) {
      _report(
        ref,
        block ? '$_name has been blocked' : '$_name has been unblocked',
        'Failed to update bodyguard status',
      );
    }
  }

  Future<void> _onApproveDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentModel doc,
    String title,
  ) async {
    await ref
        .read(bodyguardReviewControllerProvider(companyId).notifier)
        .approveDocument(doc.id);
    if (context.mounted) {
      _report(ref, '$title approved', 'Failed to approve document');
    }
  }

  /// Rejecting any document also moves the bodyguard to REJECTED.
  Future<void> _onRejectDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentModel doc,
    String title,
  ) async {
    final result = await AppPopup.showRejectWithReason(
      context,
      title: 'Reject $title',
      message:
          'The reason is saved on this document. Rejecting a document also '
          'rejects $_name.',
      confirmLabel: 'Reject Document',
    );
    final reason = result?.data;
    if (result?.action != PopupAction.confirm ||
        reason == null ||
        !context.mounted) {
      return;
    }
    await ref
        .read(bodyguardReviewControllerProvider(companyId).notifier)
        .rejectDocument(doc.id, reason);
    if (context.mounted) {
      _report(ref, '$title rejected', 'Failed to reject document');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final status = bodyguard.status;
    final isBusy = ref
        .watch(bodyguardReviewControllerProvider(companyId))
        .isLoading;
    final allDocumentsApproved = (bodyguard.documents ?? const []).every(
      (doc) => doc.verificationStatus.isVerified,
    );
    final reason = bodyguard.rejectionReason?.trim();
    final serviceNames =
        bodyguard.services
            ?.map((s) => s.name)
            .where((n) => n.isNotEmpty)
            .toList() ??
        const <String>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 1. Header: identity, status and actions
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BodyguardAvatar(bodyguard: bodyguard, size: 56),
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                        AppSpacing.xs.h,
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            AppChip(
                              title: status.label(),
                              color: status.color(context),
                              size: AppChipSize.small,
                            ),
                            if (!bodyguard.isActive)
                              AppChip(
                                title: 'Switched off by company',
                                color: colors.onSurfaceSecondary,
                                size: AppChipSize.small,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (status.isRejected && reason != null && reason.isNotEmpty) ...[
                AppSpacing.md.h,
                RejectionReasonNote(label: 'Rejection reason', reason: reason),
              ],
              AppSpacing.md.h,
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (status.isUnderReview) ...[
                    AppButton.outline(
                      text: 'Approve Bodyguard',
                      tooltip: allDocumentsApproved
                          ? 'Approve bodyguard'
                          : 'All documents must be approved first',
                      type: .success,
                      size: .small,
                      fullWidth: false,
                      onPressed: isBusy || !allDocumentsApproved
                          ? null
                          : () => _onApprove(context, ref),
                      trailing: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                    ),
                    if (status.isPendingApproval)
                      AppButton.outline(
                        text: 'Reject Bodyguard',
                        type: .danger,
                        size: .small,
                        fullWidth: false,
                        onPressed: isBusy
                            ? null
                            : () => _onReject(context, ref),
                        trailing: const Icon(Icons.cancel_outlined, size: 16),
                      ),
                  ] else if (status.isApproved || status.isBlocked)
                    AppButton.outline(
                      text: status.isBlocked
                          ? 'Unblock Bodyguard'
                          : 'Block Bodyguard',
                      type: status.isBlocked ? .success : .warning,
                      size: .small,
                      fullWidth: false,
                      onPressed: isBusy
                          ? null
                          : () => _onToggleBlock(
                              context,
                              ref,
                              block: !status.isBlocked,
                            ),
                      trailing: Icon(
                        status.isBlocked
                            ? Icons.lock_open_rounded
                            : Icons.block_outlined,
                        size: 16,
                      ),
                    )
                  else
                    Text(
                      'The company has not submitted this bodyguard for review yet.',
                      style: context.textTheme.bodySmall?.colour(
                        colors.onSurfaceSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.md.h,

        // 2. Profile
        BodyguardDetailsSection(bodyguard: bodyguard, services: serviceNames),
        AppSpacing.md.h,

        // 3. Weekly availability
        if (bodyguard.availabilities?.isNotEmpty == true) ...[
          UserAvailabilitySection(availabilities: bodyguard.availabilities),
          AppSpacing.md.h,
        ],

        // 4. Documents
        DocumentReviewList(
          documents: bodyguard.documents ?? const [],
          canReview: status.isUnderReview,
          isReviewing: isBusy,
          emptyMessage: 'The company has not uploaded any documents yet.',
          onApprove: (doc, title) =>
              _onApproveDocument(context, ref, doc, title),
          onReject: (doc, title) => _onRejectDocument(context, ref, doc, title),
        ),
        AppSpacing.xxxl.h,
      ],
    );
  }
}
