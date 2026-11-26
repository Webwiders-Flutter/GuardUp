import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/logger/app_logger.dart';
import '/core/state/api_state.dart';
import '/features/auth/data/enum/user_role.enum.dart';
import '../data/models/admin_settings.model.dart';
import '../data/repositories/admin_settings.repository.dart';

/// Cubit managing real-time platform configuration and registration fees.
class AdminSettingsCubit extends Cubit<ApiState<AdminSettingsModel>> {
  final AdminSettingsRepository _repository;
  StreamSubscription<AdminSettingsModel>? _subscription;

  AdminSettingsCubit(this._repository)
      : super(const ApiState.loading());

  /// Returns current [AdminSettingsModel] from state, or default fallback.
  AdminSettingsModel get settings =>
      state.dataOrNull ?? AdminSettingsModel.initial();

  /// Initializes the cubit by fetching initial settings and listening to Realtime updates.
  Future<void> init() async {
    try {
      final initial = await _repository.getSettings();
      emit(ApiState.success(initial));
    } catch (e, st) {
      AppLogger.w(
        'Failed to fetch initial admin settings: $e',
        error: e,
        stackTrace: st,
        tag: 'AdminSettingsCubit',
      );
      emit(ApiState.failure('Failed to load admin settings', error: e));
    }

    _subscribeToSettingsStream();
  }

  void _subscribeToSettingsStream() {
    _subscription?.cancel();
    _subscription = _repository.streamSettings().listen(
      (updatedSettings) {
        emit(ApiState.success(updatedSettings));
      },
      onError: (error, st) {
        AppLogger.w(
          'Error in admin settings realtime stream: $error',
          error: error,
          stackTrace: st,
          tag: 'AdminSettingsCubit',
        );
      },
    );
  }

  /// Returns the dynamic registration fee based on the user's role.
  /// Bodyguard (`GUARD`) -> `bodyguardFee`
  /// Company (`COMPANY`) -> `companyFee`
  double getRegistrationFee(UserRole? role) {
    if (role == UserRole.company) {
      return settings.companyFee;
    }
    return settings.bodyguardFee;
  }

  /// Manually refreshes admin settings from the database.
  Future<void> refresh() async {
    try {
      final fresh = await _repository.getSettings();
      emit(ApiState.success(fresh));
    } catch (e) {
      // Keep previous data on refresh failure
      emit(ApiState.failure('Failed to refresh admin settings',
          previousData: state.dataOrNull, error: e));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
