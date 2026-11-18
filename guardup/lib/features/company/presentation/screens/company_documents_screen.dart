import 'package:flutter/material.dart';
import 'package:guardup/core/constants/api/database_tables.dart';
import 'package:guardup/core/constants/api/storage_buckets.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/services/file_storage/file_storage.service.dart';
import 'package:guardup/core/services/file_storage/models/file_upload_request.model.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final ValueNotifier<bool> _isInitialLoadingNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isUploadingNotifier =
      ValueNotifier<bool>(false);

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
    _isInitialLoadingNotifier.dispose();
    _isUploadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentTypesAndFiles() async {
    _isInitialLoadingNotifier.value = true;
    try {
      // 1. Fetch company document types
      final typeRows = await Supabase.instance.client
          .from(DatabaseTables.documentTypes)
          .select()
          .eq('target_role', 'COMPANY')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      final types =
          typeRows.map((r) => DocumentTypeModel.fromJson(r)).toList();
      if (mounted) _docTypesNotifier.value = types;

      // 2. Fetch existing uploaded documents for the current company user
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;

      if (currentUserId != null) {
        final docRows = await Supabase.instance.client
            .from(DatabaseTables.userDocuments)
            .select()
            .eq('user_id', currentUserId);

        final Map<String, String> urls = {};
        final Map<String, String> names = {};
        final Map<String, DocumentStatus> statuses = {};

        for (final row in docRows) {
          final docCode = row['document_type_id'] as String?;
          final fileUrl = row['file_url'] as String?;
          final fileName = row['file_name'] as String?;
          final statusRaw = row['status'] as String?;

          if (docCode != null && fileUrl != null && fileUrl.isNotEmpty) {
            urls[docCode] = fileUrl;
            if (fileName != null && fileName.isNotEmpty) {
              names[docCode] = fileName;
            }
            statuses[docCode] = DocumentStatus.fromApiValue(statusRaw);
          }
        }

        if (mounted) {
          _remoteDocsNotifier.value = urls;
          _remoteFileNamesNotifier.value = names;
          _remoteStatusesNotifier.value = statuses;
        }
      }
    } catch (_) {
    } finally {
      if (mounted) _isInitialLoadingNotifier.value = false;
    }
  }

  Future<void> _pickDocument(DocumentTypeModel doc) async {
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

      if (sl.isRegistered<FileStorageService>()) {
        for (final entry in newDocs.entries) {
          final docKey = entry.key;
          final xFile = entry.value;

          final ext = xFile.name.split('.').last;
          final storagePath =
              '$currentUserId/${docKey.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext';

          final fileUrl = await sl<FileStorageService>().uploadSingleFile(
            FileUploadRequest.fromXFile(
              bucket: StorageBuckets.documents,
              path: storagePath,
              xFile: xFile,
              upsert: true,
            ),
          );

          await Supabase.instance.client
              .from(DatabaseTables.userDocuments)
              .upsert({
                'user_id': currentUserId,
                'document_type_id': docKey,
                'file_url': fileUrl,
                'file_name': xFile.name,
                'status': 'PENDING',
              });
        }
      }

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
        child: ValueListenableBuilder<bool>(
          valueListenable: _isInitialLoadingNotifier,
          builder: (context, isInitialLoading, _) {
            if (isInitialLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.colors.primary,
                ),
              );
            }

            return ValueListenableBuilder<List<DocumentTypeModel>>(
              valueListenable: _docTypesNotifier,
              builder: (context, docTypes, _) {
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

                return ValueListenableBuilder<Map<String, String>>(
                  valueListenable: _remoteDocsNotifier,
                  builder: (context, remoteDocs, _) {
                    return ValueListenableBuilder<Map<String, String>>(
                      valueListenable: _remoteFileNamesNotifier,
                      builder: (context, remoteNames, _) {
                        return ValueListenableBuilder<
                          Map<String, DocumentStatus>
                        >(
                          valueListenable: _remoteStatusesNotifier,
                          builder: (context, remoteStatuses, _) {
                            return ValueListenableBuilder<Map<String, XFile>>(
                              valueListenable: _newDocumentsNotifier,
                              builder: (context, newDocs, _) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: _isUploadingNotifier,
                                  builder: (context, isUploading, _) {
                                    final uploadedTypes = docTypes.where((d) {
                                      final key = d.docKey;
                                      return remoteDocs.containsKey(key) ||
                                          (d.code.isNotEmpty &&
                                              remoteDocs.containsKey(d.code));
                                    }).toList();

                                    final pendingTypes = docTypes.where((d) {
                                      final key = d.docKey;
                                      final hasRemote =
                                          remoteDocs.containsKey(key) ||
                                          (d.code.isNotEmpty &&
                                              remoteDocs.containsKey(d.code));
                                      return !hasRemote;
                                    }).toList();

                                    return SingleChildScrollView(
                                      padding: context.horizontalEdgeInsets +
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
                                                    context.colors.onSurface,
                                                  ),
                                            ),
                                            AppSpacing.xxs.h,
                                            Text(
                                              'Existing documents cannot be replaced once submitted.',
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
                                              final remoteUrl =
                                                  remoteDocs[key] ??
                                                  remoteDocs[doc.code];
                                              final remoteName =
                                                  remoteNames[key] ??
                                                  remoteNames[doc.code];
                                              final status =
                                                  remoteStatuses[key] ??
                                                  remoteStatuses[doc.code];

                                              return Padding(
                                                padding: AppSpacing.md.bPadding,
                                                child: DocumentUploadCard(
                                                  key: ValueKey('view_$key'),
                                                  title: doc.name,
                                                  description: doc.description,
                                                  icon: Icon(
                                                    doc.icon,
                                                    color:
                                                        context.colors.primary,
                                                    size: AppSizes.iconLg,
                                                  ),
                                                  isRequired: doc.isRequired,
                                                  isReadOnly: true,
                                                  initialUrl: remoteUrl,
                                                  fileName: remoteName,
                                                  status: status,
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
                                                    context.colors.onSurface,
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
                                              final localFile = newDocs[key];

                                              return Padding(
                                                padding: AppSpacing.md.bPadding,
                                                child: DocumentUploadCard(
                                                  key: ValueKey('upload_$key'),
                                                  title: doc.name,
                                                  description: doc.description,
                                                  icon: Icon(
                                                    doc.icon,
                                                    color:
                                                        context.colors.primary,
                                                    size: AppSizes.iconLg,
                                                  ),
                                                  isRequired: doc.isRequired,
                                                  isOptional: !doc.isRequired,
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
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

