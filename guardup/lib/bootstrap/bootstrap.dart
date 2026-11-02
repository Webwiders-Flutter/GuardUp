import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/app/theme/colors/app_colors.dart';
import '/bootstrap/flavor.dart';
import '/core/config/config.dart';
import '/core/di/injection_container.dart';
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
    await dotenv.load(fileName: '.env');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  AppEnvironment.init(flavor);

  // Initialize dependencies / service locator (sl)
  await initDependencies();

  LocationPhoneCodeServices.init();

  runApp(builder());
}
