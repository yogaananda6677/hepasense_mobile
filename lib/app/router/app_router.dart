import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hepasense_mobile/core/routing/routes.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/mfa_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:hepasense_mobile/features/home/home_screen.dart';
import 'package:hepasense_mobile/features/notifications/presentation/pages/notification_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/account_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/history_page.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isMfaRoute = state.matchedLocation == AppRoutes.mfa;

      if (authState is AuthInitial || authState is AuthLoading) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }

      if (authState is AuthUnauthenticated || authState is AuthFailure) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      if (authState is AuthMfaRequired) {
        return isMfaRoute ? null : AppRoutes.mfa;
      }

      if (authState is Authenticated) {
        if (isAuthRoute ||
            isMfaRoute ||
            state.matchedLocation == AppRoutes.splash) {
          return AppRoutes.home;
        }
        return null;
      }

      return null; // Should not be reached with proper state handling
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.mfa,
        builder: (context, state) => const MfaPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.screeningHistory,
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.screeningDetail,
        builder: (context, state) => DetailPage(
          screeningId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationPageView(),
      ),
      GoRoute(
        path: AppRoutes.education,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Education'))),
      ),
      GoRoute(
        path: AppRoutes.educationDetail,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Education Detail'))),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Change Password'))),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Privacy Policy'))),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Help'))),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Settings'))),
      ),
    ],
  );
});
