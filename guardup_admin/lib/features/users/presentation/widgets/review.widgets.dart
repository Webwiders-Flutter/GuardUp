import 'package:flutter/material.dart';
import 'package:guardup_admin/shared/widgets/buttons/app_button.dart';

import '/core/constants/app_radius.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/datetime.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/users/data/models/user_document.model.dart';
import '/shared/widgets/feedbacks/widgets/app_file_viewer.dart';
import '/shared/widgets/misc/app_chip.dart';
import '/shared/widgets/sections/app_detail_section.dart';

/// Shared pieces of the review UI, used for accounts (user details) and for
/// company-managed bodyguards.

/// Titled wrap of chips (services, languages, certifications).
class ProfileChipGroup extends StatelessWidget {
  const ProfileChipGroup({
    super.key,
    required this.title,
    required this.values,
    required this.color,
    this.icon,
  });

  final String title;
  final List<String> values;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.sm.h,
        Text(
          title,
          style: context.textTheme.bodySmall?.semiBold().colour(
            context.colors.onSurfaceSecondary,
          ),
        ),
        AppSpacing.xs.h,
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final value in values)
              AppChip(
                title: value,
                icon: icon,
                size: AppChipSize.small,
                color: color,
              ),
          ],
        ),
      ],
    );
  }
}

/// Verification documents with approve / reject / view actions.
///
/// Review actions are shown only while [canReview] (the owner is under
/// review) and the document is still pending; [isReviewing] disables them
/// while a request is in flight.
class DocumentReviewList extends StatelessWidget {
  const DocumentReviewList({
    super.key,
    required this.documents,
    required this.canReview,
    required this.isReviewing,
    required this.emptyMessage,
    required this.onApprove,
    required this.onReject,
  });

  final List<UserDocumentModel> documents;
  final bool canReview;
  final bool isReviewing;
  final String emptyMessage;
  final void Function(UserDocumentModel doc, String title) onApprove;
  final void Function(UserDocumentModel doc, String title) onReject;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (documents.isEmpty) {
      return AppDetailSection(
        title: 'Verification Documents',
        subtitle: 'No documents submitted yet',
        icon: Icons.folder_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            emptyMessage,
            style: context.textTheme.bodyMedium?.colour(
              colors.onSurfaceSecondary,
            ),
          ),
        ),
      );
    }

    return AppDetailSection(
      title: 'Verification Documents',
      subtitle: '${documents.length} submitted credentials and licenses',
      icon: Icons.folder_shared_outlined,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: documents.length,
        separatorBuilder: (_, _) => AppSpacing.sm.h,
        itemBuilder: (context, index) {
          final doc = documents[index];
          final docName = doc.resolvedDocumentName;
          final title = docName?.isNotEmpty == true
              ? docName!
              : (doc.fileName?.isNotEmpty == true
                    ? doc.fileName!
                    : (doc.documentTypeId ?? 'Document #${index + 1}'));
          final subtitle = docName?.isNotEmpty == true
              ? (doc.fileName ?? doc.documentTypeId)
              : doc.documentTypeId;

          final isApproved = doc.verificationStatus.isVerified;
          final isRejected = doc.verificationStatus.isRejected;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.backgroundLight,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: colors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.xsRadius,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                AppSpacing.md.w,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.bold(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        (AppSpacing.xs / 2).h,
                        Text(
                          subtitle,
                          style: context.textTheme.bodySmall?.colour(
                            colors.onSurfaceSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (doc.uploadedAt != null || doc.validTill != null) ...[
                        AppSpacing.xs.h,
                        DocumentDates(doc: doc),
                      ],
                      if (doc.rejectionReason?.trim().isNotEmpty == true) ...[
                        AppSpacing.xs.h,
                        RejectionReasonNote(
                          label: 'Rejection reason',
                          reason: doc.rejectionReason!,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.md.w,

                // Status Badge
                AppChip(
                  title: doc.verificationStatus.label(),
                  color: doc.verificationStatus.color(context),
                  size: AppChipSize.small,
                ),
                AppSpacing.sm.w,

                // Review Actions (only while the owner is under review)
                if (canReview && !isRejected && !isApproved) ...[
                  AppButton.outline(
                    size: .small,
                    type: .success,
                    tooltip: 'Approve Document',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: isReviewing ? null : () => onApprove(doc, title),
                  ),
                  AppSpacing.xs.w,
                  AppButton.outline(
                    size: .small,
                    type: .danger,
                    tooltip: 'Reject Document',
                    icon: Icons.cancel_outlined,
                    onPressed: isReviewing ? null : () => onReject(doc, title),
                  ),
                  AppSpacing.xs.w,
                ],

                // Preview File Action
                AppButton.outline(
                  size: .small,
                  type: .primary,
                  tooltip: 'View Document',
                  icon: Icons.visibility_outlined,
                  onPressed: () {
                    if (doc.fileUrl.isNotEmpty) {
                      AppFileViewer.show(
                        context: context,
                        title: title,
                        fileUrl: doc.fileUrl,
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Upload date and expiry (`valid_till`) of a document; expired ones are
/// flagged in red.
class DocumentDates extends StatelessWidget {
  const DocumentDates({super.key, required this.doc});

  final UserDocumentModel doc;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final metaStyle = context.textTheme.bodySmall?.colour(
      colors.onSurfaceSecondary,
    );
    final uploadedAt = doc.uploadedAt;
    final validTill = doc.validTill;
    final isExpired =
        validTill != null && validTill.isBefore(DateTime.now().startOfDay);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (uploadedAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file_outlined,
                size: AppSpacing.md - 2,
                color: colors.onSurfaceSecondary,
              ),
              (AppSpacing.xs / 2).w,
              Text('Uploaded ${uploadedAt.readableDate}', style: metaStyle),
            ],
          ),
        if (validTill != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_outlined,
                size: AppSpacing.md - 2,
                color: isExpired ? colors.error : colors.onSurfaceSecondary,
              ),
              (AppSpacing.xs / 2).w,
              Text(
                'Valid till ${validTill.readableDate}',
                style: isExpired
                    ? context.textTheme.bodySmall?.semiBold().colour(
                        colors.error,
                      )
                    : metaStyle,
              ),
              if (isExpired) ...[
                AppSpacing.xs.w,
                AppChip(
                  title: 'Expired',
                  color: colors.error,
                  size: AppChipSize.small,
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Highlighted rejection reason (profile, bodyguard or document).
class RejectionReasonNote extends StatelessWidget {
  const RejectionReasonNote({
    super.key,
    required this.label,
    required this.reason,
  });

  final String label;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.06),
        borderRadius: AppRadius.smRadius,
        border: Border.all(color: colors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: colors.error),
          AppSpacing.xs.w,
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: context.textTheme.bodySmall?.semiBold().colour(
                      colors.error,
                    ),
                  ),
                  TextSpan(
                    text: reason,
                    style: context.textTheme.bodySmall?.colour(
                      colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
