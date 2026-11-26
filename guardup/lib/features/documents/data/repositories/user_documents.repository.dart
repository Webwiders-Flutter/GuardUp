import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/core/constants/api/json_keys.dart';
import '/core/constants/api/storage_buckets.dart';
import '/core/repositories/base.repository.dart';
import '/core/services/file_storage/file_storage.service.dart';
import '/core/services/file_storage/models/file_upload_request.model.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import '/shared/models/record_owner.model.dart';
import '../models/document_type.model.dart';
import '../models/user_document.model.dart';

/// `public.user_documents`: User and bodyguard uploaded compliance documents.
class UserDocumentsRepository
    extends BaseSupabaseRepository<UserDocumentModel> {
  final FileStorageService? fileStorageService;

  UserDocumentsRepository(SupabaseClient client, {this.fileStorageService})
    : super(
        client: client,
        tableName: DatabaseTables.userDocuments,
        fromJson: UserDocumentModel.fromJson,
        entityName: 'user document',
        searchFields: const [JsonKeys.fileName],
        primarySortColumn: JsonKeys.uploadedAt,
        primarySortAscending: false,
      );

  /// Fetches all documents submitted by [owner] with embedded document types.
  Future<List<UserDocumentModel>> getFor(RecordOwner owner) async {
    final rows = await client
        .from(tableName)
        .select('*, document_type:document_types(*)')
        .eq(owner.column, owner.id);
    return (rows as List<dynamic>)
        .map((r) => UserDocumentModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Uploads [file] to storage bucket and upserts a row in `public.user_documents`.
  Future<UserDocumentModel> upload({
    required String storageUserId,
    required RecordOwner owner,
    required DocumentTypeModel type,
    required XFile file,
  }) async {
    final ext = file.name.split('.').last;
    final storageFolder = switch (owner) {
      AccountOwner() => storageUserId,
      ManagedBodyguardOwner(:final id) => '$storageUserId/bodyguards/$id',
    };
    final storagePath =
        '$storageFolder/${type.id.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final String fileUrl;
    if (fileStorageService != null) {
      fileUrl = await fileStorageService!.uploadSingleFile(
        FileUploadRequest.fromXFile(
          bucket: StorageBuckets.documents,
          path: storagePath,
          xFile: file,
          upsert: true,
        ),
      );
    } else {
      final bytes = await file.readAsBytes();
      await client.storage
          .from(StorageBuckets.documents)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      fileUrl = client.storage
          .from(StorageBuckets.documents)
          .getPublicUrl(storagePath);
    }

    final row = await client
        .from(tableName)
        .upsert({
          owner.column: owner.id,
          JsonKeys.documentTypeId: type.id,
          JsonKeys.fileUrl: fileUrl,
          JsonKeys.fileName: file.name,
          JsonKeys.status: DocumentStatus.pending.apiValue,
          JsonKeys.updatedAt: DateTime.now().toIso8601String(),
        }, onConflict: '${owner.column},${JsonKeys.documentTypeId}')
        .select('*, document_type:document_types(*)')
        .single();

    return UserDocumentModel.fromJson(row);
  }
}
