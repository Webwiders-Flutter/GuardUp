final class DatabaseTables {
  const DatabaseTables._();
  static const String users = "users";

  /// Role profiles split out of [users] (see documentation/user_profiles.md).
  static const String companies = "companies";
  static const String bodyguards = "bodyguards";

  /// Read-only view: [users] + [companies] + [bodyguards] flattened per account.
  static const String userProfiles = "user_profiles";
  static const String documentTypes = "document_types";
  static const String truckTypes = "truck_types";
  static const String unitTypes = "unit_types";
  static const String truckBodyTypes = "truck_body_types";
  static const String faqs = "faqs";
  static const String legalContent = "legal_content";
  static const String contactUs = "contact_us";
  static const String businessTypes = "business_types";
  static const String materialTypes = "material_types";
  static const String userDealtMaterials = "user_dealt_materials";
  static const String userBankAccounts = "user_bank_accounts";
  static const String userAvailabilities = "user_availabilities";
  static const String userDocuments = "user_documents";
  static const String trucks = "trucks";
  static const String truckDocuments = "truck_documents";
  static const String adminSettings = "admin_settings";
  static const String services = "services";
  static const String userServices = "user_services";
  static const String orders = "orders";
  static const String orderDocuments = "order_documents";
  static const String party = "party";
  static const String trips = "trips";
  static const String tripDocuments = "trip_documents";
  static const String payments = "payments";
  static const String userDevices = "user_devices";
  static const String notifications = "notifications";
  static const String membershipPlans = "membership_plans";
}
