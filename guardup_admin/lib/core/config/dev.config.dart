import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config.dart';

final class DevConfig implements AppConfig {
  @override
  String get appName => 'GuardUp Admin (Dev)';

  @override
  String get baseUrl => dotenv.get('DEV_SUPABASE_URL');

  @override
  String get apiKey => dotenv.get('DEV_SUPABASE_PUBLISHABLE_KEY');

  @override
  String get firebaseVapidKey => dotenv.get('FIREBASE_VAPID_KEY');

  @override
  bool get enableLogging => true;
}
