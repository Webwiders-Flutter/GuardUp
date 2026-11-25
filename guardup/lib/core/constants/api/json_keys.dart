final class JsonKeys {
  JsonKeys._();

  // General & Standard Entity Keys
  static const String id = 'id';
  static const String name = 'name';
  static const String nameHi = 'name_hi';
  static const String description = 'description';
  static const String descriptionHi = 'description_hi';
  static const String sortOrder = 'display_order';
  static const String userId = 'user_id';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isActive = 'is_active';

  // Account (users) Keys
  static const String role = 'role';
  static const String status = 'status';
  static const String rejectionReason = 'rejection_reason';
  static const String profileImageUrl = 'profile_image_url';
  static const String gender = 'gender';
  static const String phoneCode = 'phone_code';
  static const String phoneNumber = 'phone_number';
  static const String address = 'address';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';

  // Company profile (companies) Keys
  static const String companyId = 'company_id';
  static const String companyName = 'company_name';
  static const String businessEmail = 'business_email';
  static const String companyType = 'company_type';
  static const String companyPhoneCode = 'company_phone_code';
  static const String companyPhoneNumber = 'company_phone_number';

  // Bodyguard profile (bodyguards) Keys
  static const String bodyguardId = 'bodyguard_id';

  // Notification `data` payload keys (also sent with the push)
  static const String event = 'event';
  static const String route = 'route';
  static const String notificationId = 'notification_id';
  static const String hourlyRate = 'hourly_rate';
  static const String rating = 'rating';
  static const String experienceYears = 'experience_years';
  static const String bio = 'bio';
  static const String languages = 'languages';
  static const String certifications = 'certifications';
  static const String qualifications = 'qualifications';

  // Profile child tables
  static const String serviceId = 'service_id';
  static const String documentTypeId = 'document_type_id';
  static const String fileUrl = 'file_url';
  static const String fileName = 'file_name';

  // RPC parameters for set_user_services / set_bodyguard_services
  static const String pUserId = 'p_user_id';
  static const String pBodyguardId = 'p_bodyguard_id';
  static const String pServiceIds = 'p_service_ids';

  // Device & Push Notification Keys
  static const String token = 'token';
  static const String platform = 'platform';
  static const String languageCode = 'language_code';
  static const String lastActiveAt = 'last_active_at';

  // RPC parameters for register_user_device / update_user_device_language
  static const String pToken = 'p_token';
  static const String pPlatform = 'p_platform';
  static const String pLanguageCode = 'p_language_code';

  // Notification Keys
  static const String type = 'type';
  static const String title = 'title';
  static const String titleHi = 'title_hi';
  static const String body = 'body';
  static const String bodyHi = 'body_hi';
  static const String data = 'data';
  static const String imageUrl = 'image_url';
  static const String isRead = 'is_read';
  static const String readAt = 'read_at';
}
