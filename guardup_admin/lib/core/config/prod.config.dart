import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/core/config/config.dart';

class ProdConfig implements AppConfig {
  @override
  String get appName => 'GuardUp Admin';

  @override
  String get baseUrl => dotenv.get('SUPABASE_URL');

  @override
  String get apiKey => dotenv.get('SUPABASE_PUBLISHABLE_KEY');

  @override
  String get firebaseVapidKey => dotenv.get('FIREBASE_VAPID_KEY');

  @override
  bool get enableLogging => false;
}
