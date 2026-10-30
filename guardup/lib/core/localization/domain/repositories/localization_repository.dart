abstract class LocalizationRepository {
  Future<void> saveLocale(String localeCode);
  Future<String?> getLocale();
}
