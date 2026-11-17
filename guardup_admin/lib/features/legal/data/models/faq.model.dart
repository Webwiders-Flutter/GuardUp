import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../users/data/enums/user_role.enum.dart';
export 'faq_request.model.dart';

part 'faq.model.freezed.dart';
part 'faq.model.g.dart';

@freezed
sealed class Faq with _$Faq {
  const factory Faq({
    required String id,
    required String question,
    required String answer,
    String? questionHi,
    String? answerHi,
    UserRoleType? role,
    @Default(0) int sortOrder,
    @Default(true) bool isActive,
    String? createdAt,
    String? updatedAt,
  }) = _Faq;

  factory Faq.fromJson(Map<String, dynamic> json) => _$FaqFromJson(json);
}
