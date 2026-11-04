import 'package:flutter/material.dart';

/// Semantic transaction type representing funds credited or debited.
enum TransactionType {
  credit,
  debit;

  bool get isCredit => this == TransactionType.credit;
  bool get isDebit => this == TransactionType.debit;

  String get prefix => isCredit ? '+' : '-';

  IconData get icon => isCredit
      ? Icons.arrow_downward_rounded
      : Icons.arrow_upward_rounded;
}

