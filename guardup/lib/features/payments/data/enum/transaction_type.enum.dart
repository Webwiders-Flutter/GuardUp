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

  bool get isCredit => this == TransactionType.credit;
  bool get isDebit => this == TransactionType.debit;

  String get prefix => isCredit ? '+' : '-';

  IconData get icon =>
      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
}
