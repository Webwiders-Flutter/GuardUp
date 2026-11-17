import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/constants/app_local_storage_keys.dart';
import '/core/services/local_storage/storage.dart';

class ThemeController extends AsyncNotifier<ThemeMode> {
  final Storage _storage;

  ThemeController(this._storage);

  @override
  Future<ThemeMode> build() async {
    final theme = await _storage.read(AppLocalStorageKeys.themePreference);
    return switch (theme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      // Follow the OS setting when the user hasn't chosen a theme yet.
      _ => ThemeMode.system,
    };
  }

  Future<void> changeTheme(ThemeMode theme) async {
    state = AsyncData(theme);
    await _storage.write(
      key: AppLocalStorageKeys.themePreference,
      value: switch (theme) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
      },
    );
  }

  Future<void> setThemeMode(ThemeMode theme) => changeTheme(theme);

  Future<void> toggleTheme(BuildContext context) async {
    final Brightness platformBrightness = MediaQuery.platformBrightnessOf(
      context,
    );
    final current = state.value ?? ThemeMode.system;
    final bool isDarkCurrently = switch (current) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };

    final nextMode = isDarkCurrently ? ThemeMode.light : ThemeMode.dark;
    await changeTheme(nextMode);
  }

  bool get isDark => state.value == ThemeMode.dark;
  bool get isLight => state.value == ThemeMode.light;
  bool get isSystem => state.value == ThemeMode.system;
}
