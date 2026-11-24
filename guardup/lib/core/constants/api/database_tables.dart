final class DatabaseTables {
  const DatabaseTables._();
  static const String users = "users";

  /// Role profiles split out of [users] (see documentation/user_profiles.md).
  static const String companies = "companies";
  static const String bodyguards = "bodyguards";

  /// Read-only view: [users] + [companies] + [bodyguards] flattened per account.
  static const String userProfiles = "user_profiles";
  static const String services = "services";
  static const String userServices = "user_services";
  static const String documentTypes = "document_types";
  static const String userDocuments = "user_documents";
  static const String userAvailabilities = "user_availabilities";
  static const String userBankAccounts = "user_bank_accounts";
  static const String documents = "documents";
  static const String faqs = "faqs";
  static const String legalContent = "legal_content";
  static const String contactUs = "contact_us";
  static const String adminSettings = "admin_settings";
  static const String membershipPlans = "membership_plans";
  static const String notifications = "notifications";
  static const String userDevices = "user_devices";
}
