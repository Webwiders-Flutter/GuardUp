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
