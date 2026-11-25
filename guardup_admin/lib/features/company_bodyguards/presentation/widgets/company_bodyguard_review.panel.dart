import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/layout.extension.dart';
import '/core/extensions/riverpod.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/company_bodyguards/di/company_bodyguards.providers.dart';
import '/features/company_bodyguards/presentation/controllers/company_bodyguard_review.controller.dart';
import '/features/users/data/models/bodyguard.model.dart';
import '/features/users/data/models/user_document.model.dart';
import '/features/users/presentation/screens/user_details.screen.dart';
import '/features/users/presentation/widgets/bodyguard_details.section.dart';
import '/features/users/presentation/widgets/review.widgets.dart';
import '/features/users/presentation/widgets/user_availability.section.dart';
import '/shared/widgets/admin_layout/app_side_panel.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/state/app_state_view.dart';
import 'company_bodyguard_avatar.widget.dart';

/// Side panel to review one company-managed bodyguard, with the same review
/// flow as a user's application (UserDetailsScreen), except that company
/// bodyguards are never blocked: only approve, reject and delete.
///
/// - Pending: review each document, then approve (only once every document
///   is approved) or reject the bodyguard with a reason.
/// - Rejected: documents stay reviewable; the company fixes and resubmits.
///   Rejecting a document rejects the bodyguard; approving the last rejected
///   one sends it back to pending (database triggers).
/// - Approved: delete.
class CompanyBodyguardReviewPanel extends ConsumerWidget {
  const CompanyBodyguardReviewPanel({
    super.key,
    required this.bodyguardId,
    this.showCompanyLink = true,
  });

  final String bodyguardId;

  /// Off when opened from the company's own details.
  final bool showCompanyLink;

  static Future<void> show({
    required BuildContext context,
    required String bodyguardId,
    bool showCompanyLink = true,
  }) {
    return AppSidePanel.show<void>(
      context: context,
      title: 'Bodyguard Review',
      subtitle: 'Profile, documents and verification of a company bodyguard',
      width: 60.wPercent(context),
      showFooter: false,
      body: CompanyBodyguardReviewPanel(
        bodyguardId: bodyguardId,
        showCompanyLink: showCompanyLink,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = companyBodyguardDetailsProvider(bodyguardId);
    final asyncBodyguard = ref.watch(provider);

    return SizedBox(
      height: context.screenHeight,
      child: asyncBodyguard.when(
        skipLoadingOnReload: true,
        loading: () => const AppStateView(type: AppViewType.loading),
        error: (error, _) => AppStateView(
          type: AppViewType.error,
          message: 'Failed to load bodyguard',
          subtitle: error.toString(),
          actionText: 'Retry',
          onAction: () => ref.invalidate(provider),
        ),
        data: (bodyguard) => _ReviewBody(
          bodyguard: bodyguard,
          showCompanyLink: showCompanyLink,
        ),
      ),
    );
  }
}

class _ReviewBody extends ConsumerWidget {
  const _ReviewBody({required this.bodyguard, required this.showCompanyLink});

  final BodyguardModel bodyguard;
  final bool showCompanyLink;

  String get _name => bodyguard.name.isNotEmpty ? bodyguard.name : 'Bodyguard';

  CompanyBodyguardReviewController _controller(WidgetRef ref) => ref.read(
    companyBodyguardReviewControllerProvider(bodyguard.id).notifier,
  );

  bool _report(WidgetRef ref, String success, String failure) {
    return ref
        .read(companyBodyguardReviewControllerProvider(bodyguard.id))
        .handleResult(successMessage: success, fallbackErrorMessage: failure);
  }

  /// Enabled only once every document is approved.
  Future<void> _onApprove(BuildContext context, WidgetRef ref) async {
    await _controller(ref).approve();
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
    await _controller(ref).reject(reason);
    if (context.mounted) {
      _report(ref, '$_name has been rejected', 'Failed to reject bodyguard');
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final result = await AppPopup.showDeleteConfirmation(
      context,
      deleteItemName: _name,
    );
    if (result?.action != PopupAction.confirm || !context.mounted) return;

    await _controller(ref).delete();
    if (!context.mounted) return;
    final deleted = _report(
      ref,
      '$_name deleted successfully',
      'Failed to delete bodyguard',
    );
    if (deleted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onApproveDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentModel doc,
    String title,
  ) async {
    await _controller(ref).approveDocument(doc.id);
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
    await _controller(ref).rejectDocument(doc.id, reason);
    if (context.mounted) {
      _report(ref, '$title rejected', 'Failed to reject document');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final status = bodyguard.status;
    final isBusy = ref
        .watch(companyBodyguardReviewControllerProvider(bodyguard.id))
        .isLoading;
    final reason = bodyguard.rejectionReason?.trim();
    final company = bodyguard.company;
    final companyName = company?.companyName?.trim();
    final serviceNames =
        bodyguard.services
            ?.map((s) => s.name)
            .where((n) => n.isNotEmpty)
            .toList() ??
        const <String>[];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // 1. Header: identity, company, status and actions
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
                  CompanyBodyguardAvatar(bodyguard: bodyguard, size: 56),
                  AppSpacing.md.w,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: context.textTheme.titleMedium?.bold(),
                        ),
                        if (companyName != null && companyName.isNotEmpty) ...[
                          (AppSpacing.xs / 2).h,
                          Text(
                            'Bodyguard of $companyName',
                            style: context.textTheme.bodySmall?.colour(
                              colors.onSurfaceSecondary,
                            ),
                          ),
                        ],
                        AppSpacing.xs.h,
                        Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            AppChip(
                              title: status.label(),
                              color: status.color(context),
                              icon: status.icon,
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
                  if (showCompanyLink && company != null)
                    AppButton.outline(
                      text: 'View Company',
                      size: .small,
                      type: .primary,
                      fullWidth: false,
                      onPressed: () => UserDetailsScreen.showAsSidebar(
                        context: context,
                        userId: company.userId,
                      ),
                      trailing: const Icon(Icons.business_outlined, size: 16),
                    ),
                ],
              ),
              if (reason != null && reason.isNotEmpty) ...[
                AppSpacing.md.h,
                RejectionReasonNote(label: 'Rejection reason', reason: reason),
              ],
              if (!status.isRejected) ...[
                AppSpacing.md.h,
                Divider(
                  color: colors.borderLight.withValues(alpha: 0.6),
                  height: 1,
                ),
                AppSpacing.md.h,
              ],
              _ActionsBar(
                bodyguard: bodyguard,
                isBusy: isBusy,
                onApprove: () => _onApprove(context, ref),
                onReject: () => _onReject(context, ref),
                onDelete: () => _onDelete(context, ref),
              ),
            ],
          ),
        ),
        AppSpacing.md.h,

        // 2. Profile
        BodyguardDetailsSection(bodyguard: bodyguard, services: serviceNames),
        AppSpacing.md.h,

        // 3. Weekly availability
        UserAvailabilitySection(availabilities: bodyguard.availabilities),
        AppSpacing.md.h,

        // 4. Documents (reviewable while pending or rejected)
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

/// Same actions per status as a user's details (_UserActionsBar), without
/// block / unblock.
class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.bodyguard,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  final BodyguardModel bodyguard;
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = bodyguard.status;
    final allDocumentsApproved = (bodyguard.documents ?? const []).every(
      (doc) => doc.verificationStatus.isVerified,
    );

    if (status.isIncomplete) {
      return Text(
        'The company has not submitted this bodyguard for review yet.',
        style: context.textTheme.bodySmall?.colour(
          context.colors.onSurfaceSecondary,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // BLOCKED only exists on rows blocked before blocking was removed.
        if (status.isApproved || status.isBlocked) ...[
          AppButton.outline(
            text: 'Delete Bodyguard',
            type: .danger,
            size: .small,
            fullWidth: false,
            onPressed: isBusy ? null : onDelete,
            trailing: const Icon(Icons.delete_outline_rounded, size: 16),
          ),
        ] else if (status.isPendingApproval) ...[
          AppButton.outline(
            text: 'Approve Bodyguard',
            tooltip: allDocumentsApproved
                ? 'Approve bodyguard'
                : 'All documents must be approved before approving the bodyguard',
            type: .success,
            size: .small,
            fullWidth: false,
            onPressed: isBusy || !allDocumentsApproved ? null : onApprove,
            trailing: const Icon(Icons.check_circle_outline_rounded, size: 16),
          ),
          AppButton.outline(
            text: 'Reject Bodyguard',
            type: .danger,
            size: .small,
            fullWidth: false,
            onPressed: isBusy ? null : onReject,
            trailing: const Icon(Icons.cancel_outlined, size: 16),
          ),
        ],
      ],
    );
  }
}
