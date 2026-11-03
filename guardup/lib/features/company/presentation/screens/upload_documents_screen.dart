import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/enum/doc_type.enum.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final ValueNotifier<Map<DocType, XFile>> _documentsNotifier =
      ValueNotifier<Map<DocType, XFile>>({});

  @override
  void dispose() {
    _documentsNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(DocType type) async {
    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: type.allowCrop,
      allowFile: type.allowFile,
    );

    if (picked != null && mounted) {
      _documentsNotifier.value = {
        ..._documentsNotifier.value,
        type: picked,
      };
    }
  }

  void _handleSubmit() {
    context.push(AppRoutes.registrationFee);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.transparent,
      appBar: AppAppBar.transparent(
        title: context.l10n.uploadDocuments,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: ValueListenableBuilder<Map<DocType, XFile>>(
                    valueListenable: _documentsNotifier,
                    builder: (context, docs, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.lg.h,

                          // 1. Business Registration
                          DocumentUploadCard(
                            title: DocType.businessRegistration.label(
                              context.l10n,
                            ),
                            icon: Icon(
                              DocType.businessRegistration.icon,
                              color: context.colors.primary,
                              size: 24,
                            ),
                            // selectedFilePath:
                            //     docs[DocType.businessRegistration]?.path,
                            onPick: () =>
                                _pickDocument(DocType.businessRegistration),
                          ),
                          AppSpacing.md.h,

                          // 2. Government ID (Admin)
                          DocumentUploadCard(
                            title: DocType.governmentId.label(context.l10n),
                            icon: Icon(
                              DocType.governmentId.icon,
                              color: context.colors.primary,
                              size: 24,
                            ),
                            selectedFilePath:
                                docs[DocType.governmentId]?.path,
                            onPick: () =>
                                _pickDocument(DocType.governmentId),
                          ),
                          AppSpacing.md.h,

                          // 3. Company Logo
                          DocumentUploadCard(
                            title: DocType.companyLogo.label(context.l10n),
                            icon: Icon(
                              DocType.companyLogo.icon,
                              color: context.colors.primary,
                              size: 24,
                            ),
                            selectedFilePath:
                                docs[DocType.companyLogo]?.path,
                            onPick: () =>
                                _pickDocument(DocType.companyLogo),
                          ),
                          AppSpacing.md.h,

                          // 4. Additional Documents
                          DocumentUploadCard(
                            title: DocType.additionalDocuments.label(
                              context.l10n,
                            ),
                            icon: Icon(
                              DocType.additionalDocuments.icon,
                              color: context.colors.primary,
                              size: 24,
                            ),
                            onUpload: () {},
                            selectedFilePath:
                                docs[DocType.additionalDocuments]?.path,
                            onPick: () =>
                                _pickDocument(DocType.additionalDocuments),
                          ),

                          const Spacer(),
                          AppSpacing.lg.h,

                          // Upload Documents Button
                          AppButton(
                            text: context.l10n.uploadDocuments,
                            size: ButtonSize.large,
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

