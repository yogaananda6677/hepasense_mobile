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
import 'package:hepasense_mobile/features/screening/domain/detail_state.dart';
import 'package:hepasense_mobile/features/screening/domain/screening.dart';
import 'package:hepasense_mobile/features/screening/presentation/controllers/detail_controller.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/detail_page.dart';

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

class FixedDetailController extends DetailController {
  FixedDetailController(this.value);
  final DetailState value;
  @override
  DetailState build() => value;
  @override
  Future<void> load(int id, {bool refresh = false}) async {}
}

const patient = Patient(
  id: 1,
  patientCode: 'HPS-1',
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

Map<String, dynamic> detailJson({
  String status = 'warning',
  bool valid = true,
  String? temperature = '34.400',
}) => {
  'id': 15,
  'screening_uid': '11111111-2222-4333-8444-555555555555',
  'measured_at': '2026-08-12 10:15:00',
  'status': valid ? status : 'invalid',
  'sample_valid': valid,
  'measurement': {
    'nh3_corrected': '0.280000',
    'nh3_unit': 'ppm',
    'temperature_celsius': temperature,
    'humidity_percent': '86.200',
    'flow_quality': '0.910000',
    'expiration_duration_seconds': '5.300',
    'raw_nh3': 'must-not-be-read',
    'device_credential': 'must-not-be-read',
  },
  'result': {'classification': valid ? status : null, 'confidence_score': null},
  'payload_digest': 'must-not-be-read',
};

Screening screening({String status = 'warning', bool valid = true}) =>
    Screening.fromJson(detailJson(status: status, valid: valid));

void main() {
  group('Screening detail mapping and repository', () {
    test('maps only patient-safe detail fields and nullable measurement', () {
      final parsed = Screening.fromJson(detailJson(temperature: null));
      expect(parsed.id, 15);
      expect(parsed.measurement.nh3Value, 0.28);
      expect(parsed.measurement.temperatureCelsius, isNull);
      expect(parsed.result.confidenceScore, isNull);
    });

    test(
      'invalid sample remains invalid without manufactured classification',
      () {
        final parsed = screening(valid: false);
        expect(parsed.status, ScreenStatus.invalid);
        expect(parsed.sampleValid, isFalse);
        expect(parsed.result.classification, isNull);
      },
    );

    test('uses canonical detail endpoint', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(() => dio.get('/api/v1/screenings/15/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/screenings/15/'),
          data: detailJson(),
        ),
      );
      final result = await ScreeningRepository(api).detail(15);
      expect(result, isA<ScreeningDetailAvailable>());
      verify(() => dio.get('/api/v1/screenings/15/')).called(1);
    });

    test('maps ownership-safe 404 to not found', () async {
      final api = MockApiClient();
      final dio = MockDio();
      when(() => api.dio).thenReturn(dio);
      when(() => dio.get(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/screenings/99/'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/screenings/99/'),
            statusCode: 404,
          ),
        ),
      );
      expect(
        await ScreeningRepository(api).detail(99),
        isA<ScreeningDetailNotFound>(),
      );
    });
  });

  group('DetailController', () {
    ProviderContainer container(MockScreeningRepository repository) {
      final value = ProviderContainer(
        overrides: [
          patientControllerProvider.overrideWith(
            () => FixedPatientController(const PatientLinked(patient)),
          ),
          screeningRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(value.dispose);
      return value;
    }

    test('loads success and prevents duplicate in-flight request', () async {
      final repository = MockScreeningRepository();
      when(
        () => repository.detail(15),
      ).thenAnswer((_) async => ScreeningDetailAvailable(screening()));
      final value = container(repository);
      final controller = value.read(detailControllerProvider.notifier);
      await Future.wait([controller.load(15), controller.load(15)]);
      expect(value.read(detailControllerProvider), isA<DetailLoaded>());
      verify(() => repository.detail(15)).called(1);
    });

    test('maps not found and API failures to explicit states', () async {
      final repository = MockScreeningRepository();
      when(
        () => repository.detail(15),
      ).thenAnswer((_) async => const ScreeningDetailNotFound());
      final value = container(repository);
      await value.read(detailControllerProvider.notifier).load(15);
      expect(value.read(detailControllerProvider), isA<DetailNotFound>());
      when(() => repository.detail(16)).thenThrow(
        const ApiError(code: 'NETWORK', message: 'Jaringan bermasalah.'),
      );
      await value.read(detailControllerProvider.notifier).load(16);
      expect(
        (value.read(detailControllerProvider) as DetailFailure).message,
        'Jaringan bermasalah.',
      );
    });
  });

  group('DetailPage', () {
    Future<void> pump(WidgetTester tester, DetailState state) async {
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            patientControllerProvider.overrideWith(
              () => FixedPatientController(const PatientLinked(patient)),
            ),
            detailControllerProvider.overrideWith(
              () => FixedDetailController(state),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const DetailPage(screeningId: 15),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders loading, missing, and retry states', (tester) async {
      await pump(tester, const DetailLoading());
      expect(find.text('Memuat detail pemeriksaan...'), findsOneWidget);
      await pump(tester, const DetailNotFound());
      expect(
        find.text(
          'Data pemeriksaan tidak ditemukan atau sudah tidak tersedia.',
        ),
        findsOneWidget,
      );
      await pump(tester, const DetailFailure('Jaringan bermasalah.'));
      expect(find.text('Jaringan bermasalah.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('renders safe measurements without confidence probability', (
      tester,
    ) async {
      await pump(tester, DetailLoaded(screening()));
      expect(find.text('Waspada'), findsWidgets);
      expect(find.text('0.28 ppm'), findsOneWidget);
      expect(find.text('34.4 °C'), findsOneWidget);
      expect(find.text('86.2 %'), findsOneWidget);
      expect(find.textContaining('probabilitas'), findsNothing);
      expect(find.textContaining('confidence'), findsNothing);
    });

    testWidgets('invalid result gives repeat guidance, not healthy copy', (
      tester,
    ) async {
      await pump(tester, DetailLoaded(screening(valid: false)));
      expect(find.text('Sampel pemeriksaan tidak valid'), findsOneWidget);
      expect(find.textContaining('Ulangi pemeriksaan'), findsOneWidget);
      expect(find.text('Hasil Skrining Baik'), findsNothing);
    });

    testWidgets('high risk remains screening-safe and non-diagnostic', (
      tester,
    ) async {
      await pump(tester, DetailLoaded(screening(status: 'high_risk')));
      expect(find.text('Risiko Tinggi'), findsWidgets);
      expect(find.textContaining('bukan diagnosis medis'), findsWidgets);
      expect(find.textContaining('penyakit terkonfirmasi'), findsNothing);
    });
  });
}
