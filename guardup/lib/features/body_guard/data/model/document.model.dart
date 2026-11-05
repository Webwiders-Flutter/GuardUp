import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/document_status.enum.dart';
import '../enum/guard_doc_type.enum.dart';

part 'document.model.freezed.dart';
part 'document.model.g.dart';

/// Represents a verified or submitted document record for a bodyguard profile.
@freezed
abstract class DocumentModel with _$DocumentModel {
  const factory DocumentModel({
    required String id,
    required GuardDocType docType,
    required String url,
    @Default(DocumentStatus.pending) DocumentStatus status,
    DateTime? validTill,
    String? fileName,
    DateTime? uploadedAt,
    String? rejectionReason,
  }) = _DocumentModel;

  factory DocumentModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentModelFromJson(json);

  static List<DocumentModel> get fakeData => [
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
