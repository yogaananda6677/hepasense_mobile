import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepasense_mobile/core/theme/app_colors.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/core/widgets/app_bottom_navigation.dart';

void main() {
  test('final HepaSense mint and teal color tokens are canonical', () {
    expect(AppColors.primary, const Color(0xFF00685D));
    expect(AppColors.primaryDark, const Color(0xFF00574E));
    expect(AppColors.primarySoft, const Color(0xFFDDF3EF));
    expect(AppColors.accent, const Color(0xFF2D8C83));
    expect(AppColors.background, const Color(0xFFF7FAF9));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.infoSurface, const Color(0xFFE9F6FD));
    expect(AppColors.navigationBackground, const Color(0xFFF5FBFA));
    expect(AppColors.navigationActive, const Color(0xFFCFE9E5));
    expect(AppColors.onSurface, const Color(0xFF1D2926));
    expect(AppColors.onSurfaceVariant, const Color(0xFF61706C));
    expect(AppColors.statusHealthySurface, const Color(0xFFE8F5E9));
    expect(AppColors.statusHealthy, const Color(0xFF2E7D32));
    expect(AppColors.statusWarningSurface, const Color(0xFFFFF4D6));
    expect(AppColors.statusWarning, const Color(0xFF9A6700));
    expect(AppColors.statusHighRiskSurface, const Color(0xFFFDEBEC));
    expect(AppColors.statusHighRisk, const Color(0xFFB42318));
    expect(AppColors.statusInvalidSurface, const Color(0xFFEEF2F4));
    expect(AppColors.statusInvalid, const Color(0xFF5E6A71));
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.background);
    expect(
      AppTheme.light.navigationBarTheme.indicatorColor,
      AppColors.navigationActive,
    );
  });

  test('primary production token no longer uses rejected blue', () {
    final colors = File('lib/core/theme/app_colors.dart').readAsStringSync();
    expect(colors, isNot(contains('0xFF007BFF')));
  });

  test('primary destinations use immediate route pages', () {
    final router = File('lib/app/router/app_router.dart').readAsStringSync();
    for (final page in [
      'HomeScreen',
      'HistoryPage',
      'EducationPageView',
      'AiAssistantPage',
      'AccountPage',
    ]) {
      expect(router, contains('NoTransitionPage'));
      expect(router, contains(page));
    }
    expect(router, isNot(contains('SlideTransition')));
  });

  testWidgets('functional navigation includes enabled Chat AI entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          bottomNavigationBar: AppBottomNavigation(selectedIndex: 2),
        ),
      ),
    );
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Gizi'), findsOneWidget);
    expect(find.text('Chat AI'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  test('Home source keeps compact safe hierarchy without fabricated data', () {
    final source = File(
      'lib/features/home/home_screen.dart',
    ).readAsStringSync();
    for (final label in [
      'Kesehatan Anda Hari Ini',
      'Hasil Pemeriksaan Terakhir',
      'Kesimpulan',
      'Lihat Riwayat Lengkap',
      'Tips Kesehatan',
    ]) {
      expect(source, contains(label));
    }
    expect(source, contains('Belum ada hasil skrining'));
    expect(source, contains('bukan diagnosis medis'));
    expect(source, isNot(contains('confidenceScore')));
  });

  test('production UI has no template or finance branding contamination', () {
    final forbidden = RegExp(
      r'\b(HaloSehat|Protokol Sehat|Nara|wallet|balance|expense|transfer|finance)\b',
      caseSensitive: false,
    );
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      expect(
        file.readAsStringSync(),
        isNot(matches(forbidden)),
        reason: file.path,
      );
    }
  });

  testWidgets('navigation stays stable at target sizes and text scales', (
    tester,
  ) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      for (final scale in const [1.0, 1.3]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Scaffold(
                body: Text('HepaSense'),
                bottomNavigationBar: AppBottomNavigation(selectedIndex: 0),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$size @ $scale');
      }
    }
    await tester.binding.setSurfaceSize(null);
  });
}
