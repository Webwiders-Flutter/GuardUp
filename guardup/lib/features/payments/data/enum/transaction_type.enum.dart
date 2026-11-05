import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Semantic transaction type representing funds credited or debited.
enum TransactionType {
  @JsonValue('CREDIT')
  credit('CREDIT'),

  @JsonValue('DEBIT')
  debit('DEBIT');

  final String apiValue;

  const TransactionType(this.apiValue);

  static TransactionType fromApiValue(String? value) {
    if (value == null) return TransactionType.credit;
    return TransactionType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      orElse: () => TransactionType.credit,
    );
  }

  static TransactionType? tryFromApiValue(String? value) {
    if (value == null) return null;
    try {
      return TransactionType.values.firstWhere(
        (e) => e.apiValue.toUpperCase() == value.toUpperCase().trim(),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isCredit => this == TransactionType.credit;
  bool get isDebit => this == TransactionType.debit;

  String get prefix => isCredit ? '+' : '-';

  IconData get icon =>
      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
}
