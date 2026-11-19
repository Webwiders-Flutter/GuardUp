import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_settings.model.freezed.dart';
part 'admin_settings.model.g.dart';

@freezed
sealed class AdminSettingsModel with _$AdminSettingsModel {
  const AdminSettingsModel._();

  const factory AdminSettingsModel({
    required String id,
    @Default('1.0.0') String latestIosVersion,
    @Default('1.0.0') String latestAndroidVersion,
    @Default('1.0.0') String minimumIosVersion,
    @Default('1.0.0') String minimumAndroidVersion,
    @Default(
      'A new version of the app is available. Please update to continue using GuardUp.',
    )
    String? updateMessageIos,
    @Default(
      'A new version of the app is available. Please update to continue using GuardUp.',
    )
    String? updateMessageAndroid,
    @Default('https://apps.apple.com/app/guardup') String? iosAppUrl,
    @Default('https://play.google.com/store/apps/details?id=com.guardup.app')
    String? androidAppUrl,
    @Default('support@guardup.com') String supportEmail,
    @Default('+919876543210') String supportCallPhoneNumber,
    @Default('+919876543210') String supportWhatsappPhoneNumber,
    @Default('10:00 AM - 7:00 PM (Mon-Sat)') String? supportHours,
    @Default(false) bool isUnderMaintenance,
    @Default('App Under Maintenance') String? maintenanceTitle,
    @Default(
      'We are currently upgrading our systems. Please check back shortly.',
    )
    String? maintenanceMessage,
    @Default(0.0) double bodyguardFee,
    @Default(0.0) double companyFee,
    @Default(true) bool singletonGuard,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AdminSettingsModel;

  factory AdminSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$AdminSettingsModelFromJson(json);

  /// Factory providing default placeholder settings before database load.
  factory AdminSettingsModel.initial() => const AdminSettingsModel(
    id: '',
    latestIosVersion: '1.0.0',
    latestAndroidVersion: '1.0.0',
    minimumIosVersion: '1.0.0',
    minimumAndroidVersion: '1.0.0',
    updateMessageIos:
        'A new version of the app is available. Please update to continue using GuardUp.',
    updateMessageAndroid:
        'A new version of the app is available. Please update to continue using GuardUp.',
    iosAppUrl: 'https://apps.apple.com/app/guardup',
    androidAppUrl:
        'https://play.google.com/store/apps/details?id=com.guardup.app',
    supportEmail: 'support@guardup.com',
    supportCallPhoneNumber: '+919876543210',
    supportWhatsappPhoneNumber: '+919876543210',
    supportHours: '10:00 AM - 7:00 PM (Mon-Sat)',
    isUnderMaintenance: false,
    maintenanceTitle: 'App Under Maintenance',
    maintenanceMessage:
        'We are currently upgrading our systems. Please check back shortly.',
    bodyguardFee: 0.0,
    companyFee: 0.0,
    singletonGuard: true,
  );
}
