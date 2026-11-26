import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '/features/settings/settings.dart';
import '/core/logger/app_logger.dart';
import '/core/services/app_update/app_update.service.dart';
import '/core/utils/validators.dart';

/// Cubit managing app-level gate checks (maintenance, force update, optional update)
/// powered directly by [AdminSettingsModel] as the single source of truth.
class AppGateCubit extends Cubit<AdminSettingsModel> {
  final AdminSettingsCubit _adminSettingsCubit;
  StreamSubscription? _settingsSub;

  String _currentVersion = '1.0.0';
  bool _isChecking = false;
  bool _optionalUpdateDismissed = false;

  AppGateCubit(this._adminSettingsCubit)
      : super(_adminSettingsCubit.settings);

  /// Installed application version (e.g. '1.0.0').
  String get currentVersion => _currentVersion;

  /// Whether a manual re-check or lifecycle verification is currently in-flight.
  bool get isChecking => _isChecking;

  /// Whether the host platform is iOS.
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Minimum mandatory version for the current platform.
  String get minimumVersion =>
      isIOS ? state.minimumIosVersion : state.minimumAndroidVersion;

  /// Latest available version for the current platform.
  String get latestVersion =>
      isIOS ? state.latestIosVersion : state.latestAndroidVersion;

  /// Update release notes / announcement message for the current platform.
  String? get updateMessage =>
      isIOS ? state.updateMessageIos : state.updateMessageAndroid;

  /// Official store URL for the current platform.
  String? get storeUrl => isIOS ? state.iosAppUrl : state.androidAppUrl;

  /// Whether platform maintenance mode is actively turned on.
  bool get isUnderMaintenance => state.isUnderMaintenance;

  /// Whether current app version is strictly lower than the minimum required version.
  bool get isForceUpdateRequired =>
      Validators.compareSemver(_currentVersion, minimumVersion) < 0;

  /// Whether a newer version is available in the store.
  bool get hasOptionalUpdate =>
      Validators.compareSemver(_currentVersion, latestVersion) < 0;

  /// Whether the optional update modal should be shown to the user.
  bool get shouldPromptOptionalUpdate =>
      !isUnderMaintenance &&
      !isForceUpdateRequired &&
      hasOptionalUpdate &&
      !_optionalUpdateDismissed;

  /// Initializes the cubit by reading the device's installed version
  /// and subscribing to [AdminSettingsCubit] updates.
  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _currentVersion = info.version;
    } catch (e, st) {
      AppLogger.w(
        'Failed to read platform package info: $e',
        error: e,
        stackTrace: st,
        tag: 'AppGateCubit',
      );
    }

    // Sync initial settings
    emit(_adminSettingsCubit.settings);

    // Reactively receive updates whenever AdminSettingsCubit emits fresh settings
    unawaited(_settingsSub?.cancel());
    _settingsSub = _adminSettingsCubit.stream.listen((apiState) {
      final settings = apiState.dataOrNull;
      if (settings != null) {
        // Reset dismissed flag when settings change (admin may have bumped the version)
        _optionalUpdateDismissed = false;
        emit(settings);
      }
    });
  }

  /// Refreshes admin settings from the server (e.g. on "Check Again" tap or AppLifecycleState.resumed).
  Future<void> checkAgain() async {
    _isChecking = true;
    // No emit needed — builder reads isChecking from the cubit instance.

    try {
      await _adminSettingsCubit.refresh();
      // The stream subscription above will emit the fresh settings.
    } finally {
      _isChecking = false;
    }
  }

  /// Triggers the platform update workflow (In-App Update or Store fallback).
  Future<bool> performUpdate({bool immediate = false}) async {
    return AppUpdateService.startUpdate(
      storeUrl: storeUrl,
      immediate: immediate,
    );
  }

  /// Dismisses the optional update dialog for this app session.
  void dismissOptionalUpdate() {
    _optionalUpdateDismissed = true;
  }

  @override
  Future<void> close() {
    _settingsSub?.cancel();
    return super.close();
  }
}
