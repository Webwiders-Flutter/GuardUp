import 'package:flutter/material.dart';
import 'package:guardup/l10n/generated/app_localizations.dart';

class MissingDocsFormatter {
  static String format(String? rawNote, {required bool isArabic}) {
    if (rawNote == null || rawNote.trim().isEmpty) {
      return lookupAppLocalizations(Locale(isArabic ? 'ar' : 'en'))
          .pleaseUploadRequiredDocs;
    }

    final trimmed = rawNote.trim();
    if (trimmed.startsWith('REQ_DOCS:[')) {
      final closingBracketIndex = trimmed.indexOf(']');
      if (closingBracketIndex > 10) {
        final idsStr = trimmed.substring(10, closingBracketIndex);
        final docIds = idsStr
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final cleanNote = trimmed.substring(closingBracketIndex + 1).trim();

        if (docIds.isNotEmpty) {
          final docNames = docIds
              .map((id) => _getDocTitle(id, isArabic))
              .toList();
          final joinedNames = docNames.join(isArabic ? '، ' : ', ');
          final mainText = isArabic
              ? 'يرجى تحميل $joinedNames.'
              : 'Please upload your $joinedNames.';

          if (cleanNote.isNotEmpty) {
            return '$mainText ($cleanNote)';
          }
          return mainText;
        }

        if (cleanNote.isNotEmpty) return cleanNote;
      }
    }

    return trimmed;
  }

  static String _getDocTitle(String docId, bool isArabic) {
    switch (docId.toLowerCase().trim()) {
      case 'passport':
      case 'passpert':
      case 'passport_copy':
        return isArabic ? 'صورة الجواز' : 'Passport Copy';
      case 'transcripts':
      case 'transcript':
        return isArabic ? 'كشف الدرجات والشهادات' : 'Academic Transcripts';
      case 'sop':
      case 'statement_of_purpose':
        return isArabic
            ? 'خطاب الغرض من الدراسة'
            : 'Statement of Purpose (SOP)';
      case 'cv':
      case 'resume':
        return isArabic ? 'السيرة الذاتية' : 'CV / Resume';
      case 'recommendation':
      case 'recommendation_letter':
      case 'recommendation_letters':
        return isArabic ? 'خطابات التوصية' : 'Recommendation Letters';
      case 'language_test':
      case 'language_certificate':
      case 'english':
      case 'ielts':
      case 'toefl':
        return isArabic
            ? 'شهادة / نتيجة اختبار اللغة'
            : 'Language Certificate / Test Result';
      case 'birth_certificate':
        return isArabic ? 'شهادة الميلاد' : 'Birth Certificate';
      case 'national_id':
      case 'id':
        return isArabic ? 'بطاقة الهوية' : 'National ID';
      case 'financial_proof':
      case 'bank_statement':
        return isArabic
            ? 'إثبات القدرة المالية'
            : 'Financial Proof / Bank Statement';
      case 'medical':
      case 'medical_certificate':
        return isArabic ? 'الشهادة الطبية' : 'Medical Certificate';
      case 'photos':
      case 'photo':
        return isArabic ? 'صور شخصية' : 'Personal Photos';
      default:
        // Humanize unknown IDs (replace _ with space, title-case)
        final humanized = docId
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');
        return humanized.isNotEmpty
            ? humanized
            : (isArabic ? 'مستند مطلوب' : 'Required Document');
    }
  }
}
