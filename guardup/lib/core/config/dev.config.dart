import 'package:flutter_dotenv/flutter_dotenv.dart';

import '/core/constants/app_constants.dart';

import 'config.dart';

final class DevConfig implements AppConfig {
  @override
  String get appName => '${AppConstants.appName} (Dev)';

  @override
  String get supabaseUrl =>
      dotenv.maybeGet('DEV_SUPABASE_URL') ??
      dotenv.maybeGet('SUPABASE_URL') ??
      '';

  @override
  String get supabasePublishableKey =>
      dotenv.maybeGet('DEV_SUPABASE_PUBLISHABLE_KEY') ??
      dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY') ??
      '';

  @override
  String get baseUrl =>
      dotenv.maybeGet('DEV_BASE_URL') ??
      dotenv.maybeGet('BASE_URL') ??
      supabaseUrl;

  @override
  String get apiKey =>
      dotenv.maybeGet('DEV_X_API_KEY') ??
      dotenv.maybeGet('X_API_KEY') ??
      supabasePublishableKey;

  @override
  String get deepLinkScheme =>
      dotenv.maybeGet('DEEP_LINK_SCHEME') ?? 'transporthub-dev';

  @override
  bool get enableLogging =>
      dotenv.maybeGet('ENABLE_LOGGING')?.toLowerCase() == 'true' || true;
}
