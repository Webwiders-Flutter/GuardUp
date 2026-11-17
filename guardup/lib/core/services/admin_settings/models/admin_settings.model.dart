/// Model representing global platform admin settings from public.admin_settings.
class AdminSettingsModel {
  final String id;
  final String latestIosVersion;
  final String latestAndroidVersion;
  final String minimumIosVersion;
  final String minimumAndroidVersion;
  final String? updateMessageIos;
  final String? updateMessageAndroid;
  final String? iosAppUrl;
  final String? androidAppUrl;
  final String supportEmail;
  final String supportCallPhoneNumber;
  final String supportWhatsappPhoneNumber;
  final String? supportHours;
  final bool isUnderMaintenance;
  final String? maintenanceTitle;
  final String? maintenanceMessage;
  final double bodyguardFee;
  final double companyFee;
  final bool singletonGuard;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminSettingsModel({
    required this.id,
    this.latestIosVersion = '1.0.0',
    this.latestAndroidVersion = '1.0.0',
    this.minimumIosVersion = '1.0.0',
    this.minimumAndroidVersion = '1.0.0',
    this.updateMessageIos,
    this.updateMessageAndroid,
    this.iosAppUrl,
    this.androidAppUrl,
    this.supportEmail = 'support@guardup.com',
    this.supportCallPhoneNumber = '+919876543210',
    this.supportWhatsappPhoneNumber = '+919876543210',
    this.supportHours = '10:00 AM - 7:00 PM (Mon-Sat)',
    this.isUnderMaintenance = false,
    this.maintenanceTitle = 'App Under Maintenance',
    this.maintenanceMessage =
        'We are currently upgrading our systems. Please check back shortly.',
    this.bodyguardFee = 0.0,
    this.companyFee = 0.0,
    this.singletonGuard = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminSettingsModel(
      id: (json['id'] ?? '') as String,
      latestIosVersion: (json['latest_ios_version'] ?? '1.0.0') as String,
      latestAndroidVersion:
          (json['latest_android_version'] ?? '1.0.0') as String,
      minimumIosVersion: (json['minimum_ios_version'] ?? '1.0.0') as String,
      minimumAndroidVersion:
          (json['minimum_android_version'] ?? '1.0.0') as String,
      updateMessageIos: json['update_message_ios'] as String?,
      updateMessageAndroid: json['update_message_android'] as String?,
      iosAppUrl: json['ios_app_url'] as String?,
      androidAppUrl: json['android_app_url'] as String?,
      supportEmail: (json['support_email'] ?? 'support@guardup.com') as String,
      supportCallPhoneNumber:
          (json['support_call_phone_number'] ?? '+919876543210') as String,
      supportWhatsappPhoneNumber:
          (json['support_whatsapp_phone_number'] ?? '+919876543210') as String,
      supportHours: json['support_hours'] as String?,
      isUnderMaintenance: (json['is_under_maintenance'] ?? false) as bool,
      maintenanceTitle: json['maintenance_title'] as String?,
      maintenanceMessage: json['maintenance_message'] as String?,
      bodyguardFee:
          double.tryParse(json['bodyguard_fee']?.toString() ?? '') ?? 0.0,
      companyFee:
          double.tryParse(json['company_fee']?.toString() ?? '') ?? 0.0,
      singletonGuard: (json['singleton_guard'] ?? true) as bool,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  factory AdminSettingsModel.initial() => const AdminSettingsModel(id: '');
}

