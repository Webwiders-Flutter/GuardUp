import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quick_container/quick_container.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/document_submission/document_submission_service.dart';
import '../../../auth/auth.dart';
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
import '../../data/enum/document_status.enum.dart';
import '../../data/model/body_guard.model.dart';
import '../../data/model/document_type.model.dart';
import '/features/payments/presentation/screens/registration_fee_screen.dart';

/// Screen for bodyguard verification credentials and document upload.
///
/// Follows GuardUp Development Rules & Architectural Guidelines:
/// - State Management: [ValueNotifier] & [ValueListenableBuilder] over `setState()`.
/// - Component Reuse: [DocumentUploadCard], [AppButton], [AppAppBar], [AppRichText].
/// - Theming: strictly uses context extensions ([context.colors], [context.textTheme], [AppSpacing]).
class BodyGuardUploadDocumentsScreen extends StatefulWidget {
  static const route = '/bodyguard-upload-documents';

  final BodyGuardModel? bodyguard;

  const BodyGuardUploadDocumentsScreen({super.key, this.bodyguard});

  @override
  State<BodyGuardUploadDocumentsScreen> createState() =>
      _BodyGuardUploadDocumentsScreenState();
}

class _BodyGuardUploadDocumentsScreenState
    extends State<BodyGuardUploadDocumentsScreen> {
  /// Available active document types dynamically fetched from DatabaseTables.documentTypes.
  final ValueNotifier<List<DocumentTypeModel>> _docTypesNotifier =
      ValueNotifier<List<DocumentTypeModel>>([]);
  final ValueNotifier<bool> _isDocTypesLoadingNotifier = ValueNotifier<bool>(
    true,
  );

  /// Reactive state holding selected documents per document code.
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
      final types = await docService.getDocumentTypes(UserRole.guard);
      if (mounted) _docTypesNotifier.value = types;

      final isGuard =
          sl.isRegistered<AuthBloc>() && sl<AuthBloc>().state.isGuard;
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;
      final targetUserId = isGuard
          ? currentUserId
          : (widget.bodyguard?.user.id.isNotEmpty == true
              ? widget.bodyguard!.user.id
              : (widget.bodyguard?.id.isNotEmpty == true
                  ? widget.bodyguard!.id
                  : currentUserId));

      if (targetUserId != null) {
        final records = await docService.getUserDocuments(targetUserId);
        if (mounted) {
          _remoteDocsNotifier.value = records.urls;
          _remoteFileNamesNotifier.value = records.names;
          _remoteStatusesNotifier.value = records.statuses;
          _rejectionReasonsNotifier.value = records.rejectionReasons;
        }
      }
    } catch (e) {
      debugPrint('Error loading bodyguard document types & files: $e');
    } finally {
      if (mounted) {
        _isDocTypesLoadingNotifier.value = false;
      }
    }
  }

  @override
  void dispose() {
    _docTypesNotifier.dispose();
    _isDocTypesLoadingNotifier.dispose();
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
      final status =
          remoteStatuses[key] ??
          (doc.code.isNotEmpty ? remoteStatuses[doc.code] : null);
      if (status == DocumentStatus.rejected && !localDocs.containsKey(key)) {
        AppSnackbar.error('Please upload an updated document for ${doc.name}');
        return;
      }
    }

    // 2. Validate required documents from dynamic docTypes:
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
      final isGuard =
          sl.isRegistered<AuthBloc>() && sl<AuthBloc>().state.isGuard;
      final currentUserId = sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>().currentUserId
          : null;
      final targetUserId = isGuard
          ? currentUserId
          : (widget.bodyguard?.user.id.isNotEmpty == true
              ? widget.bodyguard!.user.id
              : (widget.bodyguard?.id.isNotEmpty == true
                  ? widget.bodyguard!.id
                  : currentUserId));

      if (targetUserId != null) {
        if (localDocs.isNotEmpty) {
          await sl<DocumentSubmissionService>().uploadDocuments(
            userId: targetUserId,
            documents: localDocs,
            docTypes: docTypes,
            isCompany: !isGuard,
          );
        } else {
          // Documents already uploaded & valid. Transition user status back to PENDING_APPROVAL
          await sl<DocumentSubmissionService>().submitApplicationForReview(
            targetUserId,
          );
        }
      }

      if (mounted) {
        _documentsNotifier.value = {};
        await _loadDocumentTypesAndFiles();
        if (!mounted) return;

        if (isGuard) {
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
        } else {
          AppSnackbar.success(
            localDocs.isNotEmpty
                ? 'Documents submitted successfully. The guard profile is under review.'
                : 'Application submitted successfully. The guard profile is under review.',
          );
          context.go(AdminApprovalScreen.route);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error('Failed to submit application: $e');
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuard =
        sl.isRegistered<AuthBloc>() && sl<AuthBloc>().state.isGuard;

    return Scaffold(
      appBar: AppAppBar.transparent(
        title: context.l10n.uploadDocuments,
        alignTitle: sl<AuthBloc>().state.isAuthenticated ? .right : .center,
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
                      sl<AuthBloc>().add(const AuthSignOutRequested());
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
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _isLoadingNotifier,
                      _isDocTypesLoadingNotifier,
                      _docTypesNotifier,
                      _documentsNotifier,
                      _remoteDocsNotifier,
                      _remoteFileNamesNotifier,
                      _remoteStatusesNotifier,
                      _rejectionReasonsNotifier,
                    ]),
                    builder: (context, _) {
                      final isDocTypesLoading =
                          _isDocTypesLoadingNotifier.value;
                      if (isDocTypesLoading) {
                        return Center(
                          child: Padding(
                            padding: AppSpacing.xxl.allPadding,
                            child: CircularProgressIndicator(
                              color: context.colors.primary,
                            ),
                          ),
                        );
                      }

                      final isLoading = _isLoadingNotifier.value;
                      final docTypes = _docTypesNotifier.value;
                      final docs = _documentsNotifier.value;
                      final remoteDocs = _remoteDocsNotifier.value;
                      final remoteNames = _remoteFileNamesNotifier.value;
                      final remoteStatuses = _remoteStatusesNotifier.value;
                      final rejectionReasons = _rejectionReasonsNotifier.value;

                      final hasRejectedDoc = remoteStatuses.values.any(
                        (s) => s == DocumentStatus.rejected,
                      );

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
                            final remoteStatus =
                                remoteStatuses[key] ??
                                (doc.code.isNotEmpty
                                    ? remoteStatuses[doc.code]
                                    : null);
                            final rejectionReason =
                                rejectionReasons[key] ??
                                (doc.code.isNotEmpty
                                    ? rejectionReasons[doc.code]
                                    : null);

                            final wasRejected =
                                remoteStatus == DocumentStatus.rejected;
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
                                  onPick: () => _pickDocument(doc),
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
