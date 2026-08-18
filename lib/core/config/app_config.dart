enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;
  final String apiBaseUrl;

  static const String _defaultDevelopmentUrl = 'http://192.168.1.10:8081';

  factory AppConfig.fromDefines({String? appEnv, String? apiBaseUrl}) {
    final env = _parseEnvironment(appEnv);
    final url = apiBaseUrl ?? _defaultUrlForEnvironment(env);
    return AppConfig(environment: env, apiBaseUrl: url);
  }

  static AppEnvironment _parseEnvironment(String? value) {
    switch (value?.toLowerCase()) {
      case 'staging':
        return AppEnvironment.staging;
      case 'production':
        return AppEnvironment.production;
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  static String _defaultUrlForEnvironment(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return _defaultDevelopmentUrl;
      case AppEnvironment.staging:
        return '';
      case AppEnvironment.production:
        return '';
    }
  }

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;
  bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
