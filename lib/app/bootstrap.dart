import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/config/app_config_scope.dart';
import '../features/auth/data/auth_providers.dart';
import 'app.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();

  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  final config = AppConfig.fromDefines(
    appEnv: appEnv,
    apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : null,
  );

  runApp(
    AppConfigScope(
      config: config,
      child: ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(config)],
        child: const HepaSenseApp(),
      ),
    ),
  );
}
