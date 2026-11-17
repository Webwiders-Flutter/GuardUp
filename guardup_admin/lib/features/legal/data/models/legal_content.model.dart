import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../users/data/enums/user_role.enum.dart';
import '/features/legal/data/enums/content_type.enum.dart';
import '/core/enums/language.enum.dart';

part 'legal_content.model.freezed.dart';
part 'legal_content.model.g.dart';

/// Typedef for compound key identifying a specific legal document per role and language.
typedef LegalContentKey = ({
  ContentType type,
  UserRoleType role,
  LanguageType language,
});

@freezed
sealed class LegalContentModel with _$LegalContentModel {
  const LegalContentModel._();

  const factory LegalContentModel({
    String? id,
    required ContentType contentType,
    required UserRoleType role,
    @Default(LanguageType.english) LanguageType language,
    @Default('') String contentHtml,
    DateTime? createdAt,
    DateTime? lastPublishedAt,
  }) = _LegalContentModel;

  factory LegalContentModel.fromJson(Map<String, dynamic> json) =>
      _$LegalContentModelFromJson(json);

  LegalContentKey get key =>
      (type: contentType, role: role, language: language);
}
