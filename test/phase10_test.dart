import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hepasense_mobile/core/network/api_client.dart';
import 'package:hepasense_mobile/core/network/api_error.dart';
import 'package:hepasense_mobile/core/theme/app_theme.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hepasense_mobile/features/education/data/education_providers.dart';
import 'package:hepasense_mobile/features/education/domain/education_content.dart';
import 'package:hepasense_mobile/features/education/domain/education_state.dart';
import 'package:hepasense_mobile/features/education/presentation/controllers/education_controller.dart';
import 'package:hepasense_mobile/features/patient/data/patient_providers.dart';
import 'package:hepasense_mobile/features/patient/domain/patient.dart';
import 'package:hepasense_mobile/features/patient/domain/patient_state.dart';
import 'package:hepasense_mobile/features/patient/presentation/controllers/patient_controller.dart';
import 'package:hepasense_mobile/features/profile/data/password_repository.dart';
import 'package:hepasense_mobile/features/profile/data/profile_providers.dart';
import 'package:hepasense_mobile/features/profile/domain/account_profile.dart';
import 'package:hepasense_mobile/features/profile/domain/password_change_state.dart';
import 'package:hepasense_mobile/features/profile/domain/profile_state.dart';
import 'package:hepasense_mobile/features/profile/presentation/controllers/password_change_controller.dart';
import 'package:hepasense_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/about_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/account_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/help_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/privacy_page.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockDio extends Mock implements Dio {}

class MockPasswordRepository extends Mock implements PasswordRepository {}

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

class FixedHelpController extends HelpController {
  FixedHelpController(this.value);
  final EducationState value;
  @override
  EducationState build() => value;
  @override
  Future<void> load() async {}
  @override
  Future<void> loadMore() async {}
}

class TestAuthController extends AuthController {
  bool invalidated = false;
  @override
  AuthStatus build() => const Authenticated(user: null);
  @override
  Future<void> invalidateSession() async {
    invalidated = true;
    state = const AuthUnauthenticated();
  }
}

class FixedPasswordController extends PasswordChangeController {
  FixedPasswordController(this.value, {this.result = false});
  final PasswordChangeState value;
  final bool result;
  int submits = 0;
  @override
  PasswordChangeState build() => value;
  @override
  Future<bool> submit({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    submits++;
    return result;
  }
}

class SuccessfulPasswordController extends PasswordChangeController {
  @override
  PasswordChangeState build() => const PasswordChangeIdle();
  @override
  Future<bool> submit({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    state = const PasswordChangeSuccess('Password berhasil diubah.');
    return true;
  }
}

const profile = AccountProfile(
  id: 1,
  email: 'patient@example.test',
  firstName: 'Nama',
  lastName: 'Pasien',
  fullName: 'Nama Pasien',
  phoneNumber: '+6200000000',
  isPatient: true,
  isDoctor: false,
  twoFactorEnabled: false,
);

const patient = Patient(
  id: 7,
  patientCode: 'HPS-0123456789ABCDEF',
  fullName: 'Nama Pasien',
  dateOfBirth: null,
  sex: '',
  phone: '',
  address: '',
  status: 'active',
  userLinked: true,
  createdAt: '2026-08-13 10:00:00',
  updatedAt: '2026-08-13 10:00:00',
);

EducationArticle helpArticle() => EducationArticle(
  id: 3,
  type: 'help',
  title: 'Cara melihat hasil pemeriksaan',
  slug: 'cara-melihat-hasil',
  summary: 'Panduan penggunaan aplikasi.',
  thumbnail: null,
  isFeatured: false,
  readTimeMinutes: 2,
  publishedAt: '2026-08-12 09:00:00',
  category: null,
);

void main() {
  group('Password change contract', () {
    late MockApiClient api;
    late MockDio dio;

    setUp(() {
      api = MockApiClient();
      dio = MockDio();
      when(() => api.dio).thenReturn(dio);
    });

    test(
      'posts exact frozen request fields and returns success message',
      () async {
        when(() => dio.post(any(), data: any(named: 'data'))).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: 'password'),
            data: {'message': 'Password berhasil diubah. Silakan login ulang.'},
          ),
        );
        final message = await PasswordRepository(api).change(
          oldPassword: 'OldStrong!234',
          newPassword: 'NewStrong!234',
          newPasswordConfirm: 'NewStrong!234',
        );
        final captured =
            verify(
                  () => dio.post(
                    '/api/v1/accounts/change-password/',
                    data: captureAny(named: 'data'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured.keys, {
          'old_password',
          'new_password',
          'new_password_confirm',
        });
        expect(message, contains('login ulang'));
      },
    );

    test('incorrect password and validation errors map safely', () async {
      when(() => dio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'password'),
          response: Response(
            requestOptions: RequestOptions(path: 'password'),
            statusCode: 400,
            data: {
              'errors': {
                'old_password': ['Password lama salah.'],
              },
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      await expectLater(
        PasswordRepository(api).change(
          oldPassword: 'wrong',
          newPassword: 'NewStrong!234',
          newPasswordConfirm: 'NewStrong!234',
        ),
        throwsA(
          isA<ApiError>().having(
            (error) => error.message,
            'message',
            'Password lama salah.',
          ),
        ),
      );
    });

    test('network errors remain safe and do not expose DioException', () async {
      when(() => dio.post(any(), data: any(named: 'data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'password'),
          type: DioExceptionType.connectionError,
        ),
      );
      await expectLater(
        PasswordRepository(api).change(
          oldPassword: 'old',
          newPassword: 'new',
          newPasswordConfirm: 'new',
        ),
        throwsA(
          isA<ApiError>().having(
            (error) => error.message,
            'message',
            isNot(contains('DioException')),
          ),
        ),
      );
    });
  });

  group('PasswordChangeController', () {
    test(
      'success clears authenticated session after feedback interval',
      () async {
        final repository = MockPasswordRepository();
        when(
          () => repository.change(
            oldPassword: any(named: 'oldPassword'),
            newPassword: any(named: 'newPassword'),
            newPasswordConfirm: any(named: 'newPasswordConfirm'),
          ),
        ).thenAnswer((_) async => 'Password berhasil diubah.');
        final container = ProviderContainer(
          overrides: [
            passwordRepositoryProvider.overrideWithValue(repository),
            authControllerProvider.overrideWith(TestAuthController.new),
          ],
        );
        addTearDown(container.dispose);
        final future = container
            .read(passwordChangeControllerProvider.notifier)
            .submit(
              oldPassword: 'OldStrong!234',
              newPassword: 'NewStrong!234',
              newPasswordConfirm: 'NewStrong!234',
            );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(passwordChangeControllerProvider),
          isA<PasswordChangeSuccess>(),
        );
        await future;
        expect(
          container.read(authControllerProvider),
          isA<AuthUnauthenticated>(),
        );
      },
    );

    test('duplicate submit is prevented while request is pending', () async {
      final repository = MockPasswordRepository();
      final completer = Completer<String>();
      when(
        () => repository.change(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
          newPasswordConfirm: any(named: 'newPasswordConfirm'),
        ),
      ).thenAnswer((_) => completer.future);
      final container = ProviderContainer(
        overrides: [
          passwordRepositoryProvider.overrideWithValue(repository),
          authControllerProvider.overrideWith(TestAuthController.new),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        passwordChangeControllerProvider.notifier,
      );
      final first = controller.submit(
        oldPassword: 'old',
        newPassword: 'new',
        newPasswordConfirm: 'new',
      );
      expect(
        await controller.submit(
          oldPassword: 'old',
          newPassword: 'new',
          newPasswordConfirm: 'new',
        ),
        isFalse,
      );
      verify(
        () => repository.change(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
          newPasswordConfirm: any(named: 'newPasswordConfirm'),
        ),
      ).called(1);
      completer.complete('Berhasil');
      await first;
    });

    test('ordinary failure does not change authenticated state', () async {
      final repository = MockPasswordRepository();
      when(
        () => repository.change(
          oldPassword: any(named: 'oldPassword'),
          newPassword: any(named: 'newPassword'),
          newPasswordConfirm: any(named: 'newPasswordConfirm'),
        ),
      ).thenThrow(const ApiError(code: 'NETWORK', message: 'Jaringan gagal.'));
      final container = ProviderContainer(
        overrides: [
          passwordRepositoryProvider.overrideWithValue(repository),
          authControllerProvider.overrideWith(TestAuthController.new),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(passwordChangeControllerProvider.notifier)
          .submit(
            oldPassword: 'old',
            newPassword: 'new',
            newPasswordConfirm: 'new',
          );
      expect(container.read(authControllerProvider), isA<Authenticated>());
      expect(
        container.read(passwordChangeControllerProvider),
        isA<PasswordChangeFailure>(),
      );
    });
  });

  group('Account and support UI', () {
    Widget accountApp(
      PatientState patientState, {
      Size size = const Size(390, 844),
    }) => ProviderScope(
      overrides: [
        profileControllerProvider.overrideWith(
          () => FixedProfileController(const ProfileLoaded(profile)),
        ),
        patientControllerProvider.overrideWith(
          () => FixedPatientController(patientState),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(theme: AppTheme.light, home: const AccountPage()),
      ),
    );

    testWidgets(
      'linked account uses existing profile and selected Account nav',
      (tester) async {
        await tester.pumpWidget(accountApp(const PatientLinked(patient)));
        await tester.pump();
        expect(find.text('Nama Pasien'), findsOneWidget);
        expect(find.text('Data pasien terhubung'), findsOneWidget);
        expect(find.text('Ubah biodata'), findsNothing);
        expect(find.text('Biodata'), findsOneWidget);
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          4,
        );
      },
    );

    testWidgets(
      'unlinked account remains safe and general settings accessible',
      (tester) async {
        await tester.pumpWidget(accountApp(const PatientUnlinked()));
        await tester.pump();
        expect(find.text('Belum terhubung'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Ubah Password'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Ubah Password'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Bantuan'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Bantuan'), findsOneWidget);
      },
    );

    testWidgets('unsupported Figma settings and identifiers are absent', (
      tester,
    ) async {
      await tester.pumpWidget(accountApp(const PatientLinked(patient)));
      await tester.pump();
      for (final value in [
        'Premium Member',
        'My Plants',
        'Garden Management',
        'Download Reports',
        'Language',
        'Notification Settings',
        patient.patientCode,
      ]) {
        expect(find.textContaining(value), findsNothing);
      }
    });

    testWidgets('account layout handles 360 width and larger text', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileControllerProvider.overrideWith(
              () => FixedProfileController(const ProfileLoaded(profile)),
            ),
            patientControllerProvider.overrideWith(
              () => FixedPatientController(const PatientUnlinked()),
            ),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              theme: AppTheme.light,
              home: const AccountPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('password form catches confirmation mismatch client-side', (
      tester,
    ) async {
      final controller = FixedPasswordController(const PasswordChangeIdle());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordChangeControllerProvider.overrideWith(() => controller),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChangePasswordPage(),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'OldStrong!234');
      await tester.enterText(find.byType(TextFormField).at(1), 'NewStrong!234');
      await tester.enterText(find.byType(TextFormField).at(2), 'Different!234');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('Konfirmasi password tidak cocok.'), findsOneWidget);
      expect(controller.submits, 0);
      expect(find.byTooltip('Tampilkan password'), findsNWidgets(3));
    });

    testWidgets('password submitting state disables duplicate action', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordChangeControllerProvider.overrideWith(
              () => FixedPasswordController(const PasswordChangeSubmitting()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChangePasswordPage(),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
    });

    testWidgets('password controllers are cleared after success', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            passwordChangeControllerProvider.overrideWith(
              SuccessfulPasswordController.new,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ChangePasswordPage(),
          ),
        ),
      );
      for (var index = 0; index < 3; index++) {
        await tester.enterText(
          find.byType(TextFormField).at(index),
          index == 0 ? 'OldStrong!234' : 'NewStrong!234',
        );
      }
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.controller?.text, isEmpty);
      }
    });

    testWidgets('privacy is conservative and contains no sensitive result', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));
      expect(find.text('Informasi kesehatan'), findsOneWidget);
      expect(find.textContaining('bukan pengganti diagnosis'), findsOneWidget);
      for (final value in ['HIPAA', 'GDPR', 'ISO 27001', 'nh3_corrected']) {
        expect(find.textContaining(value), findsNothing);
      }
    });

    testWidgets('About uses safe product wording and actual app version', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AboutHepaSensePage()));
      expect(find.text('Versi 1.0.0 (1)'), findsOneWidget);
      expect(find.textContaining('bukan diagnosis penyakit'), findsOneWidget);
      expect(find.textContaining('akurasi diagnosis'), findsNothing);
    });

    testWidgets(
      'backend-backed Help renders without fake contact or assistant',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              helpControllerProvider.overrideWith(
                () => FixedHelpController(
                  EducationLoaded(
                    items: [helpArticle()],
                    categories: const [],
                    page: 1,
                    hasNext: false,
                    type: EducationType.help,
                  ),
                ),
              ),
            ],
            child: MaterialApp(theme: AppTheme.light, home: const HelpPage()),
          ),
        );
        await tester.pump();
        expect(find.text('Cara melihat hasil pemeriksaan'), findsOneWidget);
        expect(
          find.textContaining('tidak memberikan diagnosis'),
          findsOneWidget,
        );
        for (final value in ['WhatsApp', '@hepasense', 'hotline', 'chatbot']) {
          expect(find.textContaining(value), findsNothing);
        }
      },
    );
  });
}
