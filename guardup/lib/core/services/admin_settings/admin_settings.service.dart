import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/core/constants/api/database_tables.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import 'models/admin_settings.model.dart';

/// Singleton service responsible for fetching and caching platform configuration
/// and registration fee prices from [DatabaseTables.adminSettings] once upon app open.
class AdminSettingsService {
  static final AdminSettingsService instance = AdminSettingsService._();
  AdminSettingsService._();

  AdminSettingsModel _settings = AdminSettingsModel.initial();
  AdminSettingsModel get settings => _settings;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Fetches admin settings from Supabase table `public.admin_settings` once when app opens.
  Future<AdminSettingsModel> init() async {
    if (_isInitialized) return _settings;

    try {
      final data = await Supabase.instance.client
          .from(DatabaseTables.adminSettings)
          .select()
          .limit(1)
          .maybeSingle();

      if (data != null) {
        _settings = AdminSettingsModel.fromJson(data);
        _isInitialized = true;
      }
    } catch (e, st) {
      debugPrint('Failed to load admin settings: $e\n$st');
    }

    return _settings;
  }

  /// Returns the dynamic registration fee based on the user's role.
  /// Bodyguard (`GUARD`) -> `bodyguardFee`
  /// Company (`COMPANY`) -> `companyFee`
  double getRegistrationFee(UserRole? role) {
    if (role == UserRole.company) {
      return _settings.companyFee;
    }
    return _settings.bodyguardFee;
  }
}

