import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api/database_tables.dart';
import '../../../../core/constants/api/storage_buckets.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/file_storage/file_storage.service.dart';
import '../../../../core/services/file_storage/models/file_upload_request.model.dart';
import '../../../auth/auth.dart';
import '/app/routes/app_routes.dart';
import '/core/constants/app_radius.dart';
import '/core/constants/app_sizes.dart';
import '/core/constants/app_spacing.dart';
import '/core/extensions/context.extension.dart';
import '/core/extensions/localization.extension.dart';
import '/core/extensions/spacing.extension.dart';
import '/core/extensions/textstyle_extension.dart';
import '/shared/widgets/buttons/app_button.dart';
import '/shared/widgets/feedbacks/widgets/app_popup.dart';
import '/shared/widgets/feedbacks/widgets/app_snackbar.dart';
import '/shared/widgets/inputs/app_media_picker_sheet.dart';
import '/shared/widgets/inputs/document_upload_card.dart';
import '/shared/widgets/misc/app_rich_text.dart';
import '/shared/widgets/sections/app_appbar.dart';
import '/shared/widgets/sections/wrapper_card.dart';
import '../../data/model/document_type.model.dart';

/// Screen for bodyguard verification credentials and document upload.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Component Reuse: [DocumentUploadCard], [AppButton], [AppAppBar], [AppRichText].
/// - Theming: strictly uses context extensions ([context.colors], [context.textTheme], [AppSpacing]).
class BodyGuardUploadDocumentsScreen extends StatefulWidget {
  static const route = '/bodyguard-upload-documents';

  const BodyGuardUploadDocumentsScreen({super.key});

  @override
  State<BodyGuardUploadDocumentsScreen> createState() =>
      _BodyGuardUploadDocumentsScreenState();
}

class _BodyGuardUploadDocumentsScreenState
    extends State<BodyGuardUploadDocumentsScreen> {
  /// Available active document types dynamically fetched from DatabaseTables.documentTypes.
  final ValueNotifier<List<DocumentTypeModel>> _docTypesNotifier =
      ValueNotifier<List<DocumentTypeModel>>([]);
  final ValueNotifier<bool> _isDocTypesLoadingNotifier =
      ValueNotifier<bool>(true);

  /// Reactive state holding selected documents per document code.
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
    // 1. Dynamically fetch guard document types from document_types table where target_role = 'GUARD' and is_active = true
    try {
      final typeRows = await Supabase.instance.client
          .from(DatabaseTables.documentTypes)
          .select()
          .eq('target_role', 'GUARD')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        _docTypesNotifier.value = typeRows
            .map((r) => DocumentTypeModel.fromJson(r))
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) {
        _isDocTypesLoadingNotifier.value = false;
      }
    }

    // 2. Fetch already uploaded documents from user_documents table
    final currentUserId = sl.isRegistered<AuthRepository>()
        ? sl<AuthRepository>().currentUserId
        : null;
    if (currentUserId == null) return;

    try {
      final rows = await Supabase.instance.client
          .from(DatabaseTables.userDocuments)
          .select()
          .eq('user_id', currentUserId);

      if (rows.isNotEmpty && mounted) {
        final Map<String, String> urls = {};
        final Map<String, String> names = {};
        for (final row in rows) {
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
    _isDocTypesLoadingNotifier.dispose();
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

    // Validate required documents from dynamic docTypes:
    for (final doc in docTypes.where((d) => d.isRequired)) {
      final key = doc.docKey;
      final hasLocal = localDocs.containsKey(key);
      final hasRemote = remoteDocs.containsKey(key) ||
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
      }

      if (mounted) {
        context.go(AppRoutes.registrationFee);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to submit documents: $e');
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.uploadDocuments,
        alignTitle: sl<AuthBloc>().state.isAuthenticated ? .right : .center,
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
                                                style: context
                                                    .textTheme.labelSmall
                                                    ?.bold()
                                                    .copyWith(
                                                      color: context
                                                          .colors.primary,
                                                      letterSpacing: 0.8,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          AppSpacing.sm.h,

                                          // 2. Main Heading
                                          Text(
                                            'Verification Credentials',
                                            style: context
                                                .textTheme.headlineMedium
                                                ?.bold(),
                                          ),
                                          AppSpacing.sm.h,

                                          // 3. Subtitle Description
                                          Text(
                                            'Submit your official documentation to unlock high-tier VIP assignments & priority instant payouts.',
                                            style: context.textTheme.bodyMedium
                                                ?.colour(
                                                  context
                                                      .colors.onSurfaceVariant,
                                                ),
                                          ),
                                          AppSpacing.lg.h,

                                          // Dynamic Document Types from Supabase
                                          ...docTypes.map(
                                            (doc) {
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
                                                      color: context
                                                          .colors.primary,
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
                                                  AppSpacing.lg.h,
                                                ],
                                              );
                                            },
                                          ),

                                          // 4. 256-Bit Encrypted & Compliant Security Notice
                                          WrapperCard(
                                            padding: AppSpacing.md.allPadding,
                                            borderRadius: AppRadius.md,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                QuickContainer(
                                                  w: 36,
                                                  h: 36,
                                                  radius: AppRadius.sm,
                                                  color: context
                                                      .colors
                                                      .surfaceContainerHigh
                                                      .withValues(alpha: 0.5),
                                                  border: Border.all(
                                                    color: context
                                                        .colors.outlineVariant
                                                        .withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    Icons.lock_outline_rounded,
                                                    size: AppSizes.iconSmd,
                                                    color:
                                                        context.colors.primary,
                                                  ),
                                                ),
                                                AppSpacing.sm.w,
                                                Expanded(
                                                  child: AppRichText(
                                                    spans: [
                                                      AppTextSpan(
                                                        text:
                                                            '256-Bit Encrypted & Compliant: ',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: context
                                                            .colors.onSurface,
                                                        fontSize: 12,
                                                      ),
                                                      AppTextSpan(
                                                        text:
                                                            'Documents are stored in an encrypted vault and reviewed only by authorized government compliance officers.',
                                                        color: context
                                                            .colors
                                                            .onSurfaceVariant,
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
                                            isLoading: isLoading,
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
