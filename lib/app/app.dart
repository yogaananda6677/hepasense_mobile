import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../app/router/app_router.dart';
import '../features/auth/domain/auth_status.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/education/data/education_providers.dart';
import '../features/patient/data/patient_providers.dart';
import '../features/patient/domain/patient_state.dart';
import '../features/profile/data/profile_providers.dart';
import '../features/home/data/home_providers.dart';
import '../features/notifications/data/notification_providers.dart';
import '../features/push/data/push_providers.dart';
import '../features/screening/data/screening_providers.dart';

Future<void> refreshPatientDataOnResume({
  required PatientState patient,
  required Future<void> Function() refreshPatient,
  required Future<void> Function() refreshHome,
}) async {
  if (patient is PatientUnlinked) {
    await refreshPatient();
  } else if (patient is PatientLinked) {
    await refreshHome();
  }
}

class HepaSenseApp extends ConsumerStatefulWidget {
  const HepaSenseApp({super.key});

  @override
  ConsumerState<HepaSenseApp> createState() => _HepaSenseAppState();
}

class _HepaSenseAppState extends ConsumerState<HepaSenseApp>
    with WidgetsBindingObserver {
  bool _resumeRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshOnResume());
  }

  Future<void> _refreshOnResume() async {
    if (_resumeRefreshInFlight ||
        ref.read(authControllerProvider) is! Authenticated) {
      return;
    }
    _resumeRefreshInFlight = true;
    try {
      final requests = <Future<void>>[
        ref.read(unreadCountControllerProvider.notifier).load(),
      ];
      final patient = ref.read(patientControllerProvider);
      requests.add(
        refreshPatientDataOnResume(
          patient: patient,
          refreshPatient: () =>
              ref.read(patientControllerProvider.notifier).load(),
          refreshHome: () => ref.read(homeControllerProvider.notifier).load(),
        ),
      );
      await Future.wait(requests);
    } finally {
      _resumeRefreshInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pushCoordinator = ref.watch(pushCoordinatorProvider);
    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      if (next is Authenticated && previous is! Authenticated) {
        pushCoordinator.onAuthenticated();
      }
      if (next is! Authenticated) {
        if (previous is Authenticated) pushCoordinator.onLogout();
        ref.invalidate(patientControllerProvider);
        ref.invalidate(profileControllerProvider);
        ref.invalidate(homeControllerProvider);
        ref.invalidate(historyControllerProvider);
        ref.invalidate(detailControllerProvider);
        ref.invalidate(notificationControllerProvider);
        ref.invalidate(unreadCountControllerProvider);
        ref.invalidate(educationControllerProvider);
        ref.invalidate(articleDetailControllerProvider);
        ref.invalidate(helpControllerProvider);
        ref.invalidate(passwordChangeControllerProvider);
      }
    });
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'HepaSense',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
