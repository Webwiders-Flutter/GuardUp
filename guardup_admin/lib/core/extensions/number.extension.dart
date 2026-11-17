import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Extensions on [num] (covering [double] and [int]) for currency and number formatting.
extension NumberFormattingExtension on num {
  /// Formats this number into INR currency format (e.g. `₹ 28,000` or `₹ 2,45,000`).
  String get toInrAmount {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '${AppConstants.currencySymbol} ',
      decimalDigits: this is double && (this % 1 != 0) ? 2 : 0,
    );
    return formatter.format(this);
  }

  String get toDistance {
    final value = this;

    final formatter = NumberFormat.decimalPattern('en_IN')
      ..maximumFractionDigits = value is double && value % 1 != 0 ? 2 : 0
      ..minimumFractionDigits = 0;

    return '${formatter.format(value)} ${AppConstants.globalDistanceUnit}';
  }
}

extension NullableNumberFormattingExtension on num? {
  String toInrAmountOr([String fallback = '—']) =>
      this != null ? this!.toInrAmount : fallback;

  String toDistanceOr([String fallback = '—']) =>
      this != null ? this!.toDistance : fallback;
}
