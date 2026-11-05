import 'package:flutter/material.dart';
import 'package:guardup/features/company/data/enum/company_doc_type.enum.dart';
import 'package:intl/intl.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/model/document.model.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../../data/model/company.model.dart';

/// Tab content rendering company biography, membership tenure, and verified business documentation.
class CompanyAboutTab extends StatelessWidget {
  final CompanyModel? company;

  const CompanyAboutTab({super.key, this.company});

  static const String _defaultBio =
      "Lorem Ipsum is simply dummy text of the printing and typesetting industry. "
      "Lorem Ipsum has been the industry's standard dummy text ever since 1966, "
      "when designers at Letraset and James Mosley, the librarian at St Bride Printing Library in London, "
      "took a 1914 Cicero translation and scrambled it to make dummy text for Letraset's Body Type sheets. "
      "It has survived not only many decades, but also the leap into electronic typesetting, remaining essentially unchanged.";

  @override
  Widget build(BuildContext context) {
    final joinedDateText = company?.joinedAt != null
        ? 'Joined ${DateFormat('dd MMM , yyyy').format(company!.joinedAt!)}'
        : 'Joined 25 aug , 2024';

    final effectiveDocs = DocumentModel.fakeData;

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
            company?.bio ?? _defaultBio,
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
          for (int i = 0; i < CompanyDocType.values.length; i++) ...[
            _buildDocumentCard(
              context: context,
              spec: (
                icon: CompanyDocType.values[i].icon,
                title: CompanyDocType.values[i].label(context.l10n),
              ),
              docModel: i < effectiveDocs.length ? effectiveDocs[i] : null,
            ),
            if (i < CompanyDocType.values.length - 1) AppSpacing.md.h,
          ],
          AppSpacing.xl.h,
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required BuildContext context,
    required ({String title, IconData icon}) spec,
    required DocumentModel? docModel,
  }) {
    return DocumentUploadCard(
      title: spec.title,
      isReadOnly: true,
      showPreview: false,
      status: docModel?.status ?? DocumentStatus.approved,
      initialUrl: docModel?.url,
      fileName: docModel?.fileName,
      icon: Icon(
        spec.icon,
        color: context.colors.primary,
        size: AppSizes.iconLg,
      ),
    );
  }
}
