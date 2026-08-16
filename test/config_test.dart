import 'package:flutter_test/flutter_test.dart';
import 'package:hepasense_mobile/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults to development environment', () {
      final config = AppConfig.fromDefines();
      expect(config.environment, AppEnvironment.development);
      expect(config.isDevelopment, isTrue);
      expect(config.isStaging, isFalse);
      expect(config.isProduction, isFalse);
    });

    test('parses staging environment', () {
      final config = AppConfig.fromDefines(appEnv: 'staging');
      expect(config.environment, AppEnvironment.staging);
      expect(config.isStaging, isTrue);
    });

    test('parses production environment', () {
      final config = AppConfig.fromDefines(appEnv: 'production');
      expect(config.environment, AppEnvironment.production);
      expect(config.isProduction, isTrue);
    });

    test('only development has an intentional default URL', () {
      final devConfig = AppConfig.fromDefines(appEnv: 'development');
      expect(devConfig.apiBaseUrl, contains('10.0.2.2'));

      final stagingConfig = AppConfig.fromDefines(appEnv: 'staging');
      expect(stagingConfig.apiBaseUrl, isEmpty);
      expect(stagingConfig.isApiConfigured, isFalse);

      final prodConfig = AppConfig.fromDefines(appEnv: 'production');
      expect(prodConfig.apiBaseUrl, isEmpty);
      expect(prodConfig.isApiConfigured, isFalse);
    });

    test('uses custom URL when provided', () {
      final config = AppConfig.fromDefines(
        appEnv: 'development',
        apiBaseUrl: 'http://custom:8080',
      );
      expect(config.apiBaseUrl, 'http://custom:8080');
    });

    test('never returns empty URL', () {
      final config = AppConfig.fromDefines();
      expect(config.apiBaseUrl.isNotEmpty, isTrue);
      expect(config.isApiConfigured, isTrue);
    });

    test('production accepts only an explicit deployment URL', () {
      final config = AppConfig.fromDefines(
        appEnv: 'production',
        apiBaseUrl: 'https://mobile-api.example.test',
      );
      expect(config.apiBaseUrl, 'https://mobile-api.example.test');
      expect(config.isApiConfigured, isTrue);
    });

    test('case insensitive environment parsing', () {
      final config = AppConfig.fromDefines(appEnv: 'STAGING');
      expect(config.environment, AppEnvironment.staging);
    });
  });
}
