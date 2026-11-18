import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

enum DiscountType {
  @JsonValue('PERCENTAGE')
  percentage('PERCENTAGE'),

  @JsonValue('FLAT')
  flat('FLAT');

  final String apiValue;

  const DiscountType(this.apiValue);

  bool get isPercentage => this == DiscountType.percentage;

  String get label {
    switch (this) {
      case DiscountType.percentage:
        return 'Percentage';
      case DiscountType.flat:
        return 'Flat Amount';
    }
  }

  String get subtitle {
    switch (this) {
      case DiscountType.percentage:
        return 'A % off the booking total, with an optional maximum amount';
      case DiscountType.flat:
        return 'A fixed amount off every booking';
    }
  }

  IconData get icon {
    switch (this) {
      case DiscountType.percentage:
        return Icons.percent_rounded;
      case DiscountType.flat:
        return Icons.payments_outlined;
    }
  }

  static DiscountType? fromApi(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    return DiscountType.values
        .where((e) => e.apiValue == normalized)
        .firstOrNull;
  }
}
