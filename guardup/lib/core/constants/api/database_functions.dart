final class DatabaseFunctions {
  const DatabaseFunctions._();

  /// Creates and sends notifications in batch via database trigger and FCM.
  static const String createAndSendNotification =
      'create_and_send_notification';

  /// Verifies if a user exists with the given phone number.
  static const String checkUserExists = 'check_user_exists';

  /// Verifies if a user exists with the given email address.
  static const String checkEmailExists = 'check_email_exists';

  /// Checks if either phone or email exists in public.users.
  static const String checkUserPhoneOrEmailExists =
      'check_user_phone_or_email_exists';

  /// Checks administrative role access.
  static const String isAdmin = 'is_admin';

  /// Creates or updates the caller's device row, keyed on the FCM token.
  static const String registerUserDevice = 'register_user_device';

  /// Changes the push language of one of the caller's devices.
  static const String updateUserDeviceLanguage = 'update_user_device_language';

  /// Replaces the services of a login account (guard / company) atomically.
  static const String setUserServices = 'set_user_services';

  /// Replaces the services of a company-managed bodyguard atomically.
  static const String setBodyguardServices = 'set_bodyguard_services';
}
