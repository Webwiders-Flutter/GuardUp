class CountrySearchUtils {
  static const Map<String, List<String>> countryAliases = {
    'GB': ['uk', 'united kingdom', 'great britain'],
    'US': ['us', 'usa', 'united states', 'united states of america'],
    'AE': ['uae', 'united arab emirates', 'الإمارات', 'الامارات'],
    'SA': ['ksa', 'saudi arabia', 'السعودية', 'السعوديه'],
    'BH': ['bahrain', 'البحرين'],
    'DE': ['germany', 'ألمانيا', 'المانيا'],
    'ES': ['spain', 'إسبانيا', 'اسبانيا'],
    'FR': ['france', 'فرنسا'],
    'IT': ['italy', 'إيطاليا', 'ايطاليا'],
  };

  static String normalizeArabicText(String text) {
    var normalized = text.toLowerCase();
    // Remove diacritics / hamza
    normalized = normalized.replaceAll(RegExp(r'[أإآا]'), 'ا');
    normalized = normalized.replaceAll(RegExp(r'[ة]'), 'ه');
    normalized = normalized.replaceAll(RegExp(r'[يى]'), 'ي');
    normalized = normalized.replaceAll(RegExp(r'[ؤ]'), 'و');
    normalized = normalized.replaceAll(RegExp(r'[ئ]'), 'ي');
    return normalized.trim();
  }

  static bool matchesQuery(
    String query, {
    String? nameEn,
    String? nameAr,
    String? countryCode,
    String? phoneCode,
    String? searchKeywords,
  }) {
    if (query.trim().isEmpty) return true;

    final q = query.trim().toLowerCase();
    final normalizedQuery = normalizeArabicText(q);
    final phoneQuery = q.replaceAll(RegExp(r'[^\d]'), '');

    // Check english name
    if (nameEn != null) {
      final nameEnLower = nameEn.toLowerCase();
      if (nameEnLower.contains(q) ||
          normalizeArabicText(nameEnLower).contains(normalizedQuery)) {
        return true;
      }
    }

    // Check arabic name
    if (nameAr != null) {
      final nameArLower = nameAr.toLowerCase();
      if (nameArLower.contains(q) ||
          normalizeArabicText(nameArLower).contains(normalizedQuery)) {
        return true;
      }
    }

    // Check search keywords (from database)
    if (searchKeywords != null && searchKeywords.isNotEmpty) {
      final keywordsLower = searchKeywords.toLowerCase();
      if (keywordsLower.contains(q) ||
          normalizeArabicText(keywordsLower).contains(normalizedQuery)) {
        return true;
      }
    }

    // Check country code and aliases
    if (countryCode != null) {
      final codeUpper = countryCode.toUpperCase();
      final codeLower = countryCode.toLowerCase();
      if (codeLower.contains(q)) return true;

      // Check aliases
      final aliases = countryAliases[codeUpper];
      if (aliases != null) {
        for (final alias in aliases) {
          if (alias.contains(q) ||
              normalizeArabicText(alias).contains(normalizedQuery)) {
            return true;
          }
        }
      }
    }

    // Check phone code
    if (phoneCode != null && phoneQuery.isNotEmpty) {
      final cleanPhoneCode = phoneCode.replaceAll(RegExp(r'[^\d]'), '');
      var cleanPhoneQuery = phoneQuery.replaceFirst(RegExp(r'^0+'), '');
      if (cleanPhoneQuery.isEmpty) {
        cleanPhoneQuery = phoneQuery; // in case query is just "0"
      }

      if (cleanPhoneCode.contains(cleanPhoneQuery) ||
          cleanPhoneQuery.contains(cleanPhoneCode)) {
        return true;
      }
    }

    return false;
  }
}
