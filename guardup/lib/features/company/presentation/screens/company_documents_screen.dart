import 'package:flutter/material.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/logger/app_logger.dart';
import 'package:guardup/core/services/document_submission/document_submission_service.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:image_picker/image_picker.dart';

import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/model/document_type.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';

/// Screen allowing an authenticated Company to view their approved/pending business
/// documents in read-only mode and upload any new/un-submitted credentials.
class CompanyDocumentsScreen extends StatefulWidget {
  static const route = '/business-documents';

  const CompanyDocumentsScreen({super.key});

  @override
  State<CompanyDocumentsScreen> createState() => _CompanyDocumentsScreenState();
}

class _CompanyDocumentsScreenState extends State<CompanyDocumentsScreen> {
  final ValueNotifier<List<DocumentTypeModel>> _docTypesNotifier =
      ValueNotifier<List<DocumentTypeModel>>([]);
  final ValueNotifier<Map<String, XFile>> _newDocumentsNotifier =
      ValueNotifier<Map<String, XFile>>({});
  final ValueNotifier<Map<String, String>> _remoteDocsNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<Map<String, String>> _remoteFileNamesNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<Map<String, DocumentStatus>> _remoteStatusesNotifier =
      ValueNotifier<Map<String, DocumentStatus>>({});
  final ValueNotifier<Map<String, String>> _rejectionReasonsNotifier =
      ValueNotifier<Map<String, String>>({});
  final ValueNotifier<bool> _isInitialLoadingNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<bool> _isUploadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadDocumentTypesAndFiles();
  }

  @override
  void dispose() {
    _docTypesNotifier.dispose();
    _newDocumentsNotifier.dispose();
    _remoteDocsNotifier.dispose();
    _remoteFileNamesNotifier.dispose();
    _remoteStatusesNotifier.dispose();
    _rejectionReasonsNotifier.dispose();
    _isInitialLoadingNotifier.dispose();
    _isUploadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentTypesAndFiles() async {
    _isInitialLoadingNotifier.value = true;
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
    } catch (e, st) {
      AppLogger.d('Error loading company documents: $e', tag: 'CompanyDocumentsScreen', error: e, stackTrace: st);
    } finally {
      if (mounted) _isInitialLoadingNotifier.value = false;
    }
  }

  Future<void> _pickDocument(DocumentTypeModel doc) async {
    final key = doc.docKey;
    final status = _remoteStatusesNotifier.value[key] ??
        (doc.code.isNotEmpty ? _remoteStatusesNotifier.value[doc.code] : null);
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

    if (picked != null && mounted) {
      _newDocumentsNotifier.value = {
        ..._newDocumentsNotifier.value,
        doc.docKey: picked,
      };
    }
  }

  Future<void> _handleUploadNewDocuments() async {
    final newDocs = _newDocumentsNotifier.value;
    if (newDocs.isEmpty || _isUploadingNotifier.value) return;

    _isUploadingNotifier.value = true;
    try {
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;

      if (currentUserId == null) return;

      await sl<DocumentSubmissionService>().uploadDocuments(
        userId: currentUserId,
        documents: newDocs,
        docTypes: _docTypesNotifier.value,
        isCompany: true,
      );

      if (mounted) {
        _newDocumentsNotifier.value = {};
        AppSnackbar.success('New documents uploaded successfully');
        await _loadDocumentTypesAndFiles();
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to upload document: $e');
      }
    } finally {
      if (mounted) _isUploadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.businessDocuments,
        showBackIcon: true,
        fontSize: 14,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            _isInitialLoadingNotifier,
            _docTypesNotifier,
            _remoteDocsNotifier,
            _remoteFileNamesNotifier,
            _remoteStatusesNotifier,
            _rejectionReasonsNotifier,
            _newDocumentsNotifier,
            _isUploadingNotifier,
          ]),
          builder: (context, _) {
            final isInitialLoading = _isInitialLoadingNotifier.value;
            if (isInitialLoading) {
              return Center(
                child: CircularProgressIndicator(color: context.colors.primary),
              );
            }

            final docTypes = _docTypesNotifier.value;
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

            final remoteDocs = _remoteDocsNotifier.value;
            final remoteNames = _remoteFileNamesNotifier.value;
            final remoteStatuses = _remoteStatusesNotifier.value;
            final rejectionReasons = _rejectionReasonsNotifier.value;
            final newDocs = _newDocumentsNotifier.value;
            final isUploading = _isUploadingNotifier.value;

            final uploadedTypes = docTypes.where((
              d,
            ) {
              final key = d.docKey;
              return remoteDocs.containsKey(key) ||
                  (d.code.isNotEmpty &&
                      remoteDocs.containsKey(
                        d.code,
                      ));
            }).toList();

            final pendingTypes = docTypes.where((
              d,
            ) {
              final key = d.docKey;
              final hasRemote =
                  remoteDocs.containsKey(key) ||
                  (d.code.isNotEmpty &&
                      remoteDocs.containsKey(
                        d.code,
                      ));
              return !hasRemote;
            }).toList();

            return SingleChildScrollView(
                                          padding:
                                              context.horizontalEdgeInsets +
                                              AppSpacing.lg.yPadding,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // 1. Uploaded Documents Section
                                              if (uploadedTypes.isNotEmpty) ...[
                                                Text(
                                                  'Uploaded Documents',
                                                  style: context
                                                      .textTheme
                                                      .titleSmall
                                                      ?.semiBold()
                                                      .colour(
                                                        context
                                                            .colors
                                                            .onSurface,
                                                      ),
                                                ),
                                                AppSpacing.xxs.h,
                                                Text(
                                                  'Review status of your credentials. Tap Re-upload if rejected.',
                                                  style: context
                                                      .textTheme
                                                      .bodySmall
                                                      ?.colour(
                                                        context
                                                            .colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                AppSpacing.md.h,
                                                ...uploadedTypes.map((doc) {
                                                  final key = doc.docKey;
                                                  final localFile =
                                                      newDocs[key];
                                                  final remoteUrl =
                                                      remoteDocs[key] ??
                                                      remoteDocs[doc.code];
                                                  final remoteName =
                                                      remoteNames[key] ??
                                                      remoteNames[doc.code];
                                                  final status =
                                                      remoteStatuses[key] ??
                                                      remoteStatuses[doc.code];
                                                  final rejectionReason =
                                                      rejectionReasons[key] ??
                                                      rejectionReasons[doc
                                                          .code];
                                                  final wasRejected =
                                                      status ==
                                                      DocumentStatus.rejected;
                                                  final isResubmitted =
                                                      (wasRejected &&
                                                          localFile != null) ||
                                                      (status ==
                                                              DocumentStatus
                                                                  .pending &&
                                                          rejectionReason !=
                                                              null &&
                                                          rejectionReason
                                                              .isNotEmpty);

                                                  return Padding(
                                                    padding:
                                                        AppSpacing.md.bPadding,
                                                    child: DocumentUploadCard(
                                                      key: ValueKey(
                                                        'view_$key',
                                                      ),
                                                      title: doc.name,
                                                      description:
                                                          doc.description,
                                                      icon: Icon(
                                                        doc.icon,
                                                        color: context
                                                            .colors
                                                            .primary,
                                                        size: AppSizes.iconLg,
                                                      ),
                                                      isRequired:
                                                          doc.isRequired,
                                                      isReadOnly:
                                                          status !=
                                                          DocumentStatus
                                                              .rejected,
                                                      initialUrl:
                                                          localFile == null
                                                          ? remoteUrl
                                                          : null,
                                                      selectedFilePath:
                                                          localFile?.path,
                                                      fileName:
                                                          localFile != null
                                                          ? localFile.name
                                                          : remoteName,
                                                      status:
                                                          isResubmitted ||
                                                              localFile != null
                                                          ? DocumentStatus
                                                                .pending
                                                          : status,
                                                      isResubmitted:
                                                          isResubmitted,
                                                      statusLabel: isResubmitted
                                                          ? 'Resubmitted'
                                                          : null,
                                                      rejectionReason:
                                                          (isResubmitted ||
                                                              localFile != null)
                                                          ? null
                                                          : rejectionReason,
                                                      onPick: status ==
                                                              DocumentStatus
                                                                  .approved
                                                          ? null
                                                          : () =>
                                                              _pickDocument(
                                                                doc,
                                                              ),
                                                    ),
                                                  );
                                                }),
                                                AppSpacing.lg.h,
                                              ],

                                              // 2. Additional / Un-uploaded Documents Section
                                              if (pendingTypes.isNotEmpty) ...[
                                                Text(
                                                  'Add New Documents',
                                                  style: context
                                                      .textTheme
                                                      .titleSmall
                                                      ?.semiBold()
                                                      .colour(
                                                        context
                                                            .colors
                                                            .onSurface,
                                                      ),
                                                ),
                                                AppSpacing.xxs.h,
                                                Text(
                                                  'Upload any optional or pending credentials.',
                                                  style: context
                                                      .textTheme
                                                      .bodySmall
                                                      ?.colour(
                                                        context
                                                            .colors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                AppSpacing.md.h,
                                                ...pendingTypes.map((doc) {
                                                  final key = doc.docKey;
                                                  final localFile =
                                                      newDocs[key];

                                                  return Padding(
                                                    padding:
                                                        AppSpacing.md.bPadding,
                                                    child: DocumentUploadCard(
                                                      key: ValueKey(
                                                        'upload_$key',
                                                      ),
                                                      title: doc.name,
                                                      description:
                                                          doc.description,
                                                      icon: Icon(
                                                        doc.icon,
                                                        color: context
                                                            .colors
                                                            .primary,
                                                        size: AppSizes.iconLg,
                                                      ),
                                                      isRequired:
                                                          doc.isRequired,
                                                      isOptional:
                                                          !doc.isRequired,
                                                      isReadOnly: false,
                                                      selectedFilePath:
                                                          localFile?.path,
                                                      onPick: () =>
                                                          _pickDocument(doc),
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
                                                  onPressed:
                                                      _handleUploadNewDocuments,
                                                ),
                                                AppSpacing.xl.h,
                                              ],
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
}
