import '/core/constants/api/json_keys.dart';

/// Request model representing payload for creating or updating a [Faq].
class FaqRequest {
  final String question;
  final String answer;
  final String? questionHi;
  final String? answerHi;
  final String? role;
  final int? sortOrder;
  final bool isActive;

  const FaqRequest({
    required this.question,
    required this.answer,
    this.questionHi,
    this.answerHi,
    this.role,
    this.sortOrder,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final q = question.trim();
    final a = answer.trim();
    final qHi = questionHi?.trim();
    final aHi = answerHi?.trim();
    final r = (role == null || role!.isEmpty || role == 'ALL') ? null : role;

    return <String, dynamic>{
      JsonKeys.question: q,
      JsonKeys.answer: a,
      JsonKeys.questionHi: (qHi != null && qHi.isNotEmpty) ? qHi : null,
      JsonKeys.answerHi: (aHi != null && aHi.isNotEmpty) ? aHi : null,
      JsonKeys.role: r,
      JsonKeys.sortOrder: sortOrder,
      JsonKeys.isActive: isActive,
    };
  }
}
