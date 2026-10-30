import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String? currencyCode,
    String defaultCurrency = 'USD',
  }) {
    final NumberFormat formatter = NumberFormat('#,##0.##');
    final formattedAmount = formatter.format(amount);
    return '${currencyCode ?? defaultCurrency} $formattedAmount';
  }
}
