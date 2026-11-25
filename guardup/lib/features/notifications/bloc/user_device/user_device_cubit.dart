import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/app_logger.dart';
import '/core/services/notification/push_notification_service.dart';
import '../../data/models/user_device.model.dart';
import '../../data/repositories/user_device_repository.dart';

/// Cubit managing user device registration state and FCM token synchronization with Supabase.
class UserDeviceCubit extends Cubit<UserDeviceModel?> {
  final UserDeviceRepository _repository;
  StreamSubscription<String>? _tokenRefreshSubscription;

  UserDeviceCubit({required this._repository})
    : super(null);

  /// Resolves the current runtime platform string ('android' | 'ios' | 'web').
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  /// Retrieves the current device FCM token and registers/updates it in Supabase `user_devices`.
  Future<UserDeviceModel?> syncCurrentDevice({
    required String userId,
    String languageCode = 'en',
  }) async {
    if (userId.isEmpty) return null;

    try {
      final token = await PushNotificationService.getToken();
      if (token == null || token.isEmpty) {
        AppLogger.w(
          'syncCurrentDevice: FCM token is null or empty. Skipping registration.',
          tag: 'UserDeviceCubit',
        );
        return null;
      }

      final device = await _repository.upsertDevice(
        token: token,
        platform: currentPlatform,
        languageCode: languageCode,
      );

      emit(device);
      return device;
    } catch (e, st) {
      AppLogger.e(
        'syncCurrentDevice failed: $e',
        error: e,
        stackTrace: st,
        tag: 'UserDeviceCubit',
      );
      return null;
    }
  }

  /// Clears the current device token in Supabase when user logs out.
  Future<void> clearCurrentDevice() async {
    try {
      final token = await PushNotificationService.getToken();
      if (token != null && token.isNotEmpty) {
        await _repository.deleteByToken(token);
      }
      emit(null);
    } catch (e) {
      AppLogger.w(
        'clearCurrentDevice error: $e',
        tag: 'UserDeviceCubit',
      );
    }
  }

  /// Sets up a listener on token refreshes to keep Supabase updated automatically.
  void listenToTokenRefresh(
    String Function() getUserId, {
    String languageCode = 'en',
  }) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = PushNotificationService.onTokenRefresh.listen((
      newToken,
    ) async {
      final userId = getUserId();
      if (userId.isNotEmpty) {
        AppLogger.d(
          'New token emitted from FCM. Updating user_devices...',
          tag: 'UserDeviceCubit',
        );

        try {
          final device = await _repository.upsertDevice(
            token: newToken,
            platform: currentPlatform,
            languageCode: languageCode,
          );
          emit(device);
        } catch (e) {
          AppLogger.w(
            'Failed to update refreshed token: $e',
            tag: 'UserDeviceCubit',
          );
        }
      }
    });
  }

  /// Updates the push notification language of this device (its FCM token).
  Future<void> updateDeviceLanguage(String languageCode) async {
    try {
      final token = await PushNotificationService.getToken();
      if (token == null || token.isEmpty) return;

      final updated = await _repository.updateLanguage(
        token: token,
        languageCode: languageCode,
      );
      if (updated != null) {
        emit(updated);
        return;
      }

      final device = await _repository.upsertDevice(
        token: token,
        platform: currentPlatform,
        languageCode: languageCode,
      );
      emit(device);
    } catch (e) {
      AppLogger.w(
        'updateDeviceLanguage failed: $e',
        tag: 'UserDeviceCubit',
      );
    }
  }

  @override
  Future<void> close() {
    _tokenRefreshSubscription?.cancel();
    return super.close();
  }
}
