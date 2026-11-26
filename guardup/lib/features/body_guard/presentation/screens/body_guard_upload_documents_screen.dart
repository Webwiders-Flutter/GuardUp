import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_container/quick_container.dart';

import '../../../../core/di/injection_container.dart';
import '../../../auth/auth.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/api_error.extension.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/documents/documents.dart';
import '/features/payments/presentation/screens/registration_fee_screen.dart';
import '/shared/models/record_owner.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/enum/document_status.enum.dart';
import '../../data/model/body_guard.model.dart';

/// Screen for bodyguard verification credentials and document upload.
///
/// Uses [DocumentsBloc] for fetching active document types, tracking local picks,
/// uploading files, and submitting for compliance review.
class BodyGuardUploadDocumentsScreen extends StatelessWidget {
  static const route = '/bodyguard-upload-documents';

  final BodyGuardModel? bodyguard;

  const BodyGuardUploadDocumentsScreen({super.key, this.bodyguard});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isGuard = authState.isGuard;
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? (sl<AuthRepository>().currentUserId ?? '')
        : (authState.user?.id ?? '');

    final RecordOwner owner = isGuard
        ? AccountOwner(currentUserId)
        : ManagedBodyguardOwner(bodyguard?.id ?? '');

    return BlocProvider(
      create: (_) => sl<DocumentsBloc>(
        param1: owner,
        param2: UserRole.guard,
      )..add(const DocumentsStarted()),
      child: _BodyGuardUploadDocumentsView(
        bodyguard: bodyguard,
        isGuard: isGuard,
      ),
    );
  }
}

class _BodyGuardUploadDocumentsView extends StatelessWidget {
  final BodyGuardModel? bodyguard;
  final bool isGuard;

  const _BodyGuardUploadDocumentsView({
    this.bodyguard,
    required this.isGuard,
  });

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

    // 2. Validate required documents dynamically from docTypes
    for (final doc in state.types.where((d) => d.isRequired)) {
      final hasLocal = state.picked.containsKey(doc.docKey);
      final hasRemote = state.uploaded.containsKey(doc.docKey);
      if (!hasLocal && !hasRemote) {
        AppSnackbar.error('Please upload your ${doc.name}');
        return;
      }
    }

    if (!isGuard && (bodyguard?.id.isEmpty ?? true)) {
      AppSnackbar.error('Please save the bodyguard details first.');
      return;
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
          if (isGuard) {
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
          } else {
            AppSnackbar.success(
              bodyguard?.verificationStatus == UserStatus.active
                  ? 'Bodyguard updated successfully.'
                  : 'Bodyguard submitted for admin review.',
            );
            if (bodyguard?.verificationStatus != UserStatus.active) {
              context.go(
                AdminApprovalScreen.route,
                extra: {
                  'bodyguard': bodyguard,
                  'isCompanyBodyguardFlow': true,
                },
              );
            } else {
              context.pop(true);
            }
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
          title: context.l10n.uploadDocuments,
          alignTitle: isAuthenticated ? .right : .center,
          actions: isGuard
              ? [
                  IconButton(
                    tooltip: context.l10n.logOut,
                    icon: Icon(
                      Icons.logout_rounded,
                      color: context.colors.error,
                      size: AppSizes.iconSmd,
                    ),
                    onPressed: () async {
                      final result = await AppPopup.showLogoutConfirmation(
                        context,
                      );
                      if (result?.action == PopupAction.confirm &&
                          context.mounted) {
                        context.read<AuthBloc>().add(
                          const AuthSignOutRequested(),
                        );
                        context.go(LoginScreen.route);
                      }
                    },
                  ),
                  AppSpacing.xs.w,
                ]
              : null,
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
                        if (state.loadStatus.isLoading) {
                          return Center(
                            child: Padding(
                              padding: AppSpacing.xxl.allPadding,
                              child: CircularProgressIndicator(
                                color: context.colors.primary,
                              ),
                            ),
                          );
                        }

                        final isSubmitting = state.submitStatus.isLoading;
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
                                            'One or more documents were rejected by the compliance team. Please review the reasons highlighted below, select updated files, and resubmit.',
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

                            // Dynamic Document Types from Supabase
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
                                  AppSpacing.lg.h,
                                ],
                              );
                            }),

                            // 4. 256-Bit Encrypted & Compliant Security Notice
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

                            // 5. Submit for Review Button
                            AppButton(
                              text: 'Submit for Review',
                              isLoading: isSubmitting,
                              trailing: Icon(
                                Icons.arrow_forward_rounded,
                                size: AppSizes.iconMd,
                                color: context.colors.onPrimary,
                              ),
                              onPressed: () => _handleSubmit(context, state),
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
      ),
    );
  }
}
