final class AppConstants {
  AppConstants._();
  static const String appName = 'GuardUp';

  static const int paginationLimit = 10;
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const int sortOrderGap = 1000;
  static const int indiaCountryId = 101;

  static const String globalCurrency = '₹';

  static const int resendSeconds = 60;
}
