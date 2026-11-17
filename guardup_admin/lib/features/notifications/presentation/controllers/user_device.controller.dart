import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/logger/app_logger.dart';
import '/core/services/notification/push_notification_service.dart';
import '/core/utils/callback/async_callback.handler.dart';
import '/features/notifications/data/models/user_device.model.dart';
import '/features/notifications/data/repositories/user_device.repository.dart';
import '/features/notifications/di/user_device.providers.dart';

/// Controller managing user device registration state and token synchronization.
class UserDeviceController extends AsyncNotifier<UserDeviceModel?> {
  UserDeviceRepository get _repository =>
      ref.read(userDeviceRepositoryProvider);

  @override
  FutureOr<UserDeviceModel?> build() async {
    return null;
  }

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
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final token = await PushNotificationService.getToken();
        if (token == null || token.isEmpty) {
          AppLogger.w(
            'syncCurrentDevice: FCM token is null or empty. Skipping registration.',
            tag: 'UserDeviceController',
          );
          return null;
        }

        final device = await _repository.upsertDevice(
          userId: userId,
          token: token,
          platform: currentPlatform,
          languageCode: languageCode,
        );

        return device;
      }),
    );

    state = result;

    if (result.hasError) {
      // final errorStr = result.error.toString();
      // if (errorStr.contains('23503') ||
      //     errorStr.contains('user_devices_user_id_fkey')) {
      //   AppLogger.w(
      //     'syncCurrentDevice: User profile not yet fully created in public.users. Ignoring foreign key error.',
      //     tag: 'UserDeviceController',
      //   );
      //   return null;
      // }
      throw result.error!;
    }
    return result.value;
  }

  /// clear the current device token in Supabase when user logs out.
  Future<void> clearCurrentDevice() async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => asyncHandler(() async {
        final token = await PushNotificationService.getToken();
        if (token != null && token.isNotEmpty) {
          await _repository.deleteByToken(token);
        }
        return null;
      }),
    );

    state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }

  /// Sets up a listener on token refreshes to keep Supabase updated automatically.
  void listenToTokenRefresh(
    String Function() getUserId, {
    String languageCode = 'en',
  }) {
    PushNotificationService.onTokenRefresh.listen((newToken) async {
      final userId = getUserId();
      if (userId.isNotEmpty) {
        AppLogger.i(
          'New token emitted from FCM. Updating user_devices...',
          tag: 'UserDeviceController',
        );

        await AsyncValue.guard(
          () => asyncHandler(() async {
            return await _repository.upsertDevice(
              userId: userId,
              token: newToken,
              platform: currentPlatform,
              languageCode: languageCode,
            );
          }),
        );
      }
    });
  }

  /// Updates the preferred notification language in Supabase for this device
  Future<void> updateDeviceLanguage(String languageCode) async {
    await AsyncValue.guard(
      () => asyncHandler(() async {
        final token = await PushNotificationService.getToken();
        if (token != null && token.isNotEmpty) {
          await _repository.updateLanguage(
            token: token,
            languageCode: languageCode,
          );
        }
        return null;
      }),
    );
  }
}
