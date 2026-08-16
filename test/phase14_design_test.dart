import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepasense_mobile/core/theme/app_colors.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/core/theme/spacing.dart';
import 'package:hepasense_mobile/core/widgets/app_bottom_navigation.dart';
import 'package:hepasense_mobile/core/widgets/app_card.dart';

void main() {
  test('centralized Stitch-aligned theme loads', () {
    final theme = AppTheme.light;
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFF7FAF9));
    expect(AppRadius.xl, 20);
    expect(theme.textTheme.headlineMedium?.fontWeight, FontWeight.w700);
  });

  testWidgets('shared card provides reusable rounded surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AppCard(child: Text('Konten aman'))),
      ),
    );
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.text('Konten aman'), findsOneWidget);
  });

  testWidgets('bottom navigation structure and selected route are shared', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          bottomNavigationBar: AppBottomNavigation(selectedIndex: 1),
        ),
      ),
    );
    expect(find.byKey(const Key('shared-bottom-navigation')), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Gizi'), findsOneWidget);
    expect(find.text('Chat AI'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('shared mobile shell remains stable across target widths', (
    tester,
  ) async {
    for (final size in const [Size(360, 800), Size(390, 844), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SafeArea(
                child: AppCard(
                  child: Text('Hasil skrining bukan diagnosis medis.'),
                ),
              ),
              bottomNavigationBar: AppBottomNavigation(selectedIndex: 0),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.byType(AppBottomNavigation), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
  });

  test('core redesigned screens consume shared surfaces and navigation', () {
    final sources = [
      File('lib/features/home/home_screen.dart').readAsStringSync(),
      File(
        'lib/features/screening/presentation/pages/history_page.dart',
      ).readAsStringSync(),
      File(
        'lib/features/screening/presentation/pages/detail_page.dart',
      ).readAsStringSync(),
      File(
        'lib/features/education/presentation/pages/education_page.dart',
      ).readAsStringSync(),
      File(
        'lib/features/profile/presentation/pages/account_page.dart',
      ).readAsStringSync(),
    ];
    for (final source in sources) {
      expect(source, contains('AppCard'));
    }
    expect(sources[0], contains('AppBottomNavigation'));
    expect(sources[1], contains('AppBottomNavigation'));
    expect(sources[4], contains('AppBottomNavigation'));
  });

  test('medical semantics and Phase 13 unlinked behavior remain explicit', () {
    final home = File('lib/features/home/home_screen.dart').readAsStringSync();
    final detail = File(
      'lib/features/screening/presentation/pages/detail_page.dart',
    ).readAsStringSync();
    expect(home, contains('Akun belum terhubung'));
    expect(home, contains("text: 'Coba Lagi'"));
    expect(detail, contains('skrining awal, bukan diagnosis medis'));
    expect(detail, isNot(contains('probabilitas penyakit')));
  });

  test('all auth screens retain behavior while sharing the design surface', () {
    for (final path in [
      'lib/features/auth/presentation/pages/login_page.dart',
      'lib/features/auth/presentation/pages/register_page.dart',
      'lib/features/auth/presentation/pages/mfa_page.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('AppCard'));
      expect(source, contains('authControllerProvider.notifier'));
    }
    final splash = File(
      'lib/features/auth/presentation/pages/splash_page.dart',
    ).readAsStringSync();
    expect(splash, contains('AppCard'));
    expect(splash, contains('restoreSession()'));
  });

  test('production UI contains no borrowed Nara business labels', () {
    final forbidden = RegExp(
      r'\b(Nara|wallet|balance|transfer|top-up|budget|expense|saving goal)\b',
      caseSensitive: false,
    );
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(matches(forbidden)),
        reason: file.path,
      );
    }
  });
}
