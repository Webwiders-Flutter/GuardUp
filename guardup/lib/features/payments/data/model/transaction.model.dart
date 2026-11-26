import 'package:freezed_annotation/freezed_annotation.dart';

import '../enum/transaction_status.enum.dart';
import '../enum/transaction_type.enum.dart';
import '../fixtures/payments.fixtures.dart';

part 'transaction.model.freezed.dart';
part 'transaction.model.g.dart';

/// Model representing a monetary transaction record in the user's wallet.
@freezed
abstract class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    required double amount,
    @Default('USD') String currency,
    required TransactionType type,
    required String title,
    required DateTime dateTime,
    @Default(TransactionStatus.completed) TransactionStatus status,
    String? bookingId,
    String? formattedDate,
    String? referenceId,
    String? gateway,
    String? scheduleText,
    String? discountNote,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  /// Curated fake transactions matching the exact wallet history design.
  @Deprecated('Use transactionFixtures from data/fixtures/payments.fixtures.dart')
  static List<TransactionModel> get fakeData => transactionFixtures;
}
