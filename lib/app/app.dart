import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../app/router/app_router.dart';
import '../features/auth/domain/auth_status.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/patient/data/patient_providers.dart';
import '../features/profile/data/profile_providers.dart';
import '../features/home/data/home_providers.dart';
import '../features/notifications/data/notification_providers.dart';
import '../features/push/data/push_providers.dart';
import '../features/screening/data/screening_providers.dart';

class HepaSenseApp extends ConsumerWidget {
  const HepaSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
