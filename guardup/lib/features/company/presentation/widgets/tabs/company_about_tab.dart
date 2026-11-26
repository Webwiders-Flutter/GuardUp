import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/documents/data/models/user_document.model.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../../data/model/company.model.dart';

/// Tab content rendering company biography, membership tenure, and verified business documentation.
class CompanyAboutTab extends StatelessWidget {
  final CompanyModel? company;

  const CompanyAboutTab({super.key, this.company});

  @override
  Widget build(BuildContext context) {
    final joinedDateText = company?.createdAt != null
        ? 'Joined ${DateFormat('dd MMM , yyyy').format(company!.createdAt!)}'
        : 'Joined recently';

    final bioText = company?.bio?.trim().isNotEmpty == true
        ? company!.bio!
        : '';

    final docs = company?.documents;
    final effectiveDocs =
        docs ??
        const [
          UserDocumentModel(
            id: 'doc_1',
            documentTypeId: 'incorporation',
            fileUrl: '',
            fileName: 'Certificate of Incorporation.pdf',
            status: DocumentStatus.approved,
          ),
          UserDocumentModel(
            id: 'doc_2',
            documentTypeId: 'agency_license',
            fileUrl: '',
            fileName: 'Private Security Agency License.pdf',
            status: DocumentStatus.approved,
          ),
          UserDocumentModel(
            id: 'doc_3',
            documentTypeId: 'insurance',
            fileUrl: '',
            fileName: 'Liability Insurance Coverage.pdf',
            status: DocumentStatus.approved,
          ),
        ];

    return SingleChildScrollView(
      padding: context.horizontalEdgeInsets + AppSpacing.md.yPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -------------------------------------------------------------------
          // 1. Membership / Joined Date Banner
          // -------------------------------------------------------------------
          WrapperCard(
            padding: AppSpacing.lg.allPadding,
            borderWidth: 0,
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppSizes.iconSm,
                  color: context.colors.primary,
                ),
                AppSpacing.md.w,
                Text(
                  joinedDateText,
                  style: context.textTheme.bodyMedium?.semiBold(),
                ),
              ],
            ),
          ),
          AppSpacing.lg.h,

          // -------------------------------------------------------------------
          // 2. Company Biography Paragraph
          // -------------------------------------------------------------------
          Text(
            bioText,
            style: context.textTheme.bodySmall
                ?.lineHeight(1.5)
                .colour(context.colors.onSurfaceVariant),
          ),
          AppSpacing.xxxl.h,

          // -------------------------------------------------------------------
          // 3. Verified Documentation Section Header
          // -------------------------------------------------------------------
          Text(
            'VERIFIED DOC',
            style: context.textTheme.labelMedium
                ?.bold()
                .copyWith(letterSpacing: 1.2)
                .colour(context.colors.onSurfaceVariant),
          ),
          AppSpacing.md.h,

          // -------------------------------------------------------------------
          // 4. Read-Only Document Upload Cards
          // -------------------------------------------------------------------
          if (docs != null && docs.isEmpty)
            Padding(
              padding: AppSpacing.lg.yPadding,
              child: Center(
                child: Text(
                  'No verified documents available.',
                  style: context.textTheme.bodyMedium?.colour(
                    context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < effectiveDocs.length; i++) ...[
              _buildDocumentCard(context: context, doc: effectiveDocs[i]),
              if (i < effectiveDocs.length - 1) AppSpacing.md.h,
            ],
          AppSpacing.xl.h,
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required UserDocumentModel doc,
  }) {
    final title =
        doc.resolvedDocumentName ?? doc.fileName ?? 'Verified Document';
    final iconData = doc.documentType?.icon ?? Icons.description_outlined;

    return DocumentUploadCard(
      title: title,
      isReadOnly: true,
      showPreview: false,
      status: doc.status,
      initialUrl: doc.fileUrl,
      fileName: doc.fileName,
      icon: Icon(
        iconData,
        color: context.colors.primary,
        size: AppSizes.iconLg,
      ),
    );
  }
}
