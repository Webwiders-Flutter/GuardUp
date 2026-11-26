import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/api_error.extension.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/documents/documents.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/shared/models/record_owner.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// Screen allowing an authenticated Company to view their approved/pending business
/// documents in read-only mode and upload any new/un-submitted credentials.
class CompanyDocumentsScreen extends StatelessWidget {
  static const route = '/business-documents';

  const CompanyDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? (sl<AuthRepository>().currentUserId ?? '')
        : (context.read<AuthBloc>().state.user?.id ?? '');

    return BlocProvider(
      create: (_) => sl<DocumentsBloc>(
        param1: AccountOwner(currentUserId),
        param2: UserRole.company,
      )..add(const DocumentsStarted()),
      child: const _CompanyDocumentsView(),
    );
  }
}

class _CompanyDocumentsView extends StatelessWidget {
  const _CompanyDocumentsView();

  Future<void> _pickDocument(
    BuildContext context,
    DocumentTypeModel doc,
    DocumentsState state,
  ) async {
    final status = state.uploaded[doc.docKey]?.status;
    if (status == DocumentStatus.approved) {
      AppSnackbar.info(
        'This document is already verified and cannot be changed.',
      );
      return;
    }

    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: doc.allowCrop,
      allowFile: doc.allowFile,
    );

    if (picked != null && context.mounted) {
      context.read<DocumentsBloc>().add(DocumentPicked(doc.docKey, picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DocumentsBloc, DocumentsState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus.isSuccess) {
          AppSnackbar.success('New documents uploaded successfully');
        } else if (state.submitStatus.isFailure) {
          AppSnackbar.error(
            context.apiErrorText(
              state.submitStatus.errorOrNull,
              fallback: state.submitStatus.errorMessageOrNull,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppAppBar.transparent(
          title: context.l10n.businessDocuments,
          showBackIcon: true,
          fontSize: 14,
        ),
        body: SafeArea(
          child: BlocBuilder<DocumentsBloc, DocumentsState>(
            builder: (context, state) {
              if (state.loadStatus.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: context.colors.primary,
                  ),
                );
              }

              final docTypes = state.types;
              if (docTypes.isEmpty) {
                return Center(
                  child: Text(
                    'No document requirements found.',
                    style: context.textTheme.bodyMedium?.colour(
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              final uploadedDocs = state.uploaded;
              final newDocs = state.picked;
              final isUploading = state.submitStatus.isLoading;

              final uploadedTypes = docTypes
                  .where((d) => uploadedDocs.containsKey(d.docKey))
                  .toList();

              final pendingTypes = docTypes
                  .where((d) => !uploadedDocs.containsKey(d.docKey))
                  .toList();

              return SingleChildScrollView(
                padding: context.horizontalEdgeInsets + AppSpacing.lg.yPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Uploaded Documents Section
                    if (uploadedTypes.isNotEmpty) ...[
                      Text(
                        'Uploaded Documents',
                        style: context.textTheme.titleSmall?.semiBold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                      AppSpacing.xxs.h,
                      Text(
                        'Review status of your credentials. Tap Re-upload if rejected.',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.md.h,
                      ...uploadedTypes.map((doc) {
                        final key = doc.docKey;
                        final localFile = newDocs[key];
                        final remote = uploadedDocs[key]!;
                        final status = remote.status;
                        final rejectionReason = remote.rejectionReason;
                        final wasRejected = status == DocumentStatus.rejected;
                        final isResubmitted =
                            (wasRejected && localFile != null) ||
                            (status == DocumentStatus.pending &&
                                rejectionReason != null &&
                                rejectionReason.isNotEmpty);

                        return Padding(
                          padding: AppSpacing.md.bPadding,
                          child: DocumentUploadCard(
                            key: ValueKey('view_$key'),
                            title: doc.name,
                            description: doc.description,
                            icon: Icon(
                              doc.icon,
                              color: context.colors.primary,
                              size: AppSizes.iconLg,
                            ),
                            isRequired: doc.isRequired,
                            isReadOnly: status != DocumentStatus.rejected,
                            initialUrl: localFile == null
                                ? remote.fileUrl
                                : null,
                            selectedFilePath: localFile?.path,
                            fileName: localFile != null
                                ? localFile.name
                                : remote.fileName,
                            status: isResubmitted || localFile != null
                                ? DocumentStatus.pending
                                : status,
                            isResubmitted: isResubmitted,
                            statusLabel: isResubmitted ? 'Resubmitted' : null,
                            rejectionReason:
                                (isResubmitted || localFile != null)
                                ? null
                                : rejectionReason,
                            onPick: status == DocumentStatus.approved
                                ? null
                                : () => _pickDocument(context, doc, state),
                          ),
                        );
                      }),
                      AppSpacing.lg.h,
                    ],

                    // 2. Additional / Un-uploaded Documents Section
                    if (pendingTypes.isNotEmpty) ...[
                      Text(
                        'Add New Documents',
                        style: context.textTheme.titleSmall?.semiBold().colour(
                          context.colors.onSurface,
                        ),
                      ),
                      AppSpacing.xxs.h,
                      Text(
                        'Upload any optional or pending credentials.',
                        style: context.textTheme.bodySmall?.colour(
                          context.colors.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.md.h,
                      ...pendingTypes.map((doc) {
                        final key = doc.docKey;
                        final localFile = newDocs[key];

                        return Padding(
                          padding: AppSpacing.md.bPadding,
                          child: DocumentUploadCard(
                            key: ValueKey('upload_$key'),
                            title: doc.name,
                            description: doc.description,
                            icon: Icon(
                              doc.icon,
                              color: context.colors.primary,
                              size: AppSizes.iconLg,
                            ),
                            isRequired: doc.isRequired,
                            isOptional: !doc.isRequired,
                            isReadOnly: false,
                            selectedFilePath: localFile?.path,
                            onPick: () => _pickDocument(context, doc, state),
                          ),
                        );
                      }),
                      AppSpacing.lg.h,
                    ],

                    // 3. Save Button when new documents are selected
                    if (newDocs.isNotEmpty) ...[
                      AppButton(
                        text: 'Upload New Documents',
                        isLoading: isUploading,
                        onPressed: isUploading
                            ? null
                            : () => context.read<DocumentsBloc>().add(
                                const DocumentsSubmitted(
                                  submitApplication: false,
                                ),
                              ),
                      ),
                      AppSpacing.xl.h,
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
