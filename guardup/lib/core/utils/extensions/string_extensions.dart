import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

extension StringNumberFormatting on String? {
  String toCompactNumberCount() {
    if (this == null || this!.isEmpty) return '0';

    final number = double.tryParse(this!);
    if (number != null) {
      return NumberFormat.compact().format(number);
    }

    return this!;
  }
}

extension IntNumberFormatting on int {
  String toCompactNumberCount() {
    return NumberFormat.compact().format(this);
  }
}

extension StringIdFormatting on String? {
  /// Returns the first [length] characters of the string (default 8),
  /// useful for displaying short request IDs.
  /// Change [length] in one place to update everywhere.
  static const int defaultIdLength = 8;

  String toShortId({int length = defaultIdLength}) {
    if (this == null || this!.isEmpty) return '-';
    final clean = this!.replaceAll('-', '').toUpperCase(); // strip UUID hyphens
    return clean.length <= length ? clean : clean.substring(0, length);
  }
}

extension StringFileTypeChecking on String? {
  bool get isPdf {
    if (this == null) return false;
    final cleanUrl = this!.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.pdf');
  }

  bool get isImage {
    if (this == null) return false;
    final cleanUrl = this!.split('?').first.toLowerCase();
    return cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.gif') ||
        cleanUrl.endsWith('.webp');
  }

  bool get isDocument {
    return isPdf || isImage;
  }
}

extension CurrentUserChecking on String {
  /// Checks if this string ID matches the currently logged-in Supabase user ID.
  bool get isCurrentUser {
    return this == Supabase.instance.client.auth.currentUser?.id;
  }

  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  /// Normalizes Arabic text by replacing variations of Alif, Yeh, and Te Marbuta
  /// with their basic forms. Useful for search queries.
  String normalizeArabic() {
    String text = this;
    // Remove diacritics
    text = text.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    // Replace Alif variations
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Replace Te Marbuta with Heh
    text = text.replaceAll('ة', 'ه');
    // Replace Alef Maksura with Yeh
    text = text.replaceAll('ى', 'ي');
    return text;
  }

  /// Converts an Arabic search term into a PostgreSQL regex pattern that matches
  /// variations of the same word.
  String toArabicSearchRegex() {
    String pattern = this;
    // Hamza variations
    pattern = pattern.replaceAll(RegExp(r'[اأإآ]'), '[اأإآ]');
    // Te Marbuta / Heh variations
    pattern = pattern.replaceAll(RegExp(r'[ةه]'), '[ةه]');
    // Alef Maksura / Yeh variations
    pattern = pattern.replaceAll(RegExp(r'[ىي]'), '[ىي]');
    return pattern;
  }

  /// Removes stray CJK (Chinese, Japanese, Korean) characters (e.g., 申请)
  /// that may accidentally leak into non-Chinese text responses.
  String cleanForeignCharacters() {
    if (isEmpty) return this;
    final cleaned = replaceAll(
      RegExp(
        r'[\u4E00-\u9FFF\u3400-\u4DBF\uF900-\uFAFF\u3000-\u303F\uFF00-\uFFEF]',
      ),
      '',
    );
    return cleaned.replaceAll(RegExp(r'  +'), ' ').trim();
  }

  /// Converts a 2-letter country code (like 'US', 'EG') to its emoji flag.
  String get toFlagEmoji {
    if (length != 2) return this;
    final String upperCaseCode = toUpperCase();

    // Ensure the code consists of exactly 2 A-Z letters
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(upperCaseCode)) return this;

    final int flagOffset = 0x1F1E6;
    final int asciiOffset = 0x41;

    final int firstChar =
        upperCaseCode.codeUnitAt(0) - asciiOffset + flagOffset;
    final int secondChar =
        upperCaseCode.codeUnitAt(1) - asciiOffset + flagOffset;

    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }
}
