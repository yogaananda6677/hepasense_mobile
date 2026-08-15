import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepasense_mobile/core/widgets/state_view.dart';
import 'package:hepasense_mobile/core/widgets/status_badge.dart';
import 'package:hepasense_mobile/core/errors/status_mapping.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';

Widget testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('StateView', () {
    testWidgets('shows loading indicator when state is loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const StateView(state: ViewState.loading)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows loading message when provided', (tester) async {
      await tester.pumpWidget(
        testApp(
          const StateView(
            state: ViewState.loading,
            loadingMessage: 'Memuat data...',
          ),
        ),
      );
      expect(find.text('Memuat data...'), findsOneWidget);
    });

    testWidgets('shows empty state with default text', (tester) async {
      await tester.pumpWidget(testApp(const StateView(state: ViewState.empty)));
      expect(find.text('Tidak ada data'), findsOneWidget);
    });

    testWidgets('shows empty state with custom text', (tester) async {
      await tester.pumpWidget(
        testApp(
          const StateView(
            state: ViewState.empty,
            emptyTitle: 'Kosong',
            emptyMessage: 'Tidak ada',
          ),
        ),
      );
      expect(find.text('Kosong'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      var retryTapped = false;
      await tester.pumpWidget(
        testApp(
          StateView(
            state: ViewState.error,
            errorMessage: 'Gagal memuat',
            onRetry: () => retryTapped = true,
          ),
        ),
      );
      expect(find.text('Gagal memuat'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      expect(retryTapped, isTrue);
    });

    testWidgets('shows child when state is success', (tester) async {
      await tester.pumpWidget(
        testApp(
          const StateView(state: ViewState.success, child: Text('Content')),
        ),
      );
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('renders healthy status with label', (tester) async {
      await tester.pumpWidget(
        testApp(const StatusBadge(status: ScreenStatus.healthy)),
      );
      expect(find.text('Hasil Skrining Baik'), findsOneWidget);
    });

    testWidgets('renders warning status with label', (tester) async {
      await tester.pumpWidget(
        testApp(const StatusBadge(status: ScreenStatus.warning)),
      );
      expect(find.text('Waspada'), findsOneWidget);
    });

    testWidgets('renders high risk status with label', (tester) async {
      await tester.pumpWidget(
        testApp(const StatusBadge(status: ScreenStatus.highRisk)),
      );
      expect(find.text('Risiko Tinggi'), findsOneWidget);
    });

    testWidgets('renders invalid status with label', (tester) async {
      await tester.pumpWidget(
        testApp(const StatusBadge(status: ScreenStatus.invalid)),
      );
      expect(find.text('Pemeriksaan Tidak Valid'), findsOneWidget);
    });
  });
}
