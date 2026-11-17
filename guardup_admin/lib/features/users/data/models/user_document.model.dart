import 'package:freezed_annotation/freezed_annotation.dart';
import '/features/document-type/data/models/document_type.model.dart';
import '/features/users/data/enums/verification_status.enum.dart';

part 'user_document.model.freezed.dart';
part 'user_document.model.g.dart';


@freezed
abstract class UserDocumentModel with _$UserDocumentModel {
  const UserDocumentModel._();

  const factory UserDocumentModel({
    required String id,
    required String userId,
    String? documentTypeId,
    String? documentTypeName,
    DocumentTypeModel? documentType,
    required String fileUrl,
    String? fileName,
    @Default(VerificationStatus.pending)
    @JsonKey(name: 'status')
    VerificationStatus verificationStatus,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserDocumentModel;

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$UserDocumentModelFromJson(json);

  String? get resolvedDocumentName => documentType?.name ?? documentTypeName;
}
