import 'package:hepasense_mobile/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hepasense_mobile/core/config/app_config.dart';
import 'package:hepasense_mobile/features/auth/data/auth_providers.dart';

void main() {
  testWidgets('HepaSenseApp boots without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromDefines(apiBaseUrl: 'https://api.test'),
          ),
        ],
        child: const HepaSenseApp(),
      ),
    );
    expect(find.byType(HepaSenseApp), findsOneWidget);
  });
}
