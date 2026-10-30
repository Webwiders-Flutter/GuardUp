import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension NumeralLocalization on dynamic {
  /// Converts English digits (1, 2, 3) to localized digits (e.g., ٠, ١, ٢ in Arabic)
  /// based on the current context locale.
  String localizeDigits(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return localizeWithLocale(locale);
  }

  String localizeWithLocale(String localeCode) {
    if (this == null) return '';

    // Format the number or string using the current locale
    if (this is num) {
      return NumberFormat('0', localeCode).format(this);
    }

    if (this is String) {
      final number = num.tryParse(this as String);
      if (number != null) {
        return NumberFormat('0', localeCode).format(number);
      }

      // If it's a string with numbers inside (e.g., "9+"), localize each digit
      if (localeCode == 'ar') {
        return (this as String).replaceAllMapped(RegExp(r'\d'), (Match m) {
          final digit = int.parse(m.group(0)!);
          return NumberFormat('0', 'ar').format(digit);
        });
      }
    }

    return toString();
  }
}
