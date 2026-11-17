import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/api/json_keys.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '../../data/models/admin_settings.model.dart';
import '../../data/repositories/admin_settings.repository.dart';
import '../../di/admin_settings.providers.dart';

/// Controller managing platform-wide administrative settings state.
class AdminSettingsController extends AsyncNotifier<AdminSettingsModel> {
  AdminSettingsRepository get _repository =>
      ref.read(adminSettingsRepositoryProvider);

  @override
  FutureOr<AdminSettingsModel> build() async {
    return _repository.getSettings();
  }

  /// Forces a fresh reload of settings from Supabase.
  Future<void> refreshSettings() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => asyncHandler(() => _repository.getSettings()),
    );
  }

  /// Updates settings with arbitrary field map.
  Future<void> updateSettings(
    Map<String, dynamic> data, {
    bool loading = true,
  }) async {
    final current = state.value;
    if (loading) {
      state = const AsyncLoading();
    }

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        return _repository.updateSettings(data);
      }),
    );

    if (loading || result.hasError) {
      state = result;
    } else if (result.hasValue) {
      state = AsyncData(result.requireValue);
    }

    if (result.hasError && current != null) {
      // Revert to current on background failure
      state = AsyncData(current);
      throw result.error!;
    }
  }

  /// Optimistically toggles system maintenance mode.
  Future<void> toggleMaintenance(bool isUnderMaintenance) async {
    final current = state.value;
    if (current != null) {
      // Rule 29: Optimistic instant local UI update
      state = AsyncData(
        current.copyWith(isUnderMaintenance: isUnderMaintenance),
      );
    }

    return updateSettings({
      JsonKeys.isUnderMaintenance: isUnderMaintenance,
    }, loading: false);
  }

  /// Updates maintenance information.
  Future<void> saveMaintenanceSettings({
    required bool isUnderMaintenance,
    required String title,
    required String message,
  }) async {
    return updateSettings({
      JsonKeys.isUnderMaintenance: isUnderMaintenance,
      JsonKeys.maintenanceTitle: title.trim(),
      JsonKeys.maintenanceMessage: message.trim(),
    });
  }

  /// Updates mobile app version requirements and store URLs.
  Future<void> saveMobileAppSettings({
    required String latestIosVersion,
    required String minimumIosVersion,
    required String updateMessageIos,
    required String iosAppUrl,
    required String latestAndroidVersion,
    required String minimumAndroidVersion,
    required String updateMessageAndroid,
    required String androidAppUrl,
  }) async {
    return updateSettings({
      JsonKeys.latestIosVersion: latestIosVersion.trim(),
      JsonKeys.minimumIosVersion: minimumIosVersion.trim(),
      JsonKeys.updateMessageIos: updateMessageIos.trim(),
      JsonKeys.iosAppUrl: iosAppUrl.trim(),
      JsonKeys.latestAndroidVersion: latestAndroidVersion.trim(),
      JsonKeys.minimumAndroidVersion: minimumAndroidVersion.trim(),
      JsonKeys.updateMessageAndroid: updateMessageAndroid.trim(),
      JsonKeys.androidAppUrl: androidAppUrl.trim(),
    });
  }

  /// Updates contact and support channel details.
  Future<void> saveSupportSettings({
    required String supportEmail,
    required String supportCallPhoneNumber,
    required String supportWhatsappPhoneNumber,
    required String supportHours,
  }) async {
    return updateSettings({
      JsonKeys.supportEmail: supportEmail.trim(),
      JsonKeys.supportCallPhoneNumber: supportCallPhoneNumber.trim(),
      JsonKeys.supportWhatsappPhoneNumber: supportWhatsappPhoneNumber.trim(),
      JsonKeys.supportHours: supportHours.trim(),
    });
  }
}
