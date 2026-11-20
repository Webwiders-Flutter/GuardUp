import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_radius.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/extensions/textstyle_extension.dart';
import 'package:guardup/core/services/document_submission/document_submission_service.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/model/document_type.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/features/payments/presentation/screens/registration_fee_screen.dart';

class UploadDocumentsScreen extends StatefulWidget {
  static const route = '/upload-documents';

  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final ValueNotifier<List<DocumentTypeModel>> _docTypesNotifier =
      ValueNotifier<List<DocumentTypeModel>>([]);
  final ValueNotifier<Map<String, XFile>> _documentsNotifier =
      ValueNotifier<Map<String, XFile>>({});
  final ValueNotifier<Map<String, String>> _remoteDocsNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<Map<String, String>> _remoteFileNamesNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<Map<String, DocumentStatus>> _remoteStatusesNotifier =
      ValueNotifier<Map<String, DocumentStatus>>({});
  final ValueNotifier<Map<String, String>> _rejectionReasonsNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadDocumentTypesAndFiles();
  }

  Future<void> _loadDocumentTypesAndFiles() async {
    try {
      final docService = sl<DocumentSubmissionService>();
      final types = await docService.getDocumentTypes(UserRole.company);
      if (mounted) _docTypesNotifier.value = types;

      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;
      if (currentUserId != null) {
        final records = await docService.getUserDocuments(currentUserId);
        if (mounted) {
          _remoteDocsNotifier.value = records.urls;
          _remoteFileNamesNotifier.value = records.names;
          _remoteStatusesNotifier.value = records.statuses;
          _rejectionReasonsNotifier.value = records.rejectionReasons;
        }
      }
    } catch (e) {
      debugPrint('Error loading company document types & files: $e');
    }
  }

  @override
  void dispose() {
    _docTypesNotifier.dispose();
    _documentsNotifier.dispose();
    _remoteDocsNotifier.dispose();
    _remoteFileNamesNotifier.dispose();
    _remoteStatusesNotifier.dispose();
    _rejectionReasonsNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(DocumentTypeModel doc) async {
    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: doc.allowCrop,
      allowFile: doc.allowFile,
    );

    if (picked != null && mounted) {
      _documentsNotifier.value = {
        ..._documentsNotifier.value,
        doc.docKey: picked,
      };
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoadingNotifier.value) return;

    final docTypes = _docTypesNotifier.value;
    final localDocs = _documentsNotifier.value;
    final remoteDocs = _remoteDocsNotifier.value;
    final remoteStatuses = _remoteStatusesNotifier.value;

    // 1. Ensure any rejected documents have an updated replacement file selected
    for (final doc in docTypes) {
      final key = doc.docKey;
      final status = remoteStatuses[key] ??
          (doc.code.isNotEmpty ? remoteStatuses[doc.code] : null);
      if (status == DocumentStatus.rejected && !localDocs.containsKey(key)) {
        AppSnackbar.error('Please upload an updated document for ${doc.name}');
        return;
      }
    }

    // 2. Validate required documents dynamically from database definitions
    for (final doc in docTypes.where((d) => d.isRequired)) {
      final key = doc.docKey;
      final hasLocal = localDocs.containsKey(key);
      final hasRemote =
          remoteDocs.containsKey(key) ||
          (doc.code.isNotEmpty && remoteDocs.containsKey(doc.code));
      if (!hasLocal && !hasRemote) {
        AppSnackbar.error('Please upload your ${doc.name}');
        return;
      }
    }

    _isLoadingNotifier.value = true;

    try {
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;

      if (currentUserId != null) {
        if (localDocs.isNotEmpty) {
          await sl<DocumentSubmissionService>().uploadDocuments(
            userId: currentUserId,
            documents: localDocs,
            docTypes: docTypes,
            isCompany: true,
          );
        } else {
          // Documents already uploaded & valid. Transition user status back to PENDING_APPROVAL
          await sl<DocumentSubmissionService>()
              .submitApplicationForReview(currentUserId);
        }
      }

      if (mounted) {
        _documentsNotifier.value = {};
        _isLoadingNotifier.value = false;
        await _loadDocumentTypesAndFiles();
        if (!mounted) return;

        final authState = sl.isRegistered<AuthBloc>()
            ? sl<AuthBloc>().state
            : null;
        final isPreviouslySubmitted =
            authState?.isRejected == true ||
            authState?.isPendingApproval == true;

        if (isPreviouslySubmitted) {
          AppSnackbar.success(
            localDocs.isNotEmpty
                ? 'Documents resubmitted successfully. Your application is under review.'
                : 'Application resubmitted successfully. Your profile is under review.',
          );
          context.go(AdminApprovalScreen.route);
        } else {
          context.go(RegistrationFeeScreen.route);
        }
      }
    } catch (e) {
      if (mounted) {
        _isLoadingNotifier.value = false;
        AppSnackbar.error('Failed to submit application: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: sl<AuthBloc>().state.isAuthenticated
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
                sl<AuthBloc>().add(const AuthSignOutRequested());
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
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _isLoadingNotifier,
                      _docTypesNotifier,
                      _documentsNotifier,
                      _remoteDocsNotifier,
                      _remoteFileNamesNotifier,
                      _remoteStatusesNotifier,
                      _rejectionReasonsNotifier,
                    ]),
                    builder: (context, _) {
                      final isLoading = _isLoadingNotifier.value;
                      final docTypes = _docTypesNotifier.value;
                      final docs = _documentsNotifier.value;
                      final remoteDocs = _remoteDocsNotifier.value;
                      final remoteNames = _remoteFileNamesNotifier.value;
                      final remoteStatuses = _remoteStatusesNotifier.value;
                      final rejectionReasons = _rejectionReasonsNotifier.value;

                      final hasRejectedDoc =
                          remoteStatuses.values.any(
                            (s) =>
                                s ==
                                DocumentStatus.rejected,
                          );

                      return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  AppSpacing.lg.h,

                                                  if (hasRejectedDoc) ...[
                                                    QuickContainer(
                                                      p: AppSpacing.md,
                                                      radius: AppRadius.md,
                                                      color: context
                                                          .colors
                                                          .error
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      border: Border.all(
                                                        color: context
                                                            .colors
                                                            .error
                                                            .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                        width: 1,
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .warning_amber_rounded,
                                                            color: context
                                                                .colors
                                                                .error,
                                                            size: 22,
                                                          ),
                                                          AppSpacing.sm.w,
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Revisions Required',
                                                                  style: context
                                                                      .textTheme
                                                                      .labelMedium
                                                                      ?.bold()
                                                                      .colour(
                                                                        context
                                                                            .colors
                                                                            .error,
                                                                      ),
                                                                ),
                                                                AppSpacing
                                                                    .xxs
                                                                    .h,
                                                                Text(
                                                                  'One or more documents were rejected by compliance. Please review the reasons below, re-upload clear copies, and resubmit.',
                                                                  style: context
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.colour(
                                                                        context
                                                                            .colors
                                                                            .onSurface,
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
                                                    final remoteUrl =
                                                        remoteDocs[key] ??
                                                        (doc.code.isNotEmpty
                                                            ? remoteDocs[doc
                                                                  .code]
                                                            : null);
                                                    final remoteName =
                                                        remoteNames[key] ??
                                                        (doc.code.isNotEmpty
                                                            ? remoteNames[doc
                                                                  .code]
                                                            : null);
                                                    final remoteStatus =
                                                        remoteStatuses[key] ??
                                                        (doc.code.isNotEmpty
                                                            ? remoteStatuses[doc
                                                                  .code]
                                                            : null);
                                                    final rejectionReason =
                                                        rejectionReasons[key] ??
                                                        (doc.code.isNotEmpty
                                                            ? rejectionReasons[doc
                                                                  .code]
                                                            : null);

                                                    final wasRejected =
                                                        remoteStatus ==
                                                        DocumentStatus.rejected;
                                                    final isResubmitted =
                                                        (wasRejected &&
                                                                localFile !=
                                                                    null) ||
                                                            (remoteStatus ==
                                                                    DocumentStatus
                                                                        .pending &&
                                                                rejectionReason !=
                                                                    null &&
                                                                rejectionReason
                                                                    .isNotEmpty);

                                                    return Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        DocumentUploadCard(
                                                          key: ValueKey(
                                                            'doc_$key',
                                                          ),
                                                          title: doc.name,
                                                          description:
                                                              doc.description,
                                                          icon: Icon(
                                                            doc.icon,
                                                            color: context
                                                                .colors
                                                                .primary,
                                                            size:
                                                                AppSizes.iconLg,
                                                          ),
                                                          isRequired:
                                                              doc.isRequired,
                                                          isOptional:
                                                              !doc.isRequired,
                                                          isLoading: false,
                                                          initialUrl:
                                                              localFile == null
                                                                  ? remoteUrl
                                                                  : null,
                                                          fileName: localFile !=
                                                                  null
                                                              ? localFile.name
                                                              : remoteName,
                                                          selectedFilePath:
                                                              localFile?.path,
                                                          status:
                                                              isResubmitted ||
                                                              localFile != null
                                                              ? DocumentStatus
                                                                    .pending
                                                              : remoteStatus,
                                                          isResubmitted:
                                                              isResubmitted,
                                                          statusLabel:
                                                              isResubmitted
                                                              ? 'Resubmitted'
                                                              : null,
                                                          rejectionReason:
                                                              (isResubmitted ||
                                                                      localFile !=
                                                                          null)
                                                              ? null
                                                              : rejectionReason,
                                                          onPick: () =>
                                                              _pickDocument(
                                                                doc,
                                                              ),
                                                        ),
                                                        AppSpacing.md.h,
                                                      ],
                                                    );
                                                  }),

                                                  const Spacer(),
                                                  AppSpacing.lg.h,

                                                  // Upload Documents Button
                                                  AppButton(
                                                    text: context
                                                        .l10n
                                                        .uploadDocuments,
                                                    isLoading: isLoading,
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
