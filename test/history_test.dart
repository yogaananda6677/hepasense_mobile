import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/errors/status_mapping.dart';
import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/patient/data/patient_providers.dart';
import 'package:hepasense_mobile/features/patient/domain/patient.dart';
import 'package:hepasense_mobile/features/patient/domain/patient_state.dart';
import 'package:hepasense_mobile/features/patient/presentation/controllers/patient_controller.dart';
import 'package:hepasense_mobile/features/screening/data/screening_providers.dart';
import 'package:hepasense_mobile/features/screening/data/screening_repository.dart';
import 'package:hepasense_mobile/features/screening/domain/history_state.dart';
import 'package:hepasense_mobile/features/screening/domain/screening.dart';
import 'package:hepasense_mobile/features/screening/presentation/controllers/history_controller.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/history_page.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockScreeningRepository extends Mock implements ScreeningRepository {}

class FixedPatientController extends PatientController {
  FixedPatientController(this.value);
  final PatientState value;
  @override
  PatientState build() => value;
  @override
  Future<void> load() async {}
}

class MutablePatientController extends PatientController {
  @override
  PatientState build() => const PatientLinked(patient);
  void unlink() => state = const PatientUnlinked();
  void linkAgain() => state = const PatientLinked(patient);
}

class FixedHistoryController extends HistoryController {
  FixedHistoryController(this.value);
  final HistoryState value;
  @override
  HistoryState build() => value;
  @override
  Future<void> loadInitial() async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> loadMore() async {}
  @override
  Future<void> setFilter(ScreenStatus? filter) async {}
}

const patient = Patient(
  id: 1,
  patientCode: 'HPS-0123456789ABCDEF',
  fullName: 'Pasien',
  dateOfBirth: null,
  sex: '',
  phone: '',
  address: '',
  status: 'active',
  userLinked: true,
  createdAt: '2026-08-13 08:00:00',
  updatedAt: '2026-08-13 08:00:00',
);

ScreeningSummary item(int id, ScreenStatus status, {bool valid = true}) =>
    ScreeningSummary(
      id: id,
      screeningUid: '11111111-2222-4333-8444-${id.toString().padLeft(12, '0')}',
      measuredAt: '2026-08-12 10:15:00',
      status: valid ? status : ScreenStatus.invalid,
      sampleValid: valid,
      nh3Corrected: '0.280000',
      nh3Unit: 'ppm',
    );

Map<String, dynamic> itemJson(int id, String status, {bool valid = true}) => {
  'id': id,
  'screening_uid': '11111111-2222-4333-8444-${id.toString().padLeft(12, '0')}',
  'measured_at': '2026-08-12 10:15:00',
  'status': valid ? status : 'invalid',
  'sample_valid': valid,
  'nh3_corrected': '0.280000',
  'nh3_unit': 'ppm',
};

void main() {
  group('History repository', () {
    test('parses DRF pagination envelope and compact rows', () {
      final page = ScreeningPage.fromJson({
        'count': 21,
        'next': 'https://api.test/api/v1/screenings/?page=2',
        'previous': null,
        'results': [itemJson(1, 'warning')],
      });
      expect(page.count, 21);
      expect(page.hasNext, isTrue);
      expect(page.results.single.status, ScreenStatus.warning);
      expect(page.results.single.nh3Value, 0.28);
    });

    test('history sends canonical page and supported filter', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(
        () => dio.get(any(), queryParameters: any(named: 'queryParameters')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/screenings/'),
          data: {'count': 0, 'next': null, 'previous': null, 'results': []},
        ),
      );
      await ScreeningRepository(
        api,
      ).history(page: 2, status: ScreenStatus.highRisk);
      verify(
        () => dio.get(
          '/api/v1/screenings/',
          queryParameters: {'page': 2, 'status': 'high_risk'},
        ),
      ).called(1);
    });

    test('invalid sample overrides any classification-like display', () {
      final parsed = ScreeningSummary.fromJson(
        itemJson(4, 'healthy', valid: false),
      );
      expect(parsed.status, ScreenStatus.invalid);
      expect(parsed.sampleValid, isFalse);
    });
  });

  group('HistoryController pagination', () {
    ProviderContainer container(MockScreeningRepository repository) {
      final result = ProviderContainer(
        overrides: [
          patientControllerProvider.overrideWith(
            () => FixedPatientController(const PatientLinked(patient)),
          ),
          screeningRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(result.dispose);
      return result;
    }

    test('first page success and empty history', () async {
      final repository = MockScreeningRepository();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => const ScreeningPage(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      final c = container(repository);
      await c.read(historyControllerProvider.notifier).loadInitial();
      expect(
        (c.read(historyControllerProvider) as HistoryLoaded).isEmpty,
        isTrue,
      );
    });

    test('page 2 appends without duplicate IDs', () async {
      final repository = MockScreeningRepository();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 3,
          next: 'page=2',
          previous: null,
          results: [
            item(1, ScreenStatus.healthy),
            item(2, ScreenStatus.warning),
          ],
        ),
      );
      when(() => repository.history(page: 2, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 3,
          next: null,
          previous: 'page=1',
          results: [
            item(2, ScreenStatus.warning),
            item(3, ScreenStatus.highRisk),
          ],
        ),
      );
      final c = container(repository);
      final controller = c.read(historyControllerProvider.notifier);
      await controller.loadInitial();
      await controller.loadMore();
      final state = c.read(historyControllerProvider) as HistoryLoaded;
      expect(state.items.map((e) => e.id), [1, 2, 3]);
      expect(state.hasNext, isFalse);
      await controller.loadMore();
      verify(() => repository.history(page: 2, status: null)).called(1);
    });

    test('duplicate load-more is prevented', () async {
      final repository = MockScreeningRepository();
      final pending = Completer<ScreeningPage>();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 2,
          next: 'page=2',
          previous: null,
          results: [item(1, ScreenStatus.healthy)],
        ),
      );
      when(
        () => repository.history(page: 2, status: null),
      ).thenAnswer((_) => pending.future);
      final c = container(repository);
      final controller = c.read(historyControllerProvider.notifier);
      await controller.loadInitial();
      final first = controller.loadMore();
      final second = controller.loadMore();
      pending.complete(
        ScreeningPage(
          count: 2,
          next: null,
          previous: 'page=1',
          results: [item(2, ScreenStatus.warning)],
        ),
      );
      await Future.wait([first, second]);
      verify(() => repository.history(page: 2, status: null)).called(1);
    });

    test('page-2 failure preserves page-1 and exposes retry', () async {
      final repository = MockScreeningRepository();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 2,
          next: 'page=2',
          previous: null,
          results: [item(1, ScreenStatus.healthy)],
        ),
      );
      when(() => repository.history(page: 2, status: null)).thenThrow(
        const ApiError(code: 'NETWORK', message: 'Jaringan bermasalah.'),
      );
      final c = container(repository);
      final controller = c.read(historyControllerProvider.notifier);
      await controller.loadInitial();
      await controller.loadMore();
      final state = c.read(historyControllerProvider) as HistoryLoaded;
      expect(state.items.single.id, 1);
      expect(state.nextPageError, 'Jaringan bermasalah.');
    });

    test('refresh replaces page 1 and resets pagination', () async {
      final repository = MockScreeningRepository();
      var calls = 0;
      when(() => repository.history(page: 1, status: null)).thenAnswer((
        _,
      ) async {
        calls++;
        return ScreeningPage(
          count: 1,
          next: null,
          previous: null,
          results: [item(calls, ScreenStatus.healthy)],
        );
      });
      final c = container(repository);
      final controller = c.read(historyControllerProvider.notifier);
      await controller.loadInitial();
      await controller.refresh();
      final state = c.read(historyControllerProvider) as HistoryLoaded;
      expect(state.items.single.id, 2);
      expect(state.page, 1);
    });

    test('logout/unlink clears loaded History state', () async {
      final repository = MockScreeningRepository();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 1,
          next: null,
          previous: null,
          results: [item(1, ScreenStatus.healthy)],
        ),
      );
      final c = ProviderContainer(
        overrides: [
          patientControllerProvider.overrideWith(MutablePatientController.new),
          screeningRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);
      await c.read(historyControllerProvider.notifier).loadInitial();
      expect(c.read(historyControllerProvider), isA<HistoryLoaded>());
      (c.read(patientControllerProvider.notifier) as MutablePatientController)
          .unlink();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(historyControllerProvider), isA<HistoryInitial>());
    });

    test('new account cannot inherit previous History state', () async {
      final repository = MockScreeningRepository();
      when(() => repository.history(page: 1, status: null)).thenAnswer(
        (_) async => ScreeningPage(
          count: 1,
          next: null,
          previous: null,
          results: [item(1, ScreenStatus.healthy)],
        ),
      );
      final c = ProviderContainer(
        overrides: [
          patientControllerProvider.overrideWith(MutablePatientController.new),
          screeningRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);
      await c.read(historyControllerProvider.notifier).loadInitial();
      final patientController =
          c.read(patientControllerProvider.notifier)
              as MutablePatientController;
      patientController.unlink();
      await Future<void>.delayed(Duration.zero);
      patientController.linkAgain();
      c.read(historyControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(historyControllerProvider), isA<HistoryInitial>());
    });
  });

  group('History widgets', () {
    Widget app(
      PatientState patientState,
      HistoryState historyState, {
      double textScale = 1,
    }) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        patientControllerProvider.overrideWith(
          () => FixedPatientController(patientState),
        ),
        historyControllerProvider.overrideWith(
          () => FixedHistoryController(historyState),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const HistoryPage(),
      ),
    );

    testWidgets('renders loading, empty, and initial error states', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const PatientLinked(patient), const HistoryLoading()),
      );
      expect(find.text('Memuat riwayat pemeriksaan...'), findsOneWidget);
      await tester.pumpWidget(
        app(
          const PatientLinked(patient),
          const HistoryLoaded(items: [], page: 1, hasNext: false),
        ),
      );
      await tester.pump();
      expect(find.text('Belum ada riwayat pemeriksaan'), findsOneWidget);
      await tester.pumpWidget(
        app(
          const PatientLinked(patient),
          const HistoryFailure('Tidak dapat terhubung.'),
        ),
      );
      await tester.pump();
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('renders healthy warning high-risk and invalid rows safely', (
      tester,
    ) async {
      final items = [
        item(1, ScreenStatus.healthy),
        item(2, ScreenStatus.warning),
        item(3, ScreenStatus.highRisk),
        item(4, ScreenStatus.invalid, valid: false),
      ];
      await tester.pumpWidget(
        app(
          const PatientLinked(patient),
          HistoryLoaded(items: items, page: 1, hasNext: false),
        ),
      );
      expect(find.text('Hasil Skrining Baik'), findsOneWidget);
      expect(find.text('Waspada'), findsWidgets);
      expect(find.text('Risiko Tinggi'), findsWidgets);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Pemeriksaan Tidak Valid'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('diagnosis'), findsNothing);
    });

    testWidgets('next-page error keeps rows and retry visible', (tester) async {
      await tester.pumpWidget(
        app(
          const PatientLinked(patient),
          HistoryLoaded(
            items: [item(1, ScreenStatus.healthy)],
            page: 1,
            hasNext: true,
            nextPageError: 'Gagal memuat halaman berikutnya.',
          ),
        ),
      );
      expect(find.text('Pemeriksaan HepaSense'), findsOneWidget);
      expect(find.text('Gagal memuat halaman berikutnya.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('unlinked Patient shows no history rows', (tester) async {
      await tester.pumpWidget(
        app(
          const PatientUnlinked(),
          HistoryLoaded(
            items: [item(1, ScreenStatus.healthy)],
            page: 1,
            hasNext: false,
          ),
        ),
      );
      expect(find.text('Data pasien belum tersedia'), findsOneWidget);
      expect(find.text('Pemeriksaan HepaSense'), findsNothing);
    });

    testWidgets('compact rows do not overflow at larger text scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const PatientLinked(patient),
          HistoryLoaded(
            items: [item(1, ScreenStatus.highRisk)],
            page: 1,
            hasNext: false,
          ),
          textScale: 1.5,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
