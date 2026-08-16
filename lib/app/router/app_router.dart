import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hepasense_mobile/core/routing/routes.dart';
import 'package:hepasense_mobile/features/ai/presentation/pages/ai_assistant_page.dart';
import 'package:hepasense_mobile/features/ai/presentation/pages/ai_conversation_page.dart';
import 'package:hepasense_mobile/features/auth/domain/auth_status.dart';
import 'package:hepasense_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/mfa_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:hepasense_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:hepasense_mobile/features/education/presentation/pages/article_detail_page.dart';
import 'package:hepasense_mobile/features/education/presentation/pages/education_page.dart';
import 'package:hepasense_mobile/features/home/home_screen.dart';
import 'package:hepasense_mobile/features/notifications/presentation/pages/notification_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/account_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/about_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/help_page.dart';
import 'package:hepasense_mobile/features/profile/presentation/pages/privacy_page.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/history_page.dart';
import 'package:hepasense_mobile/features/screening/presentation/pages/detail_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier();
  ref
    ..onDispose(refreshNotifier.dispose)
    ..listen<AuthStatus>(authControllerProvider, (_, _) {
      refreshNotifier.refresh();
    });

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak tersedia')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Halaman yang Anda cari tidak ditemukan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      final isMfaRoute = state.matchedLocation == AppRoutes.mfa;

      if (authState is AuthInitial) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }

      if (authState is AuthLoading) return null;

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
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.screeningHistory,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: HistoryPage()),
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
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: EducationPageView()),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AiAssistantPage()),
      ),
      GoRoute(
        path: AppRoutes.aiConversation,
        pageBuilder: (context, state) => NoTransitionPage(
          child: AiConversationPage(
            conversationId: int.tryParse(state.pathParameters['id'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.educationDetail,
        builder: (context, state) =>
            ArticleDetailPage(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.account,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: AccountPage()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (context, state) => const HelpPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutHepaSensePage(),
      ),
    ],
  );
});

class _AuthRouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
