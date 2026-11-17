import '../enum/document_status.enum.dart';

/// Represents a document submitted by a Guard or Company user.
class UserDocumentModel {
  final String id;
  final String userId;
  final String documentTypeId;
  final String fileUrl;
  final String? fileName;
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? validTill;
  final DateTime? uploadedAt;

  const UserDocumentModel({
    required this.id,
    required this.userId,
    required this.documentTypeId,
    required this.fileUrl,
    this.fileName,
    this.status = DocumentStatus.pending,
    this.rejectionReason,
    this.validTill,
    this.uploadedAt,
  });

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) {
    return UserDocumentModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      documentTypeId: (json['document_type_id'] ?? '') as String,
      fileUrl: (json['file_url'] ?? '') as String,
      fileName: json['file_name'] as String?,
      status: DocumentStatus.fromApiValue(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      validTill: json['valid_till'] != null
          ? DateTime.tryParse(json['valid_till'] as String)
          : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_type_id': documentTypeId,
      'file_url': fileUrl,
      'file_name': fileName,
      'status': status.apiValue,
      'rejection_reason': rejectionReason,
      'valid_till': validTill?.toIso8601String(),
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}

