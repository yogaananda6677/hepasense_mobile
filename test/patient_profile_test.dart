import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/storage/secure_keys.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hepasense_mobile/features/home/home_screen.dart';
import 'package:hepasense_mobile/features/patient/data/patient_providers.dart';
import 'package:hepasense_mobile/features/patient/data/patient_repository.dart';
import 'package:hepasense_mobile/features/patient/domain/patient.dart';
import 'package:hepasense_mobile/features/patient/domain/patient_state.dart';
import 'package:hepasense_mobile/features/patient/presentation/controllers/patient_controller.dart';
import 'package:hepasense_mobile/features/profile/data/profile_repository.dart';
import 'package:hepasense_mobile/features/profile/data/profile_providers.dart';
import 'package:hepasense_mobile/features/profile/domain/account_profile.dart';
import 'package:hepasense_mobile/features/profile/domain/profile_state.dart';
import 'package:hepasense_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/account_page.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockPatientRepository extends Mock implements PatientRepository {}

class MutableAuthController extends AuthController {
  @override
  AuthStatus build() => const Authenticated(user: null);

  void becomeUnauthenticated() => state = const AuthUnauthenticated();
  void becomeAuthenticated() => state = const Authenticated(user: null);
}

class FixedProfileController extends ProfileController {
  FixedProfileController(this.value);
  final ProfileState value;

  @override
  ProfileState build() => value;

  @override
  Future<void> load() async {}
}

class FixedPatientController extends PatientController {
  FixedPatientController(this.value);
  final PatientState value;

  @override
  PatientState build() => value;

  @override
  Future<void> load() async {}
}

const patient = Patient(
  id: 7,
  patientCode: 'HPS-0123456789ABCDEF',
  fullName: 'Pasien Sintetis',
  dateOfBirth: null,
  sex: '',
  phone: '',
  address: '',
  status: 'active',
  userLinked: true,
  createdAt: '2026-08-13 10:00:00',
  updatedAt: '2026-08-13 10:00:00',
);

Map<String, dynamic> get patientJson => {
  'id': patient.id,
  'patient_code': patient.patientCode,
  'full_name': patient.fullName,
  'date_of_birth': patient.dateOfBirth,
  'sex': patient.sex,
  'phone': patient.phone,
  'address': patient.address,
  'status': patient.status,
  'user_linked': patient.userLinked,
  'created_at': patient.createdAt,
  'updated_at': patient.updatedAt,
};

Map<String, dynamic> get profileJson => {
  'id': 1,
  'email': 'user@example.test',
  'first_name': 'Nama',
  'last_name': 'Pengguna',
  'full_name': 'Nama Pengguna',
  'phone_number': '+6200000000',
  'date_of_birth': null,
  'gender': null,
  'is_patient': true,
  'is_doctor': false,
  'two_factor_enabled': false,
};

void main() {
  late MockApiClient api;
  late MockDio dio;

  setUp(() {
    api = MockApiClient();
    dio = MockDio();
    when(() => api.dio).thenReturn(dio);
  });

  group('PatientRepository', () {
    test('200 resolves a linked Patient with exact safe fields', () async {
      when(() => dio.get('/api/v1/patients/me/')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
          statusCode: 200,
          data: patientJson,
        ),
      );

      final result = await PatientRepository(api).getMe();

      expect(result, isA<LinkedPatient>());
      expect(
        (result as LinkedPatient).patient.patientCode,
        patient.patientCode,
      );
      verify(() => dio.get('/api/v1/patients/me/')).called(1);
    });

    test(
      'endpoint-specific 404 resolves unlinked without another call',
      () async {
        when(() => dio.get('/api/v1/patients/me/')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
            response: Response(
              requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
              statusCode: 404,
              data: {'detail': 'No patient profile is linked.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(await PatientRepository(api).getMe(), isA<UnlinkedPatient>());
        verify(() => dio.get('/api/v1/patients/me/')).called(1);
        verifyNoMoreInteractions(dio);
      },
    );

    test('network error remains a retryable safe API error', () async {
      when(() => dio.get('/api/v1/patients/me/')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        PatientRepository(api).getMe(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });

    test('401 is not misclassified as an unlinked Patient', () async {
      when(() => dio.get('/api/v1/patients/me/')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/v1/patients/me/'),
            statusCode: 401,
            data: {'detail': 'Session expired.'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        PatientRepository(api).getMe(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Account profile contract', () {
    test('nullable account fields parse safely', () {
      final profile = AccountProfile.fromJson(profileJson);
      expect(profile.dateOfBirth, isNull);
      expect(profile.gender, isNull);
      expect(profile.email, 'user@example.test');
    });

    test('PATCH sends only approved mutable fields', () async {
      when(
        () => dio.patch('/api/v1/accounts/profile/', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/api/v1/accounts/profile/'),
          statusCode: 200,
          data: profileJson,
        ),
      );

      await ProfileRepository(api).updateProfile(
        const AccountProfileUpdate(
          firstName: 'Nama',
          lastName: 'Pengguna',
          phoneNumber: '+6200000000',
        ),
      );

      final captured =
          verify(
                () => dio.patch(
                  '/api/v1/accounts/profile/',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured.keys, {
        'first_name',
        'last_name',
        'phone_number',
        'date_of_birth',
        'gender',
      });
      expect(captured, isNot(contains('email')));
      expect(captured, isNot(contains('is_patient')));
      expect(captured, isNot(contains('two_factor_enabled')));
    });
  });

  group('Patient identity widgets', () {
    Widget app(PatientState state) => ProviderScope(
      overrides: [
        patientControllerProvider.overrideWith(
          () => FixedPatientController(state),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
    );

    testWidgets('resolving state blocks patient-dependent home', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PatientLoading()));
      expect(find.text('Memeriksa data pasien...'), findsOneWidget);
      expect(
        find.text('Data skrining akan tersedia pada tahap berikutnya.'),
        findsNothing,
      );
    });

    testWidgets('linked state renders patient area safely', (tester) async {
      await tester.pumpWidget(app(const PatientLinked(patient)));
      expect(find.text('Pasien Sintetis'), findsOneWidget);
      expect(find.textContaining('HPS-0123456789ABCDEF'), findsOneWidget);
    });

    testWidgets('unlinked state is safe, actionable, and has no claim action', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PatientUnlinked()));
      expect(find.text('Akun belum terhubung'), findsOneWidget);
      expect(
        find.textContaining('Hubungi petugas layanan HepaSense'),
        findsOneWidget,
      );
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.textContaining('Buat pasien'), findsNothing);
      expect(find.textContaining('Klaim'), findsNothing);
      expect(find.textContaining('kesalahan'), findsNothing);
    });

    testWidgets('failure shows safe retry control', (tester) async {
      await tester.pumpWidget(
        app(const PatientFailure('Periksa koneksi Anda.')),
      );
      expect(find.textContaining('Periksa koneksi Anda.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });
  });

  group('Session privacy', () {
    test(
      'in-flight Patient response cannot repopulate state after logout',
      () async {
        final repository = MockPatientRepository();
        final response = Completer<PatientResolution>();
        when(repository.getMe).thenAnswer((_) => response.future);
        final container = ProviderContainer(
          overrides: [
            authControllerProvider.overrideWith(MutableAuthController.new),
            patientRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        container.read(patientControllerProvider);
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(patientControllerProvider),
          isA<PatientLoading>(),
        );

        final auth =
            container.read(authControllerProvider.notifier)
                as MutableAuthController;
        auth.becomeUnauthenticated();
        response.complete(const LinkedPatient(patient));
        await Future<void>.delayed(Duration.zero);

        expect(
          container.read(patientControllerProvider),
          isA<PatientInitial>(),
        );
      },
    );

    test('logout/auth loss clears linked Patient state', () async {
      final repository = MockPatientRepository();
      when(
        repository.getMe,
      ).thenAnswer((_) async => const LinkedPatient(patient));
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(MutableAuthController.new),
          patientRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(patientControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(patientControllerProvider), isA<PatientLinked>());

      final auth =
          container.read(authControllerProvider.notifier)
              as MutableAuthController;
      auth.becomeUnauthenticated();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(patientControllerProvider), isA<PatientInitial>());
    });

    test('User B replaces User A Patient state after account switch', () async {
      const patientB = Patient(
        id: 8,
        patientCode: 'HPS-FEDCBA9876543210',
        fullName: 'Pasien B',
        dateOfBirth: null,
        sex: '',
        phone: '',
        address: '',
        status: 'active',
        userLinked: true,
        createdAt: '2026-08-13 11:00:00',
        updatedAt: '2026-08-13 11:00:00',
      );
      final repository = MockPatientRepository();
      var calls = 0;
      when(repository.getMe).thenAnswer((_) async {
        calls++;
        return calls == 1
            ? const LinkedPatient(patient)
            : const LinkedPatient(patientB);
      });
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(MutableAuthController.new),
          patientRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      container.read(patientControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        (container.read(patientControllerProvider) as PatientLinked).patient.id,
        7,
      );

      final auth =
          container.read(authControllerProvider.notifier)
              as MutableAuthController;
      auth.becomeUnauthenticated();
      await Future<void>.delayed(Duration.zero);
      auth.becomeAuthenticated();
      container.read(patientControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final linked = container.read(patientControllerProvider) as PatientLinked;
      expect(linked.patient.id, 8);
      expect(linked.patient.fullName, 'Pasien B');
    });

    test('Patient data has no persistent storage key', () {
      expect(SecureKeys.refreshToken, isNot(contains('patient')));
      expect(SecureKeys.fidHint, isNot(contains('patient')));
    });
  });

  testWidgets('account profile renders nullable fields safely', (tester) async {
    final profile = AccountProfile.fromJson(profileJson);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileControllerProvider.overrideWith(
            () => FixedProfileController(ProfileLoaded(profile)),
          ),
          patientControllerProvider.overrideWith(
            () => FixedPatientController(const PatientUnlinked()),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const AccountPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Nama Pengguna'), findsOneWidget);
    expect(find.text('user@example.test'), findsOneWidget);
    expect(find.text('Belum diisi'), findsOneWidget);
    expect(find.text('Belum terhubung'), findsOneWidget);
  });
}
