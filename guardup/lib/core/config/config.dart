import '/bootstrap/flavor.dart';
import '/core/config/dev.config.dart';
import '/core/config/prod.config.dart';
import '/core/config/staging.config.dart';

abstract class AppConfig {
  String get appName;
  String get baseUrl;
  String get apiKey;
  String get supabaseUrl;
  String get supabasePublishableKey;
  String get deepLinkScheme;
  bool get enableLogging;
  String get googlePlacesApiKey;
}

final class AppEnvironment {
  AppEnvironment._();

  static late final AppConfig config;

  static void init(Flavor flavor) {
    switch (flavor) {
      case Flavor.dev:
        config = DevConfig();
        break;
      case Flavor.staging:
        config = StagingConfig();
        break;
      case Flavor.prod:
        config = ProdConfig();
        break;
    }
  }
}
