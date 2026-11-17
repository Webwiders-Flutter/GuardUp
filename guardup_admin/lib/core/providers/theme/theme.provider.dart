import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/core/services/local_storage/local_storage.service.dart';
import '/core/services/local_storage/storage.dart';
import 'theme.controller.dart';

final localStorageProvider = Provider<Storage>(
  (ref) => PrefsStorageService.instance,
);

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(
      () => ThemeController(PrefsStorageService.instance),
    );
