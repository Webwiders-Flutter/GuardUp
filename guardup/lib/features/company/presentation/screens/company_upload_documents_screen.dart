import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:image_picker/image_picker.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '../../data/enum/company_doc_type.enum.dart';

class UploadDocumentsScreen extends StatefulWidget {
  static const route = '/upload-documents';

  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final ValueNotifier<Map<CompanyDocType, XFile>> _documentsNotifier =
      ValueNotifier<Map<CompanyDocType, XFile>>({});

  @override
  void dispose() {
    _documentsNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(CompanyDocType type) async {
    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: type.allowCrop,
      allowFile: type.allowFile,
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
        title: sl<AuthBloc>().state.isAuthenticated
            ? context.l10n.businessDocuments
            : context.l10n.uploadDocuments,
        fontSize: 14,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: context.horizontalEdgeInsets,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: ValueListenableBuilder<Map<CompanyDocType, XFile>>(
                    valueListenable: _documentsNotifier,
                    builder: (context, docs, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSpacing.lg.h,

                          ...CompanyDocType.values.map(
                            (x) => Column(
                              mainAxisSize: .min,
                              children: [
                                DocumentUploadCard(
                                  title: x.label(context.l10n),
                                  icon: Icon(
                                    x.icon,
                                    color: context.colors.primary,
                                    size: AppSizes.iconLg,
                                  ),
                                  selectedFilePath: docs[x]?.path,
                                  onPick: () => _pickDocument(x),
                                ),
                                AppSpacing.md.h,
                              ],
                            ),
                          ),

                          const Spacer(),
                          AppSpacing.lg.h,

                          // Upload Documents Button
                          AppButton(
                            text: context.l10n.uploadDocuments,

                            onPressed: _handleSubmit,
                          ),
                          AppSpacing.xl.h,
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
