import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/errors/status_mapping.dart';
import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/core/utils/jakarta_datetime.dart';
import 'package:hepasense_mobile/features/home/data/home_providers.dart';
import 'package:hepasense_mobile/features/home/domain/home_state.dart';
import 'package:hepasense_mobile/features/home/home_screen.dart';
import 'package:hepasense_mobile/features/home/presentation/controllers/home_controller.dart';
import 'package:hepasense_mobile/features/patient/data/patient_providers.dart';
import 'package:hepasense_mobile/features/patient/domain/patient.dart';
import 'package:hepasense_mobile/features/patient/domain/patient_state.dart';
import 'package:hepasense_mobile/features/patient/presentation/controllers/patient_controller.dart';
import 'package:hepasense_mobile/features/screening/data/screening_repository.dart';
import 'package:hepasense_mobile/features/screening/domain/screening.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class FixedPatientController extends PatientController {
  FixedPatientController(this.value);
  final PatientState value;
  @override
  PatientState build() => value;
  @override
  Future<void> load() async {}
}

class FixedHomeController extends HomeController {
  FixedHomeController(this.value);
  final HomeState value;
  @override
  HomeState build() => value;
  @override
  Future<void> load() async {}
}

const testPatient = Patient(
  id: 1,
  patientCode: 'HPS-0123456789ABCDEF',
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

Map<String, dynamic> screeningJson({
  String status = 'healthy',
  bool sampleValid = true,
  String? classification = 'healthy',
  String? confidence = '0.870000',
}) => {
  'id': 42,
  'screening_uid': '11111111-2222-4333-8444-555555555555',
  'measured_at': '2026-08-12 10:15:00',
  'status': status,
  'sample_valid': sampleValid,
  'measurement': {
    'nh3_corrected': '0.280000',
    'nh3_unit': 'ppm',
    'temperature_celsius': '34.400',
    'humidity_percent': '86.200',
    'flow_quality': '0.910000',
    'expiration_duration_seconds': '5.300',
  },
  'result': {'classification': classification, 'confidence_score': confidence},
};

void main() {
  group('Screening model and repository', () {
    test('latest success parses safe detail contract', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(() => dio.get('/api/v1/screenings/latest/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/screenings/latest/'),
          data: screeningJson(),
          statusCode: 200,
        ),
      );

      final result = await ScreeningRepository(api).latest();

      expect(result, isA<LatestAvailable>());
      expect(
        (result as LatestAvailable).screening.status,
        ScreenStatus.healthy,
      );
      verify(() => dio.get('/api/v1/screenings/latest/')).called(1);
    });

    test('latest endpoint 404 maps to no Screening', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(() => dio.get('/api/v1/screenings/latest/')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/screenings/latest/'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/screenings/latest/'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(await ScreeningRepository(api).latest(), isA<NoScreening>());
    });

    test('decimal strings parse explicitly and malformed values stay safe', () {
      final screening = Screening.fromJson(screeningJson());
      expect(screening.measurement.nh3Value, 0.28);
      final malformed = screeningJson();
      (malformed['measurement'] as Map<String, dynamic>)['nh3_corrected'] =
          'n/a';
      expect(Screening.fromJson(malformed).measurement.nh3Value, isNull);
    });

    test('invalid sample preserves nullable classification and confidence', () {
      final screening = Screening.fromJson(
        screeningJson(
          status: 'invalid',
          sampleValid: false,
          classification: null,
          confidence: null,
        ),
      );
      expect(screening.status, ScreenStatus.invalid);
      expect(screening.result.classification, isNull);
      expect(screening.result.confidenceValue, isNull);
    });

    test('all valid backend classifications map centrally', () {
      expect(Screening.fromJson(screeningJson()).status, ScreenStatus.healthy);
      expect(
        Screening.fromJson(
          screeningJson(status: 'warning', classification: 'warning'),
        ).status,
        ScreenStatus.warning,
      );
      expect(
        Screening.fromJson(
          screeningJson(status: 'high_risk', classification: 'high_risk'),
        ).status,
        ScreenStatus.highRisk,
      );
    });

    test('Jakarta timestamp is parsed as local wall time and labeled WIB', () {
      final parsed = JakartaDateTime.parse('2026-08-12 10:15:00');
      expect(parsed?.isUtc, isFalse);
      expect(parsed?.hour, 10);
      expect(
        JakartaDateTime.display('2026-08-12 10:15:00'),
        '12 Agu 2026, 10.15 WIB',
      );
    });

    test(
      'high risk and confidence copy never claims diagnosis/probability',
      () {
        final copy = StatusMapping.descriptionFor(
          ScreenStatus.highRisk,
        ).toLowerCase();
        expect(copy, contains('bukan diagnosis'));
        expect(copy, isNot(contains('menderita')));
        expect(copy, isNot(contains('kemungkinan penyakit')));
      },
    );
  });

  group('Home widgets', () {
    Widget app(PatientState patient, HomeState home) => ProviderScope(
      overrides: [
        patientControllerProvider.overrideWith(
          () => FixedPatientController(patient),
        ),
        homeControllerProvider.overrideWith(() => FixedHomeController(home)),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );

    testWidgets('linked Patient shows latest loading state', (tester) async {
      await tester.pumpWidget(
        app(const PatientLinked(testPatient), const HomeLoading()),
      );
      expect(find.text('Memuat hasil skrining terbaru...'), findsOneWidget);
    });

    testWidgets('latest result renders status, time, and safe disclaimer', (
      tester,
    ) async {
      final screening = Screening.fromJson(screeningJson());
      await tester.pumpWidget(
        app(const PatientLinked(testPatient), HomeLatest(screening)),
      );
      expect(find.text('Skrining Terbaru'), findsOneWidget);
      expect(find.text('Hasil Skrining Baik'), findsOneWidget);
      expect(find.text('12 Agu 2026, 10.15 WIB'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('bukan diagnosis medis'),
        200,
      );
      expect(find.textContaining('bukan diagnosis medis'), findsOneWidget);
      expect(find.textContaining('% kemungkinan'), findsNothing);
    });

    testWidgets('no Screening state is deliberate empty content', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const PatientLinked(testPatient), const HomeNoScreening()),
      );
      expect(find.text('Belum ada hasil skrining'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('invalid sample never renders classification interpretation', (
      tester,
    ) async {
      final screening = Screening.fromJson(
        screeningJson(
          status: 'invalid',
          sampleValid: false,
          classification: null,
          confidence: null,
        ),
      );
      await tester.pumpWidget(
        app(const PatientLinked(testPatient), HomeLatest(screening)),
      );
      expect(
        find.text('Sampel pemeriksaan belum dapat digunakan.'),
        findsOneWidget,
      );
      expect(find.text('Hasil Skrining Baik'), findsNothing);
      expect(find.text('Waspada'), findsNothing);
      expect(find.text('Risiko Tinggi'), findsNothing);
    });

    testWidgets('network failure displays retry', (tester) async {
      await tester.pumpWidget(
        app(
          const PatientLinked(testPatient),
          const HomeFailure('Tidak dapat terhubung ke server.'),
        ),
      );
      expect(find.text('Tidak dapat terhubung ke server.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('unlinked Patient never constructs Home screening state', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const PatientUnlinked(), const HomeNoScreening()),
      );
      expect(find.text('Akun belum terhubung'), findsOneWidget);
      expect(find.text('Skrining Terbaru'), findsNothing);
    });

    testWidgets('bottom navigation exposes only implemented destinations', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const PatientLinked(testPatient), const HomeNoScreening()),
      );
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Edukasi'), findsNothing);
    });
  });
}
