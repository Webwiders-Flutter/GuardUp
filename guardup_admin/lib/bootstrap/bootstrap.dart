import 'package:guardup_admin/core/services/notification/push_notification_service.dart';
import 'package:guardup_admin/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/app/theme/colors/app_colors.dart';
import '/bootstrap/flavor.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '/core/config/config.dart';
import '/shared/widgets/location-and-phone-code/services/phone_code_picker.services.dart';

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
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.white,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  AppFlavor.setFlavor(flavor);
  AppEnvironment.init(flavor);
  await Future.wait([
    LocationPhoneCodeServices.init(),
    Supabase.initialize(
      url: AppEnvironment.config.baseUrl,
      publishableKey: AppEnvironment.config.apiKey,
    ),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);
  await PushNotificationService.init();
  runApp(
    ProviderScope(
      retry: (_, _) => null, //
      child: builder(),
    ),
  );
}
