import 'package:flutter/material.dart';
import 'package:guardup/core/utils/extensions/context_extensions.dart';

class StudyProfileHelper {
  static const Map<String, String> _enToAr = {
    // Fields
    'Computer Science': 'علوم الحاسوب',
    'Data Science & AI': 'علوم البيانات والذكاء الاصطناعي',
    'Business & Management': 'إدارة الأعمال',
    'Engineering & Tech': 'الهندسة والتكنولوجيا',
    'Medicine & Healthcare': 'الطب والرعاية الصحية',
    'Arts & Humanities': 'الآداب والعلوم الإنسانية',
    'Law & Legal Studies': 'القانون والدراسات القانونية',
    'Finance & Accounting': 'المالية والمحاسبة',
    'Marketing & Media': 'التسويق والإعلام',
    'Natural Sciences': 'العلوم الطبيعية',

    // Specialisations
    'Data Science': 'علوم البيانات',
    'Software Engineering': 'هندسة البرمجيات',
    'Artificial Intelligence': 'الذكاء الاصطناعي',
    'Cyber Security': 'الأمن السيبراني',
    'Financial Management': 'الإدارة المالية',
    'Biomedical Engineering': 'الهندسة الحيوية الطبية',
    'International Business': 'الأعمال الدولية',
    'Digital Marketing': 'التسويق الرقمي',
    'Civil Engineering': 'الهندسة المدنية',
    'Psychology': 'علم النفس',

    // Intakes
    'Fall 2024': 'خريف 2024',
    'Spring 2025': 'ربيع 2025',
    'Fall 2025': 'خريف 2025',
    'Spring 2026': 'ربيع 2026',
    'Fall 2026': 'خريف 2026',
    'Spring 2027': 'ربيع 2027',
    'Fall 2027': 'خريف 2027',
    'Spring 2028': 'ربيع 2028',
    'Fall': 'خريف',
    'Spring': 'ربيع',
    'Summer': 'صيف',
    'Winter': 'شتاء',

    // Degrees
    'Undergraduate': 'بكالوريوس',
    'Graduate': 'دراسات عليا',
    'Diploma': 'دبلوم',
    'PhD': 'دكتوراه',
    'Certificate': 'شهادة',
    'Bachelors': 'بكالوريوس',
    'Master': 'ماجستير',
    'Doctorate': 'دكتوراه',
  };

  static final Map<String, String> _arToEn = {
    for (var entry in _enToAr.entries) entry.value: entry.key,
  };

  /// Returns the English string for a given value (if known or convertible).
  static String? toEn(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (_arToEn.containsKey(trimmed)) return _arToEn[trimmed];
    final arMatch = RegExp(r'^(خريف|ربيع|صيف|شتاء)\s+(\d{4})$')
        .firstMatch(trimmed);
    if (arMatch != null) {
      final arSeason = arMatch.group(1)!;
      final year = arMatch.group(2)!;
      final enSeason = _arToEn[arSeason] ?? arSeason;
      return '$enSeason $year';
    }
    return trimmed;
  }

  /// Returns the Arabic string for a given value (if known or convertible).
  static String? toAr(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (_enToAr.containsKey(trimmed)) return _enToAr[trimmed];
    final enMatch = RegExp(
      r'^(Fall|Spring|Summer|Winter)\s+(\d{4})$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (enMatch != null) {
      final enSeason = enMatch.group(1)!;
      final year = enMatch.group(2)!;
      final normSeason =
          enSeason[0].toUpperCase() + enSeason.substring(1).toLowerCase();
      final arSeason = _enToAr[normSeason] ?? normSeason;
      return '$arSeason $year';
    }
    return trimmed;
  }

  /// Translates a given study profile string based on the active locale.
  static String getLocalizedText(String? value, BuildContext context) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    final isArabic = context.isArabic;

    if (isArabic) {
      return toAr(trimmed) ?? trimmed;
    } else {
      return toEn(trimmed) ?? trimmed;
    }
  }

  /// Lists for English
  static const List<String> fieldsEn = [
    'Computer Science',
    'Data Science & AI',
    'Business & Management',
    'Engineering & Tech',
    'Medicine & Healthcare',
    'Arts & Humanities',
    'Law & Legal Studies',
    'Finance & Accounting',
    'Marketing & Media',
    'Natural Sciences',
  ];

  static const List<String> specialisationsEn = [
    'Data Science',
    'Software Engineering',
    'Artificial Intelligence',
    'Cyber Security',
    'Financial Management',
    'Biomedical Engineering',
    'International Business',
    'Digital Marketing',
    'Civil Engineering',
    'Psychology',
  ];

  static const List<String> intakesEn = [
    'Fall 2024',
    'Spring 2025',
    'Fall 2025',
    'Spring 2026',
    'Fall 2026',
    'Spring 2027',
    'Fall 2027',
    'Spring 2028',
  ];

  /// Returns true if an intake's nominal end date is in the future.
  static bool isIntakeFuture(String intake) {
    final parts = intake.trim().split(' ');
    if (parts.length < 2) return true;
    final season = parts[0].toLowerCase();
    final year = int.tryParse(parts[1]);
    if (year == null) return true;

    final now = DateTime.now();

    DateTime endDate;
    if (season.contains('spring')) {
      endDate = DateTime(year, 6, 30);
    } else if (season.contains('summer')) {
      endDate = DateTime(year, 8, 31);
    } else if (season.contains('fall') || season.contains('autumn')) {
      endDate = DateTime(year, 12, 31);
    } else if (season.contains('winter')) {
      endDate = DateTime(year, 2, 28);
    } else {
      endDate = DateTime(year, 12, 31);
    }

    return endDate.isAfter(now);
  }

  /// Dynamically generated future intakes (current year up to current year + 3).
  static List<String> get dynamicFutureIntakesEn {
    final now = DateTime.now();
    final currentYear = now.year;
    final List<String> result = [];

    for (int y = currentYear; y <= currentYear + 3; y++) {
      for (final season in ['Spring', 'Fall']) {
        final intake = '$season $y';
        if (isIntakeFuture(intake)) {
          result.add(intake);
        }
      }
    }
    return result;
  }

  static List<String> getFields(BuildContext context) {
    return fieldsEn.map((f) => getLocalizedText(f, context)).toList();
  }

  static List<String> getSpecialisations(BuildContext context) {
    return specialisationsEn.map((s) => getLocalizedText(s, context)).toList();
  }

  static List<String> getIntakes(BuildContext context) {
    return dynamicFutureIntakesEn
        .map((i) => getLocalizedText(i, context))
        .toList();
  }
}
