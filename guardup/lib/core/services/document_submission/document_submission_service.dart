import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/storage_buckets.dart';
import '/core/di/injection_container.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/features/auth/auth.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/features/body_guard/data/model/document_type.model.dart';

/// Structured container holding a user's uploaded document records mapped by document type id.
class UserDocumentRecords {
  final Map<String, String> urls;
  final Map<String, String> names;
  final Map<String, DocumentStatus> statuses;
  final Map<String, String> rejectionReasons;

  const UserDocumentRecords({
    this.urls = const {},
    this.names = const {},
    this.statuses = const {},
    this.rejectionReasons = const {},
  });

  bool get hasRejectedDoc =>
      statuses.values.any((s) => s == DocumentStatus.rejected);
}

/// Abstract contract for querying and submitting compliance & verification documents.
abstract class DocumentSubmissionService {
  /// Fetches active document types configured for a target user role (e.g. GUARD or COMPANY).
  Future<List<DocumentTypeModel>> getDocumentTypes(UserRole role);

  /// Fetches already uploaded user documents for a user, returned as [UserDocumentRecords].
  Future<UserDocumentRecords> getUserDocuments(String userId);

  /// Uploads one or more documents to Supabase Storage, updates/inserts into `user_documents`,
  /// optionally syncs company logo if applicable, and triggers AuthBloc status & role refresh.
  Future<void> uploadDocuments({
    required String userId,
    required Map<String, XFile> documents,
    required List<DocumentTypeModel> docTypes,
    bool isCompany = false,
  });

  /// Submits or resubmits the user's application for review without uploading new documents
  /// (e.g. after editing profile details while credentials/documents are already pending or valid).
  Future<void> submitApplicationForReview(String userId);
}

/// Supabase implementation of [DocumentSubmissionService].
class SupabaseDocumentSubmissionService implements DocumentSubmissionService {
  final SupabaseClient _supabase;
  final FileStorageService fileStorageService;
  final UserRepository? userRepository;

  SupabaseDocumentSubmissionService({
    SupabaseClient? supabase,
    required this.fileStorageService,
    this.userRepository,
  }) : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<DocumentTypeModel>> getDocumentTypes(UserRole role) async {
    final targetRole = role == UserRole.company ? 'COMPANY' : 'GUARD';
    final rows = await _supabase
        .from(DatabaseTables.documentTypes)
        .select()
        .eq('target_role', targetRole)
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return (rows as List<dynamic>)
        .map((r) => DocumentTypeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserDocumentRecords> getUserDocuments(String userId) async {
    final rows = await _supabase
        .from(DatabaseTables.userDocuments)
        .select()
        .eq('user_id', userId);

    final Map<String, String> urls = {};
    final Map<String, String> names = {};
    final Map<String, DocumentStatus> statuses = {};
    final Map<String, String> rejectionReasons = {};

    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final docTypeId = map['document_type_id'] as String?;
      final fileUrl = map['file_url'] as String?;
      final fileName = map['file_name'] as String?;
      final status = DocumentStatus.fromApiValue(map['status'] as String?);
      final reason = map['rejection_reason'] as String?;

      if (docTypeId != null && fileUrl != null && fileUrl.isNotEmpty) {
        urls[docTypeId] = fileUrl;
        if (fileName != null && fileName.isNotEmpty) {
          names[docTypeId] = fileName;
        }
        statuses[docTypeId] = status;
        if (reason != null && reason.trim().isNotEmpty) {
          rejectionReasons[docTypeId] = reason.trim();
        }
      }
    }

    return UserDocumentRecords(
      urls: urls,
      names: names,
      statuses: statuses,
      rejectionReasons: rejectionReasons,
    );
  }

  @override
  Future<void> uploadDocuments({
    required String userId,
    required Map<String, XFile> documents,
    required List<DocumentTypeModel> docTypes,
    bool isCompany = false,
  }) async {
    if (documents.isEmpty) return;

    String? uploadedLogoUrl;

    for (final entry in documents.entries) {
      final docKey = entry.key;
      final xFile = entry.value;

      final matchingDocType = docTypes.firstWhere(
        (d) => d.docKey == docKey || d.id == docKey || d.code == docKey,
        orElse: () => docTypes.first,
      );
      final resolvedDocTypeId = matchingDocType.id.isNotEmpty
          ? matchingDocType.id
          : docKey;

      final ext = xFile.name.split('.').last;
      final storagePath =
          '$userId/${resolvedDocTypeId.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      // 1. Upload to Supabase Storage Bucket
      final fileUrl = await fileStorageService.uploadSingleFile(
        FileUploadRequest.fromXFile(
          bucket: StorageBuckets.documents,
          path: storagePath,
          xFile: xFile,
          upsert: true,
        ),
      );

      // 2. Track company logo if applicable
      if (isCompany) {
        final isLogo = resolvedDocTypeId == 'COMPANY_LOGO' ||
            matchingDocType.name.toUpperCase().contains('LOGO') ||
            matchingDocType.code.toUpperCase().contains('LOGO');
        if (isLogo) {
          uploadedLogoUrl = fileUrl;
        }
      }

      // 3. Update existing document or insert new document
      final existingDoc = await _supabase
          .from(DatabaseTables.userDocuments)
          .select('id')
          .eq('user_id', userId)
          .eq('document_type_id', resolvedDocTypeId)
          .maybeSingle();

      if (existingDoc != null && existingDoc['id'] != null) {
        await _supabase
            .from(DatabaseTables.userDocuments)
            .update({
              'file_url': fileUrl,
              'file_name': xFile.name,
              'status': 'PENDING',
            })
            .eq('id', existingDoc['id'] as String);
      } else {
        await _supabase
            .from(DatabaseTables.userDocuments)
            .insert({
              'user_id': userId,
              'document_type_id': resolvedDocTypeId,
              'file_url': fileUrl,
              'file_name': xFile.name,
              'status': 'PENDING',
            });
      }
    }

    // 4. Update company profile image if logo uploaded
    if (uploadedLogoUrl != null &&
        uploadedLogoUrl.isNotEmpty &&
        userRepository != null) {
      try {
        await userRepository!.updateProfileFields(
          userId: userId,
          data: {'profile_image_url': uploadedLogoUrl},
        );
      } catch (e) {
        debugPrint('Failed to sync company logo URL: $e');
      }
    }

    // 5. Notify AuthBloc so real-time status and role data reload immediately
    if (sl.isRegistered<AuthBloc>()) {
      sl<AuthBloc>().add(const AuthCheckStatusRequested());
      sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
    }
  }

  @override
  Future<void> submitApplicationForReview(String userId) async {
    await _supabase
        .from(DatabaseTables.users)
        .update({
          'status': 'PENDING_APPROVAL',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    if (sl.isRegistered<AuthBloc>()) {
      sl<AuthBloc>().add(const AuthCheckStatusRequested());
      sl<AuthBloc>().add(const AuthReloadRoleDataRequested());
    }
  }
}

