import 'package:flutter/material.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/gen/assets.gen.dart';
import '/shared/widgets/sections/app_image.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/enum/guard_doc_type.enum.dart';
import '/features/body_guard/data/model/body_guard.model.dart';
import '/features/body_guard/data/model/user_document.model.dart';
import '/shared/widgets/feedbacks/widgets/app_file_preview.dart';

/// Company View "Document" Tab: Displays operative credentials and compliance documents
/// along with verification audit badges and preview capabilities.
class CompanyGuardDocumentsTabWidget extends StatelessWidget {
  final BodyGuardModel bodyguard;

  const CompanyGuardDocumentsTabWidget({
    super.key,
    required this.bodyguard,
  });

  @override
  Widget build(BuildContext context) {
    final docs = (bodyguard.documents != null && bodyguard.documents!.isNotEmpty)
        ? bodyguard.documents!
        : const [
            UserDocumentModel(
              id: 'doc_id_proof',
              documentTypeId: 'id_proof',
              fileUrl: '',
              fileName: 'Government ID / Passport.pdf',
              status: DocumentStatus.approved,
            ),
            UserDocumentModel(
              id: 'doc_license',
              documentTypeId: 'security_license',
              fileUrl: '',
              fileName: 'Armed Security Officer License.pdf',
              status: DocumentStatus.approved,
            ),
            UserDocumentModel(
              id: 'doc_police',
              documentTypeId: 'police_verification',
              fileUrl: '',
              fileName: 'Police Background Clearance.pdf',
              status: DocumentStatus.approved,
            ),
            UserDocumentModel(
              id: 'doc_cert',
              documentTypeId: 'certifications',
              fileUrl: '',
              fileName: 'Tactical Protection Certification.pdf',
              status: DocumentStatus.approved,
            ),
          ];

    final auditedCount = docs.where((d) => d.status.isApproved).length;

    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compliance Documents',
                style: context.textTheme.titleMedium?.bold(),
              ),
              QuickContainer(
                px: 10,
                py: 4,
                radius: 12,
                color: context.colors.primary.withValues(alpha: 0.12),
                borderColor: context.colors.primary,
                borderWidth: 0.6,
                child: Text(
                  '$auditedCount of ${docs.length} Verified',
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),

          AppSpacing.md.h,

          // List of document cards
          ...docs.map((doc) => _buildDocumentCard(context, doc)),

          AppSpacing.xxl.h,
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, UserDocumentModel doc) {
    final isApproved = doc.status.isApproved;
    final isRejected = doc.status.isRejected;

    final badgeColor = isApproved
        ? context.colors.success
        : isRejected
            ? context.colors.error
            : context.colors.primary;

    final docType = GuardDocType.tryFromApiValue(doc.documentTypeId);
    final title = doc.fileName != null && doc.fileName!.isNotEmpty
        ? doc.fileName!
        : switch (docType) {
            GuardDocType.idProof => 'Government ID / Passport',
            GuardDocType.securityLicense => 'Armed Security Officer License',
            GuardDocType.policeVerification => 'Police Background Clearance',
            GuardDocType.certifications => 'Tactical Protection Certification',
            null => 'Verification Document',
          };

    final subtitle = switch (docType) {
      GuardDocType.idProof => 'Identity Verification Proof',
      GuardDocType.securityLicense => 'Security Industry Authority (SIA)',
      GuardDocType.policeVerification => 'Federal Crime Records Registry',
      GuardDocType.certifications => 'Executive Close Protection Institute',
      null => 'Compliance & Verification',
    };

    return QuickContainer(
      p: 12,
      my: 6,
      radius: 15,
      color: context.colors.onPrimary.withValues(alpha: 0.6),
      borderColor: context.colors.onSurface.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QuickContainer(
                px: 10,
                py: 10,
                radius: 12,
                color: isApproved
                    ? context.colors.primary.withValues(alpha: 0.1)
                    : context.colors.surfaceContainer,
                borderColor: context.colors.borderColor,
                child: isApproved
                    ? AppImage.svgAsset(
                        assetPath: Assets.svg.verified.path,
                        width: 20,
                      )
                    : Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: badgeColor,
                      ),
              ),
              12.w,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        6.w,
                        QuickContainer(
                          px: 8,
                          py: 2,
                          radius: 10,
                          color: badgeColor.withValues(alpha: 0.12),
                          borderColor: badgeColor.withValues(alpha: 0.5),
                          borderWidth: 0.5,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isApproved
                                    ? Icons.check_circle_rounded
                                    : isRejected
                                        ? Icons.cancel_rounded
                                        : Icons.hourglass_top_rounded,
                                size: 11,
                                color: badgeColor,
                              ),
                              3.w,
                              Text(
                                doc.status.label,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    4.h,
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rejection reason banner if rejected
          if (isRejected && (doc.rejectionReason?.isNotEmpty ?? false)) ...[
            8.h,
            QuickContainer(
              p: 8,
              radius: 8,
              color: context.colors.error.withValues(alpha: 0.08),
              borderColor: context.colors.error.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: context.colors.error,
                  ),
                  6.w,
                  Expanded(
                    child: Text(
                      'Rejection reason: ${doc.rejectionReason}',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // View preview action button
          if (doc.fileUrl.isNotEmpty) ...[
            8.h,
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  AppFilePreviewSheet.show(
                    context: context,
                    title: title,
                    fileUrl: doc.fileUrl,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 13,
                        color: context.colors.primary,
                      ),
                      4.w,
                      Text(
                        'View Document',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
