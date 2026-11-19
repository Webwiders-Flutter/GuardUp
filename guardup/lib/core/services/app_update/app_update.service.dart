import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '/core/logger/app_logger.dart';
import '/core/services/launcher/app_launcher.service.dart';

/// Service responsible for managing Google Play In-App Updates and platform store fallbacks.
final class AppUpdateService {
  AppUpdateService._();

  /// Whether Google Play in-app update is potentially supported on current device.
  static bool get isPlayStoreSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks if Google Play in-app update is available.
  /// Returns `null` on unsupported platforms (iOS, Web) or if the check fails.
  static Future<AppUpdateInfo?> checkForInAppUpdate() async {
    if (!isPlayStoreSupported) return null;

    try {
      final info = await InAppUpdate.checkForUpdate();
      AppLogger.i(
        'InAppUpdate check: availability=${info.updateAvailability}, '
        'immediateAllowed=${info.immediateUpdateAllowed}, '
        'flexibleAllowed=${info.flexibleUpdateAllowed}',
        tag: 'AppUpdateService',
      );
      return info;
    } catch (e, st) {
      AppLogger.w(
        'InAppUpdate.checkForUpdate failed (likely non-PlayStore or debug build): $e',
        error: e,
        stackTrace: st,
        tag: 'AppUpdateService',
      );
      return null;
    }
  }

  /// Triggers update flow.
  ///
  /// On Android:
  /// - Tries Google Play Immediate Update if [immediate] is `true` and allowed.
  /// - Tries Google Play Flexible Update if [immediate] is `false` and allowed.
  /// - If in-app update is unavailable or fails, launches [storeUrl].
  ///
  /// On iOS / Web:
  /// - Launches [storeUrl].
  static Future<bool> startUpdate({
    required String? storeUrl,
    bool immediate = false,
  }) async {
    if (isPlayStoreSupported) {
      try {
        final updateInfo = await checkForInAppUpdate();
        if (updateInfo != null &&
            updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          if (immediate && updateInfo.immediateUpdateAllowed) {
            final result = await InAppUpdate.performImmediateUpdate();
            return result == AppUpdateResult.success;
          } else if (!immediate && updateInfo.flexibleUpdateAllowed) {
            final result = await InAppUpdate.startFlexibleUpdate();
            if (result == AppUpdateResult.success) {
              await InAppUpdate.completeFlexibleUpdate();
              return true;
            }
          }
        }
      } catch (e, st) {
        AppLogger.w(
          'In-app update failed, falling back to store URL: $e',
          error: e,
          stackTrace: st,
          tag: 'AppUpdateService',
        );
      }
    }

    // Fallback to opening store URL (Google Play / App Store)
    if (storeUrl != null && storeUrl.isNotEmpty) {
      return await AppLauncher.openWebsite(storeUrl);
    }

    return false;
  }
}
