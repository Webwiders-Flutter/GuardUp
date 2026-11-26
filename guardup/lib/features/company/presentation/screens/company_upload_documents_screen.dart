import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/api_error.extension.dart';
import 'package:guardup/core/extensions/textstyle_extension.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:guardup/features/documents/documents.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/payments/presentation/screens/registration_fee_screen.dart';
import '/shared/models/record_owner.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';

class UploadDocumentsScreen extends StatelessWidget {
  static const route = '/upload-documents';

  const UploadDocumentsScreen({super.key});

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
      child: const _CompanyUploadDocumentsView(),
    );
  }
}

class _CompanyUploadDocumentsView extends StatelessWidget {
  const _CompanyUploadDocumentsView();

  Future<void> _pickDocument(
    BuildContext context,
    DocumentTypeModel doc,
    DocumentsState state,
  ) async {
    final remoteDoc = state.uploaded[doc.docKey];
    if (remoteDoc?.status == DocumentStatus.approved) {
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

  void _handleSubmit(BuildContext context, DocumentsState state) {
    if (state.submitStatus.isLoading) return;

    // 1. Ensure any rejected documents have an updated replacement file selected
    for (final doc in state.types) {
      final remote = state.uploaded[doc.docKey];
      if (remote?.status == DocumentStatus.rejected &&
          !state.picked.containsKey(doc.docKey)) {
        AppSnackbar.error('Please upload an updated document for ${doc.name}');
        return;
      }
    }

    // 2. Validate required documents dynamically from database definitions
    for (final doc in state.types.where((d) => d.isRequired)) {
      final hasLocal = state.picked.containsKey(doc.docKey);
      final hasRemote = state.uploaded.containsKey(doc.docKey);
      if (!hasLocal && !hasRemote) {
        AppSnackbar.error('Please upload your ${doc.name}');
        return;
      }
    }

    context.read<DocumentsBloc>().add(
      const DocumentsSubmitted(submitApplication: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select(
      (AuthBloc b) => b.state.isAuthenticated,
    );

    return BlocListener<DocumentsBloc, DocumentsState>(
      listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
      listener: (context, state) {
        if (state.submitStatus.isSuccess) {
          final authState = context.read<AuthBloc>().state;
          final isPreviouslySubmitted =
              authState.isRejected || authState.isPendingApproval;

          if (isPreviouslySubmitted) {
            AppSnackbar.success(
              'Documents resubmitted successfully. Your application is under review.',
            );
            context.go(AdminApprovalScreen.route);
          } else {
            context.go(RegistrationFeeScreen.route);
          }
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
          title: isAuthenticated
              ? context.l10n.businessDocuments
              : context.l10n.uploadDocuments,
          fontSize: 14,
          actions: [
            IconButton(
              tooltip: context.l10n.logOut,
              icon: Icon(
                Icons.logout_rounded,
                color: context.colors.error,
                size: AppSizes.iconSmd,
              ),
              onPressed: () async {
                final result = await AppPopup.showLogoutConfirmation(context);
                if (result?.action == PopupAction.confirm && context.mounted) {
                  context.read<AuthBloc>().add(const AuthSignOutRequested());
                  context.go(LoginScreen.route);
                }
              },
            ),
            AppSpacing.xs.w,
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
                    child: BlocBuilder<DocumentsBloc, DocumentsState>(
                      builder: (context, state) {
                        final isLoading = state.submitStatus.isLoading;
                        final docTypes = state.types;
                        final docs = state.picked;
                        final uploadedDocs = state.uploaded;
                        final hasRejectedDoc = state.hasRejectedDoc;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppSpacing.lg.h,

                            if (hasRejectedDoc) ...[
                              QuickContainer(
                                p: AppSpacing.md,
                                radius: AppRadius.md,
                                color: context.colors.error.withValues(
                                  alpha: 0.12,
                                ),
                                border: Border.all(
                                  color: context.colors.error.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 1,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: context.colors.error,
                                      size: 22,
                                    ),
                                    AppSpacing.sm.w,
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Revisions Required',
                                            style: context.textTheme.labelMedium
                                                ?.bold()
                                                .colour(context.colors.error),
                                          ),
                                          AppSpacing.xxs.h,
                                          Text(
                                            'One or more documents were rejected by compliance. Please review the reasons below, re-upload clear copies, and resubmit.',
                                            style: context.textTheme.bodySmall
                                                ?.colour(
                                                  context.colors.onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.md.h,
                            ],

                            ...docTypes.map((doc) {
                              final key = doc.docKey;
                              final localFile = docs[key];
                              final remote = uploadedDocs[key];
                              final remoteUrl = remote?.fileUrl;
                              final remoteName = remote?.fileName;
                              final remoteStatus = remote?.status;
                              final rejectionReason = remote?.rejectionReason;

                              final wasRejected =
                                  remoteStatus == DocumentStatus.rejected;
                              final isVerified =
                                  remoteStatus == DocumentStatus.approved;
                              final isResubmitted =
                                  (wasRejected && localFile != null) ||
                                  (remoteStatus == DocumentStatus.pending &&
                                      rejectionReason != null &&
                                      rejectionReason.isNotEmpty);

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DocumentUploadCard(
                                    key: ValueKey('doc_$key'),
                                    title: doc.name,
                                    description: doc.description,
                                    icon: Icon(
                                      doc.icon,
                                      color: context.colors.primary,
                                      size: AppSizes.iconLg,
                                    ),
                                    isRequired: doc.isRequired,
                                    isOptional: !doc.isRequired,
                                    isLoading: false,
                                    isReadOnly: isVerified,
                                    initialUrl: localFile == null
                                        ? remoteUrl
                                        : null,
                                    fileName: localFile != null
                                        ? localFile.name
                                        : remoteName,
                                    selectedFilePath: localFile?.path,
                                    status: isResubmitted || localFile != null
                                        ? DocumentStatus.pending
                                        : remoteStatus,
                                    isResubmitted: isResubmitted,
                                    statusLabel: isResubmitted
                                        ? 'Resubmitted'
                                        : null,
                                    rejectionReason:
                                        (isResubmitted || localFile != null)
                                            ? null
                                            : rejectionReason,
                                    onPick: isVerified
                                        ? null
                                        : () =>
                                              _pickDocument(context, doc, state),
                                  ),
                                  AppSpacing.md.h,
                                ],
                              );
                            }),

                            const Spacer(),
                            AppSpacing.lg.h,

                            // Upload Documents Button
                            AppButton(
                              text: context.l10n.uploadDocuments,
                              isLoading: isLoading,
                              onPressed: () => _handleSubmit(context, state),
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
      ),
    );
  }
}
