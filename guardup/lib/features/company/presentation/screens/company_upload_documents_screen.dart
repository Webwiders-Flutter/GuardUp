import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/api/database_tables.dart';
import 'package:guardup/core/constants/api/storage_buckets.dart';
import 'package:guardup/core/di/injection_container.dart';
import 'package:guardup/core/services/file_storage/file_storage.service.dart';
import 'package:guardup/core/services/file_storage/models/file_upload_request.model.dart';
import 'package:guardup/features/auth/auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/app/routes/app_routes.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/features/body_guard/data/model/document_type.model.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/sections/app_appbar.dart';

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
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadDocumentTypesAndFiles();
  }

  Future<void> _loadDocumentTypesAndFiles() async {
    // 1. Dynamically fetch company document types from document_types table
    try {
      final typeRows = await Supabase.instance.client
          .from(DatabaseTables.documentTypes)
          .select()
          .eq('target_role', 'COMPANY')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        _docTypesNotifier.value = typeRows
            .map((r) => DocumentTypeModel.fromJson(r))
            .toList();
      }
    } catch (_) {}

    // 2. Fetch already uploaded documents from user_documents table
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null) return;

    try {
      final docRows = await Supabase.instance.client
          .from(DatabaseTables.userDocuments)
          .select()
          .eq('user_id', currentUserId);

      if (docRows.isNotEmpty && mounted) {
        final Map<String, String> urls = {};
        final Map<String, String> names = {};
        for (final row in docRows) {
          final docCode = row['document_type_id'] as String?;
          final fileUrl = row['file_url'] as String?;
          final fileName = row['file_name'] as String?;
          if (docCode != null && fileUrl != null && fileUrl.isNotEmpty) {
            urls[docCode] = fileUrl;
            if (fileName != null && fileName.isNotEmpty) {
              names[docCode] = fileName;
            }
          }
        }
        _remoteDocsNotifier.value = urls;
        _remoteFileNamesNotifier.value = names;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _docTypesNotifier.dispose();
    _documentsNotifier.dispose();
    _remoteDocsNotifier.dispose();
    _remoteFileNamesNotifier.dispose();
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

    // Validate required documents dynamically from database definitions
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
        String? uploadedLogoUrl;

        if (sl.isRegistered<FileStorageService>()) {
          for (final entry in localDocs.entries) {
            final docKey = entry.key;
            final xFile = entry.value;
            try {
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

              final isLogo =
                  docKey == 'COMPANY_LOGO' ||
                  docTypes
                      .firstWhere(
                        (d) => d.docKey == docKey,
                        orElse: () => docTypes.first,
                      )
                      .name
                      .toUpperCase()
                      .contains('LOGO');
              if (isLogo) {
                uploadedLogoUrl = fileUrl;
              }

              // Record in user_documents
              await Supabase.instance.client
                  .from(DatabaseTables.userDocuments)
                  .upsert({
                    'user_id': currentUserId,
                    'document_type_id': docKey,
                    'file_url': fileUrl,
                    'file_name': xFile.name,
                    'status': 'PENDING',
                  });
            } catch (_) {}
          }
        }

        // Sync logo URL if uploaded
        if (uploadedLogoUrl != null &&
            uploadedLogoUrl.isNotEmpty &&
            sl.isRegistered<UserRepository>()) {
          try {
            await sl<UserRepository>().updateProfileFields(
              userId: currentUserId,
              data: {'profile_image_url': uploadedLogoUrl},
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        _isLoadingNotifier.value = false;
        // Proceed to One-Time Registration Fee payment screen
        context.go(AppRoutes.registrationFee);
      }
    } catch (_) {
      if (mounted) {
        _isLoadingNotifier.value = false;
        AppSnackbar.error('Failed to upload documents. Please try again.');
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
                context.go(AppRoutes.login);
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
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      return ValueListenableBuilder<List<DocumentTypeModel>>(
                        valueListenable: _docTypesNotifier,
                        builder: (context, docTypes, _) {
                          return ValueListenableBuilder<Map<String, XFile>>(
                            valueListenable: _documentsNotifier,
                            builder: (context, docs, _) {
                              return ValueListenableBuilder<
                                Map<String, String>
                              >(
                                valueListenable: _remoteDocsNotifier,
                                builder: (context, remoteDocs, _) {
                                  return ValueListenableBuilder<
                                    Map<String, String>
                                  >(
                                    valueListenable: _remoteFileNamesNotifier,
                                    builder: (context, remoteNames, _) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          AppSpacing.lg.h,

                                          ...docTypes.map((doc) {
                                            final key = doc.docKey;
                                            final localFile = docs[key];
                                            final remoteUrl =
                                                remoteDocs[key] ??
                                                (doc.code.isNotEmpty
                                                    ? remoteDocs[doc.code]
                                                    : null);
                                            final remoteName =
                                                remoteNames[key] ??
                                                (doc.code.isNotEmpty
                                                    ? remoteNames[doc.code]
                                                    : null);

                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                DocumentUploadCard(
                                                  key: ValueKey('doc_$key'),
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
                                                  isLoading: false,
                                                  initialUrl: remoteUrl,
                                                  fileName: remoteName,
                                                  selectedFilePath:
                                                      localFile?.path,
                                                  onPick: isLoading
                                                      ? null
                                                      : () =>
                                                            _pickDocument(doc),
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
                                            onPressed: _handleSubmit,
                                          ),
                                          AppSpacing.xl.h,
                                        ],
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
              ),
            );
          },
        ),
      ),
    );
  }
}
