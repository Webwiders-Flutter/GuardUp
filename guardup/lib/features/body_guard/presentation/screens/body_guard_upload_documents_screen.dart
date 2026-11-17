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
import '../../data/enum/guard_doc_type.enum.dart';

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
  /// Reactive state holding selected documents per document type.
  final ValueNotifier<Map<GuardDocType, XFile>> _documentsNotifier =
      ValueNotifier<Map<GuardDocType, XFile>>({});
  final ValueNotifier<Map<GuardDocType, String>> _remoteDocsNotifier =
      ValueNotifier<Map<GuardDocType, String>>({});
  final ValueNotifier<Map<GuardDocType, String>> _remoteFileNamesNotifier =
      ValueNotifier<Map<GuardDocType, String>>({});
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  Future<void> _loadExistingDocuments() async {
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
        final Map<GuardDocType, String> urls = {};
        final Map<GuardDocType, String> names = {};
        for (final row in rows) {
          final docCode = row['document_type_id'] as String?;
          final fileUrl = row['file_url'] as String?;
          final fileName = row['file_name'] as String?;
          if (docCode != null && fileUrl != null && fileUrl.isNotEmpty) {
            final type = GuardDocType.tryFromApiValue(docCode);
            if (type != null) {
              urls[type] = fileUrl;
              if (fileName != null && fileName.isNotEmpty) {
                names[type] = fileName;
              }
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
    _documentsNotifier.dispose();
    _remoteDocsNotifier.dispose();
    _remoteFileNamesNotifier.dispose();
    _isLoadingNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(GuardDocType type) async {
    final picked = await AppMediaPickerSheet.show(
      context: context,
      allowCrop: false,
      allowFile: true,
    );

    if (picked != null && mounted) {
      _documentsNotifier.value = {..._documentsNotifier.value, type: picked};
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoadingNotifier.value) return;

    final localDocs = _documentsNotifier.value;
    final remoteDocs = _remoteDocsNotifier.value;

    // Validate required documents: only show snackbar if required item is empty
    for (final docType in GuardDocType.values.where((d) => d.isRequired)) {
      final hasLocal = localDocs.containsKey(docType);
      final hasRemote = remoteDocs.containsKey(docType);
      if (!hasLocal && !hasRemote) {
        AppSnackbar.error('Please upload your ${docType.label(context.l10n)}');
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
            final docType = entry.key;
            final xFile = entry.value;
            try {
              final ext = xFile.name.split('.').last;
              final storagePath =
                  '$currentUserId/${docType.name.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext';
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
                    'document_type_id': docType.apiValue,
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
                  child: ValueListenableBuilder<Map<GuardDocType, XFile>>(
                    valueListenable: _documentsNotifier,
                    builder: (context, docs, _) {
                      return ValueListenableBuilder<Map<GuardDocType, String>>(
                        valueListenable: _remoteDocsNotifier,
                        builder: (context, remoteDocs, _) {
                          return ValueListenableBuilder<Map<GuardDocType, String>>(
                            valueListenable: _remoteFileNamesNotifier,
                            builder: (context, remoteNames, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                    style:
                                        context.textTheme.headlineMedium?.bold(),
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

                                  // 4. ID Proof Card (Required)
                                  DocumentUploadCard(
                                    title: GuardDocType.idProof.label(
                                      context.l10n,
                                    ),
                                    description: GuardDocType.idProof
                                        .description(context.l10n),
                                    icon: Icon(
                                      GuardDocType.idProof.icon,
                                      color: context.colors.primary,
                                    ),
                                    isRequired: true,
                                    initialUrl:
                                        remoteDocs[GuardDocType.idProof],
                                    fileName: remoteNames[GuardDocType.idProof],
                                    selectedFilePath:
                                        docs[GuardDocType.idProof]?.path,
                                    onPick: () =>
                                        _pickDocument(GuardDocType.idProof),
                                  ),
                                  AppSpacing.lg.h,

                                  // 5. Police Verification Card (Required)
                                  DocumentUploadCard(
                                    title: GuardDocType.policeVerification
                                        .label(context.l10n),
                                    description: GuardDocType
                                        .policeVerification
                                        .description(context.l10n),
                                    icon: Icon(
                                      GuardDocType.policeVerification.icon,
                                      color: context.colors.primary,
                                    ),
                                    isRequired: true,
                                    initialUrl: remoteDocs[
                                        GuardDocType.policeVerification],
                                    fileName: remoteNames[
                                        GuardDocType.policeVerification],
                                    selectedFilePath: docs[
                                            GuardDocType.policeVerification]
                                        ?.path,
                                    onPick: () => _pickDocument(
                                      GuardDocType.policeVerification,
                                    ),
                                  ),
                                  AppSpacing.lg.h,

                                  // 6. Security License Card (Required)
                                  DocumentUploadCard(
                                    title: GuardDocType.securityLicense.label(
                                      context.l10n,
                                    ),
                                    description: GuardDocType.securityLicense
                                        .description(context.l10n),
                                    icon: Icon(
                                      GuardDocType.securityLicense.icon,
                                      color: context.colors.primary,
                                    ),
                                    isRequired: true,
                                    showUploadButton: true,
                                    initialUrl: remoteDocs[
                                        GuardDocType.securityLicense],
                                    fileName: remoteNames[
                                        GuardDocType.securityLicense],
                                    selectedFilePath: docs[
                                            GuardDocType.securityLicense]
                                        ?.path,
                                    onPick: () => _pickDocument(
                                      GuardDocType.securityLicense,
                                    ),
                                  ),
                                  AppSpacing.lg.h,

                                  // 7. Certifications Card (Optional)
                                  DocumentUploadCard(
                                    title: GuardDocType.certifications.label(
                                      context.l10n,
                                    ),
                                    description: GuardDocType.certifications
                                        .description(context.l10n),
                                    icon: Icon(
                                      GuardDocType.certifications.icon,
                                      color: context.colors.primary,
                                    ),
                                    isOptional: true,
                                    initialUrl: remoteDocs[
                                        GuardDocType.certifications],
                                    fileName: remoteNames[
                                        GuardDocType.certifications],
                                    selectedFilePath: docs[
                                            GuardDocType.certifications]
                                        ?.path,
                                    onPick: () => _pickDocument(
                                      GuardDocType.certifications,
                                    ),
                                  ),
                                  AppSpacing.xl.h,

                                  // 8. 256-Bit Encrypted & Compliant Security Notice
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
                                              .colors.surfaceContainerHigh
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
                                                text:
                                                    '256-Bit Encrypted & Compliant: ',
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.onSurface,
                                                fontSize: 12,
                                              ),
                                              AppTextSpan(
                                                text:
                                                    'Documents are stored in an encrypted vault and reviewed only by authorized government compliance officers.',
                                                color: context
                                                    .colors.onSurfaceVariant,
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

                                  // 9. Submit for Review Button
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _isLoadingNotifier,
                                    builder: (context, isLoading, _) {
                                      return AppButton(
                                        text: 'Submit for Review',
                                        isLoading: isLoading,
                                        trailing: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: AppSizes.iconMd,
                                          color: context.colors.onPrimary,
                                        ),
                                        onPressed: _handleSubmit,
                                      );
                                    },
                                  ),
                                  AppSpacing.huge.h,
                                ],
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
