import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../firebase_options.dart';
import '/app/theme/colors/app_colors.dart';
import '/bootstrap/flavor.dart';
import '/core/config/config.dart';
import '/core/di/injection_container.dart';
import '/core/services/admin_settings/admin_settings.service.dart';
import '/core/services/notification/push_notification_service.dart';
import '/shared/functionalities/location-and-phone-code/services/phone_code_picker.services.dart';

Future<void> bootstrap({
  required Flavor flavor,
  required Widget Function() builder,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await dotenv.load();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase if credentials are provided in .env

  AppFlavor.setFlavor(flavor);
  AppEnvironment.init(flavor);
  await Future.wait([
    Supabase.initialize(
      url: AppEnvironment.config.baseUrl,
      publishableKey: AppEnvironment.config.apiKey,
    ),
    LocationPhoneCodeServices.init(),

    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
     PushNotificationService.init(),
  ]);
  
  await AdminSettingsService.instance.init();
  await initDependencies();


  runApp(builder());
}
