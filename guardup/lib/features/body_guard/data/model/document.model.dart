import '../enum/document_status.enum.dart';
import '../enum/guard_doc_type.enum.dart';

/// Represents a verified or submitted document record for a bodyguard profile.
class DocumentModel {
  final String id;
  final GuardDocType docType;
  final String url;
  final DocumentStatus status;
  final DateTime? validTill;
  final String? fileName;
  final DateTime? uploadedAt;
  final String? rejectionReason;

  const DocumentModel({
    required this.id,
    required this.docType,
    required this.url,
    this.status = DocumentStatus.pending,
    this.validTill,
    this.fileName,
    this.uploadedAt,
    this.rejectionReason,
  });

  bool get isExpired {
    if (validTill == null) return false;
    return validTill!.isBefore(DateTime.now());
  }

  String get displayValidity {
    if (validTill == null) return 'No expiry';
    return '${validTill!.day.toString().padLeft(2, '0')}/${validTill!.month.toString().padLeft(2, '0')}/${validTill!.year}';
  }

  DocumentModel copyWith({
    String? id,
    GuardDocType? docType,
    String? url,
    DocumentStatus? status,
    DateTime? validTill,
    String? fileName,
    DateTime? uploadedAt,
    String? rejectionReason,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      docType: docType ?? this.docType,
      url: url ?? this.url,
      status: status ?? this.status,
      validTill: validTill ?? this.validTill,
      fileName: fileName ?? this.fileName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docType': docType.apiValue,
      'url': url,
      'status': status.apiValue,
      if (validTill != null) 'validTill': validTill!.toIso8601String(),
      if (fileName != null) 'fileName': fileName,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      docType: GuardDocType.fromApiValue(json['docType'] as String?),
      url: json['url'] as String? ?? '',
      status: DocumentStatus.fromApiValue(json['status'] as String?),
      validTill: json['validTill'] != null
          ? DateTime.tryParse(json['validTill'] as String)
          : null,
      fileName: json['fileName'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  /// Curated list of verified & submitted credentials for mockups.
  static List<DocumentModel> get fakeDocuments => [
    DocumentModel(
      id: 'doc_1',
      docType: GuardDocType.idProof,
      url: 'https://cdn.guardup.app/docs/passport_vikram.pdf',
      fileName: 'government_passport_id.pdf',
      status: DocumentStatus.approved,
      validTill: DateTime(2032, 8, 14),
      uploadedAt: DateTime(2026, 1, 10),
    ),
    DocumentModel(
      id: 'doc_2',
      docType: GuardDocType.securityLicense,
      url: 'https://cdn.guardup.app/docs/armed_license_404.pdf',
      fileName: 'armed_security_officer_license.pdf',
      status: DocumentStatus.approved,
      validTill: DateTime(2028, 12, 31),
      uploadedAt: DateTime(2026, 1, 11),
    ),
    DocumentModel(
      id: 'doc_3',
      docType: GuardDocType.policeVerification,
      url: 'https://cdn.guardup.app/docs/pcc_clearance.pdf',
      fileName: 'police_clearance_certificate.pdf',
      status: DocumentStatus.approved,
      validTill: DateTime(2027, 4, 1),
      uploadedAt: DateTime(2026, 1, 12),
    ),
    DocumentModel(
      id: 'doc_4',
      docType: GuardDocType.certifications,
      url: 'https://cdn.guardup.app/docs/tactical_cpr_cert.pdf',
      fileName: 'tactical_combat_casualty_care.pdf',
      status: DocumentStatus.pending,
      validTill: DateTime(2029, 3, 20),
      uploadedAt: DateTime(2026, 4, 25),
    ),
  ];
}

