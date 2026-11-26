import 'package:freezed_annotation/freezed_annotation.dart';

import '/core/utils/json_converters/enum.jsonconverter.dart';
import '/features/body_guard/data/enum/document_status.enum.dart';
import 'document_type.model.dart';

part 'user_document.model.freezed.dart';
part 'user_document.model.g.dart';

DocumentStatus _documentStatusFromJson(dynamic value) {
  if (value == null) return DocumentStatus.pending;
  return DocumentStatus.values.parse(
    value,
    defaultValue: DocumentStatus.pending,
  );
}

String _documentStatusToJson(DocumentStatus status) => status.apiValue;

@freezed
abstract class UserDocumentModel with _$UserDocumentModel {
  const UserDocumentModel._();

  const factory UserDocumentModel({
    required String id,

    /// Owner: a login account (`user_id`) or a company-managed bodyguard
    /// (`bodyguard_id`); exactly one is set.
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'bodyguard_id') String? bodyguardId,
    @JsonKey(name: 'document_type_id') required String documentTypeId,
    @JsonKey(name: 'document_type_name') String? documentTypeName,
    @JsonKey(name: 'document_type') DocumentTypeModel? documentType,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(
      name: 'status',
      fromJson: _documentStatusFromJson,
      toJson: _documentStatusToJson,
    )
    @Default(DocumentStatus.pending)
    DocumentStatus status,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'valid_till') DateTime? validTill,
    @JsonKey(name: 'uploaded_at') DateTime? uploadedAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserDocumentModel;

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$UserDocumentModelFromJson(json);

  String? get resolvedDocumentName => documentType?.name ?? documentTypeName;
  DocumentStatus get verificationStatus => status;
}
