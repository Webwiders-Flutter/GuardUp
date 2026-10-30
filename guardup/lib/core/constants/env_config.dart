import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:guardup/core/constants/app_assets.dart';

class EnvConfig {
  static String get appName => dotenv.get('APP_NAME', fallback: 'GuardUp');
  static String get apiUrl => dotenv.get('API_URL', fallback: '');
  static String get firebaseProjectId =>
      dotenv.get('FIREBASE_PROJECT_ID', fallback: '');
  static String get supabaseUrl {
    final val = dotenv.get('SUPABASE_URL', fallback: '');
    return val.trim().isNotEmpty ? val : 'https://guardup-demo.supabase.co';
  }

  static String get supabaseAnonKey {
    final val = dotenv.get('SUPABASE_ANON_KEY', fallback: '');
    return val.trim().isNotEmpty
        ? val
        : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.placeholder_anon_key';
  }
  static String get authCallbackUrl => dotenv.get(
    'AUTH_CALLBACK_URL',
    fallback: 'https://guardup.com/auth-callback',
  );
  static String get appDeepLinkBaseUrl =>
      dotenv.get('APP_DEEP_LINK_BASE_URL', fallback: 'https://guardup.com');

  static String get cloudflareR2BaseUrl => dotenv.get(
    'CLOUDFLARE_R2_BASE_URL',
    fallback: 'https://cdn.guardup.com',
  );

  static bool get isDebug =>
      dotenv.get('DEBUG_MODE', fallback: 'false').toLowerCase() == 'true';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: AppAssets.env);
    } catch (_) {
      // Fallback silently if .env is missing or invalid in development
    }
  }
}
