import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/errors/status_mapping.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hepasense_mobile/features/patient/data/patient_providers.dart';
import 'package:hepasense_mobile/features/patient/domain/patient.dart';
import 'package:hepasense_mobile/features/patient/domain/patient_state.dart';
import 'package:hepasense_mobile/features/patient/presentation/controllers/patient_controller.dart';
import 'package:hepasense_mobile/features/screening/data/report_platform_service.dart';
import 'package:hepasense_mobile/features/screening/data/screening_providers.dart';
import 'package:hepasense_mobile/features/screening/data/screening_repository.dart';
import 'package:hepasense_mobile/features/screening/domain/detail_state.dart';
import 'package:hepasense_mobile/features/screening/domain/report_state.dart';
import 'package:hepasense_mobile/features/screening/domain/screening.dart';
import 'package:hepasense_mobile/features/screening/presentation/controllers/detail_controller.dart';
import 'package:hepasense_mobile/features/screening/presentation/controllers/report_controller.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/detail_page.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockScreeningRepository extends Mock implements ScreeningRepository {}

class FakeReportPlatform implements ReportPlatformService {
  Uint8List? written;
  String? filename;
  String? opened;
  String? shared;

  @override
  Future<String> writeTemporaryPdf(Uint8List bytes, String filename) async {
    written = bytes;
    this.filename = filename;
    return '/temporary/$filename';
  }

  @override
  Future<void> openPdf(String path) async => opened = path;

  @override
  Future<void> sharePdf(String path) async => shared = path;
}

class FixedAuthController extends AuthController {
  @override
  AuthStatus build() => const Authenticated(user: null);
}

class FixedPatientController extends PatientController {
  @override
  PatientState build() => const PatientLinked(patient);
  @override
  Future<void> load() async {}
}

class FixedDetailController extends DetailController {
  @override
  DetailState build() => DetailLoaded(screening);
  @override
  Future<void> load(int id, {bool refresh = false}) async {}
}

class FixedReportController extends ReportController {
  bool emailCalled = false;
  @override
  ReportState build() => const ReportState();
  @override
  Future<void> email(int screeningId) async => emailCalled = true;
}

const patient = Patient(
  id: 1,
  patientCode: 'HPS-SYNTHETIC',
  fullName: 'Pasien Sintetis',
  dateOfBirth: null,
  sex: '',
  phone: '',
  address: '',
  status: 'active',
  userLinked: true,
  createdAt: '2026-08-13 08:00:00',
  updatedAt: '2026-08-13 08:00:00',
);

const screening = Screening(
  id: 15,
  screeningUid: '11111111-2222-4333-8444-555555555555',
  measuredAt: '2026-08-12 10:15:00',
  status: ScreenStatus.warning,
  sampleValid: true,
  measurement: ScreeningMeasurement(
    nh3Corrected: '0.28',
    nh3Unit: 'ppm',
    temperatureCelsius: '34.4',
    humidityPercent: '86.2',
    flowQuality: '0.91',
    expirationDurationSeconds: '5.3',
  ),
  result: ScreeningResult(classification: 'warning'),
);

void main() {
  group('report repository contract', () {
    late MockApiClient api;
    late MockDio dio;
    late ScreeningRepository repository;

    setUp(() {
      api = MockApiClient();
      dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      repository = ScreeningRepository(api);
    });

    test('downloads canonical PDF bytes and safe backend filename', () async {
      when(
        () => dio.get<List<int>>(
          '/api/v1/screenings/15/report/',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<List<int>>(
          requestOptions: RequestOptions(path: 'report'),
          data: const [37, 80, 68, 70],
          headers: Headers.fromMap({
            'content-disposition': [
              'attachment; filename="hepasense-hasil-skrining-20260812.pdf"',
            ],
          }),
        ),
      );
      final report = await repository.downloadReport(15);
      expect(report.bytes, Uint8List.fromList([37, 80, 68, 70]));
      expect(report.filename, 'hepasense-hasil-skrining-20260812.pdf');
    });

    test('email sends no arbitrary recipient field', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/screenings/15/email-report/',
          data: const <String, dynamic>{},
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: 'email'),
          data: const {'message': 'Terkirim.'},
        ),
      );
      expect(await repository.emailReport(15), 'Terkirim.');
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/api/v1/screenings/15/email-report/',
          data: const <String, dynamic>{},
        ),
      ).called(1);
    });
  });

  group('report controller', () {
    ProviderContainer container(
      MockScreeningRepository repository,
      FakeReportPlatform platform,
    ) {
      final value = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(FixedAuthController.new),
          screeningRepositoryProvider.overrideWithValue(repository),
          reportPlatformServiceProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(value.dispose);
      return value;
    }

    test(
      'open and share use backend PDF and temporary platform abstraction',
      () async {
        final repository = MockScreeningRepository();
        final platform = FakeReportPlatform();
        when(() => repository.downloadReport(15)).thenAnswer(
          (_) async => ScreeningReportDocument(
            bytes: Uint8List.fromList([37, 80, 68, 70]),
            filename: 'hepasense-hasil-skrining-20260812.pdf',
          ),
        );
        final value = container(repository, platform);
        await value.read(reportControllerProvider.notifier).open(15);
        expect(platform.opened, contains('/temporary/'));
        await value.read(reportControllerProvider.notifier).share(15);
        expect(platform.shared, contains('/temporary/'));
        expect(platform.filename, 'hepasense-hasil-skrining-20260812.pdf');
        verify(() => repository.downloadReport(15)).called(2);
      },
    );

    test('email success and download failures expose safe states', () async {
      final repository = MockScreeningRepository();
      final platform = FakeReportPlatform();
      when(
        () => repository.emailReport(15),
      ).thenAnswer((_) async => 'Terkirim.');
      when(
        () => repository.downloadReport(15),
      ).thenThrow(Exception('technical'));
      final value = container(repository, platform);
      await value.read(reportControllerProvider.notifier).email(15);
      expect(value.read(reportControllerProvider).message, 'Terkirim.');
      await value.read(reportControllerProvider.notifier).open(15);
      final failure = value.read(reportControllerProvider);
      expect(failure.isError, isTrue);
      expect(failure.message, isNot(contains('technical')));
    });
  });

  testWidgets('detail exposes actions and email confirmation only', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientControllerProvider.overrideWith(FixedPatientController.new),
          detailControllerProvider.overrideWith(FixedDetailController.new),
          reportControllerProvider.overrideWith(FixedReportController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DetailPage(screeningId: 15),
        ),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('report-email')), 300);
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text('Lihat / Unduh PDF'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);
    expect(find.text('Kirim ke Email'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const Key('report-email')));
    await tester.pumpAndSettle();
    expect(find.text('Kirim laporan?'), findsOneWidget);
    expect(find.textContaining('email yang terdaftar'), findsOneWidget);
  });
}
