import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guardup/core/logger/app_logger.dart';
import 'package:guardup/core/logger/supabase_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/app/theme/colors/app_colors.dart';
import '/bootstrap/flavor.dart';
import '/core/config/config.dart';
import '/core/di/injection_container.dart';
import '/core/services/admin_settings/admin_settings.service.dart';
import '/shared/functionalities/location-and-phone-code/services/phone_code_picker.services.dart';

Future<void> bootstrap({
  required Flavor flavor,
  required Widget Function() builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  AppFlavor.setFlavor(flavor);

  try {
    await dotenv.load(fileName: '.env.${flavor.name}');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      AppLogger.d('Could not load .env file: $e');
    }
  }

  // Initialize Supabase if credentials are provided in .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey =
      dotenv.env['SUPABASE_PUBLISH_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey != null &&
      supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      SupabaseLogger.success(
        'init',
        message: 'Supabase client initialized with url=$supabaseUrl',
      );
    } catch (e, st) {
      SupabaseLogger.error('init', e, st);
    }
  } else {
    SupabaseLogger.warning(
      'SUPABASE_URL or key missing in .env. Supabase client not initialized.',
    );
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  AppEnvironment.init(flavor);

  // Initialize dependencies / service locator (sl)
  await initDependencies();

  // Load platform admin settings once on app startup
  await AdminSettingsService.instance.init();

  LocationPhoneCodeServices.init();

  runApp(builder());
}
