import 'package:freezed_annotation/freezed_annotation.dart';
import '/features/users/data/enums/verification_status.enum.dart';

part 'user_document.model.freezed.dart';
part 'user_document.model.g.dart';

@freezed
abstract class UserDocumentModel with _$UserDocumentModel {
  const factory UserDocumentModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'document_type_id') String? documentTypeId,
    @JsonKey(name: 'document_type_name') String? documentTypeName,
    @JsonKey(name: 'file_url') required String fileUrl,
    @JsonKey(name: 'file_name') String? fileName,
    @Default(VerificationStatus.pending)
    @JsonKey(unknownEnumValue: VerificationStatus.pending)
    VerificationStatus verificationStatus,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _UserDocumentModel;

  factory UserDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$UserDocumentModelFromJson(json);
}
