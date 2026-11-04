import '../enum/transaction_type.enum.dart';

/// Model representing a monetary transaction record in the user's wallet.
class TransactionModel {
  final String id;
  final double amount;
  final String currency;
  final TransactionType type;
  final String title;
  final DateTime dateTime;
  final String? bookingId;
  final String? formattedDate;

  const TransactionModel({
    required this.id,
    required this.amount,
    this.currency = 'USD',
    required this.type,
    required this.title,
    required this.dateTime,
    this.bookingId,
    this.formattedDate,
  });

  /// Formats amount into clean string: e.g. "$250 USD".
  String get amountFormatted {
    final isInt = amount.truncateToDouble() == amount;
    final formattedValue = isInt ? amount.toInt().toString() : amount.toStringAsFixed(2);
    return '\$$formattedValue $currency';
  }

  /// Display date representation.
  String get displayDate => formattedDate ?? '23 March 2026, 06:36pm';

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? currency,
    TransactionType? type,
    String? title,
    DateTime? dateTime,
    String? bookingId,
    String? formattedDate,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      bookingId: bookingId ?? this.bookingId,
      formattedDate: formattedDate ?? this.formattedDate,
    );
  }

  /// Curated fake transactions matching the exact wallet history design.
  static List<TransactionModel> get fakeData => [
    TransactionModel(
      id: 'tx_1',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f23234',
      bookingId: '#f23234',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_2',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_3',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f23234',
      bookingId: '#f23234',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_4',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_5',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f23234',
      bookingId: '#f23234',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_6',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_7',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f23234',
      bookingId: '#f23234',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_8',
      amount: 250.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 23, 18, 36),
      formattedDate: '23 March 2026, 06:36pm',
    ),
    TransactionModel(
      id: 'tx_9',
      amount: 400.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f88912',
      bookingId: '#f88912',
      dateTime: DateTime(2026, 3, 22, 14, 15),
      formattedDate: '22 March 2026, 02:15pm',
    ),
    TransactionModel(
      id: 'tx_10',
      amount: 150.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 21, 10, 0),
      formattedDate: '21 March 2026, 10:00am',
    ),
    TransactionModel(
      id: 'tx_11',
      amount: 520.0,
      currency: 'USD',
      type: TransactionType.credit,
      title: 'Received from booking ID #f44102',
      bookingId: '#f44102',
      dateTime: DateTime(2026, 3, 20, 19, 45),
      formattedDate: '20 March 2026, 07:45pm',
    ),
    TransactionModel(
      id: 'tx_12',
      amount: 300.0,
      currency: 'USD',
      type: TransactionType.debit,
      title: 'Bank Withdraw',
      dateTime: DateTime(2026, 3, 19, 11, 20),
      formattedDate: '19 March 2026, 11:20am',
    ),
  ];
}

