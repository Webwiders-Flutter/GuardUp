import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/guard_doc_type.enum.dart';

/// Screen for bodyguard verification credentials and document upload.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Component Reuse: [DocumentUploadCard], [AppButton], [AppAppBar], [AppRichText].
/// - Theming: strictly uses context extensions ([context.colors], [context.textTheme], [AppSpacing]).
class BodyGuardUploadDocumentsScreen extends StatefulWidget {
  const BodyGuardUploadDocumentsScreen({super.key});

  @override
  State<BodyGuardUploadDocumentsScreen> createState() =>
      _BodyGuardUploadDocumentsScreenState();
}

class _BodyGuardUploadDocumentsScreenState
    extends State<BodyGuardUploadDocumentsScreen> {
  /// Reactive state holding selected documents per document type.
  final ValueNotifier<Map<GuardDocType, XFile>> _documentsNotifier =
      ValueNotifier<Map<GuardDocType, XFile>>({});

  @override
  void dispose() {
    _documentsNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(GuardDocType type) async {
    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: false,
      allowFile: true,
    );

    if (picked != null && mounted) {
      _documentsNotifier.value = {..._documentsNotifier.value, type: picked};
    }
  }

  void _handleSubmit() {
    context.push(AppRoutes.registrationFee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.uploadDocuments,
        alignTitle: .center,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: QuickContainer(
              w: 36,
              h: 36,
              shape: QuickContainerShape.circle,
              color: context.colors.surfaceContainerHigh.withValues(alpha: 0.5),
              border: Border.all(
                color: context.colors.outlineVariant.withValues(alpha: 0.6),
                width: 1,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.help_outline_rounded,
                size: AppSizes.iconSmd,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: ValueListenableBuilder<Map<GuardDocType, XFile>>(
                    valueListenable: _documentsNotifier,
                    builder: (context, docs, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.lg.h,

                          // 1. Partner Tag
                          Row(
                            children: [
                              QuickContainer(
                                w: 8,
                                h: 8,
                                shape: QuickContainerShape.circle,
                                color: context.colors.primary,
                              ),
                              AppSpacing.xs.w,
                              Text(
                                'ELITE PROTECTION PARTNER',
                                style: context.textTheme.labelSmall
                                    ?.bold()
                                    .copyWith(
                                      color: context.colors.primary,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ],
                          ),
                          AppSpacing.sm.h,

                          // 2. Main Heading
                          Text(
                            'Verification Credentials',
                            style: context.textTheme.headlineMedium?.bold(),
                          ),
                          AppSpacing.sm.h,

                          // 3. Subtitle Description
                          Text(
                            'Submit your official documentation to unlock high-tier VIP assignments & priority instant payouts.',
                            style: context.textTheme.bodyMedium?.colour(
                              context.colors.onSurfaceVariant,
                            ),
                          ),
                          AppSpacing.lg.h,

                          // 4. ID Proof Card
                          DocumentUploadCard(
                            title: GuardDocType.idProof.label(context.l10n),
                            description: GuardDocType.idProof.description(
                              context.l10n,
                            ),
                            icon: Icon(
                              GuardDocType.idProof.icon,
                              color: context.colors.primary,
                            ),
                            iconWidget: Icon(
                              Icons.info_outline,
                              size: AppSizes.iconSm,
                              color: context.colors.onSurfaceVariant,
                            ),
                            selectedFilePath: docs[GuardDocType.idProof]?.path,
                            onPick: () => _pickDocument(GuardDocType.idProof),
                          ),
                          AppSpacing.lg.h,

                          // 5. Police Verification Card
                          DocumentUploadCard(
                            title: GuardDocType.policeVerification.label(
                              context.l10n,
                            ),
                            description: GuardDocType.policeVerification
                                .description(context.l10n),
                            icon: Icon(
                              GuardDocType.policeVerification.icon,
                              color: context.colors.primary,
                            ),
                            iconWidget: Icon(
                              Icons.check_circle_rounded,
                              size: AppSizes.iconSm,
                              color: context.colors.success,
                            ),
                            selectedFilePath:
                                docs[GuardDocType.policeVerification]?.path,
                            onPick: () =>
                                _pickDocument(GuardDocType.policeVerification),
                          ),
                          AppSpacing.lg.h,

                          // 6. Security License Card (Required with REQ badge & Upload action)
                          DocumentUploadCard(
                            title: GuardDocType.securityLicense.label(
                              context.l10n,
                            ),
                            description: GuardDocType.securityLicense
                                .description(context.l10n),
                            icon: Icon(
                              GuardDocType.securityLicense.icon,
                              color: context.colors.primary,
                            ),
                            isRequired: true,
                            showUploadButton: true,
                            selectedFilePath:
                                docs[GuardDocType.securityLicense]?.path,
                            onPick: () =>
                                _pickDocument(GuardDocType.securityLicense),
                          ),
                          AppSpacing.lg.h,

                          // 7. Certifications Card (Optional with '+' button)
                          DocumentUploadCard(
                            title: GuardDocType.certifications.label(
                              context.l10n,
                            ),
                            description: GuardDocType.certifications
                                .description(context.l10n),
                            icon: Icon(
                              GuardDocType.certifications.icon,
                              color: context.colors.primary,
                            ),
                            isOptional: true,
                            selectedFilePath:
                                docs[GuardDocType.certifications]?.path,
                            onPick: () =>
                                _pickDocument(GuardDocType.certifications),
                          ),
                          AppSpacing.xl.h,

                          // 8. 256-Bit Encrypted & Compliant Security Notice
                          WrapperCard(
                            padding: AppSpacing.md.allPadding,
                            borderRadius: AppRadius.md,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                QuickContainer(
                                  w: 36,
                                  h: 36,
                                  radius: AppRadius.sm,
                                  color: context.colors.surfaceContainerHigh
                                      .withValues(alpha: 0.5),
                                  border: Border.all(
                                    color: context.colors.outlineVariant
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    size: AppSizes.iconSmd,
                                    color: context.colors.primary,
                                  ),
                                ),
                                AppSpacing.sm.w,
                                Expanded(
                                  child: AppRichText(
                                    spans: [
                                      AppTextSpan(
                                        text: '256-Bit Encrypted & Compliant: ',
                                        fontWeight: FontWeight.bold,
                                        color: context.colors.onSurface,
                                        fontSize: 12,
                                      ),
                                      AppTextSpan(
                                        text: 'Documents are stored in an encrypted vault and reviewed only by authorized government compliance officers.',
                                        color: context.colors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                          AppSpacing.lg.h,

                          // 9. Submit for Review Button
                          AppButton(
                            text: 'Submit for Review',
                            trailing: Icon(
                              Icons.arrow_forward_rounded,
                              size: AppSizes.iconMd,
                              color: context.colors.onPrimary,
                            ),

                            onPressed: _handleSubmit,
                          ),
                          AppSpacing.huge.h,
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
