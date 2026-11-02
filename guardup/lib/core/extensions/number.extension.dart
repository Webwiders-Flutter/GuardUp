import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/core/constants/app_constants.dart';

/// Extensions on [num] (covering [double] and [int]) for currency and number formatting.
extension NumberFormattingExtension on num {
  /// Formats this number into INR currency format (e.g. `₹ 28,000` or `₹ 2,45,000`).
  String get toInrAmount {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '${AppConstants.globalCurrency} ',
      decimalDigits: this is double && (this % 1 != 0) ? 2 : 0,
    );
    return formatter.format(this);
  }


  /// Converts this amount in Rupees (e.g. 500.50) to integer paise (50050).
  int get toPaise => (this * 100).round();

  /// Converts this amount in paise (e.g. 50050) back to double Rupees (500.50).
  double get toRupees => this / 100.0;

  Radius get toRadius => Radius.circular(toDouble());

  BorderRadius get toBorderRadius => BorderRadius.circular(toDouble());
}
