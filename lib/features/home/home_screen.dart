import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/status_mapping.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/jakarta_datetime.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../notifications/data/notification_providers.dart';
import '../notifications/domain/notification_state.dart';
import '../patient/data/patient_providers.dart';
import '../patient/domain/patient.dart';
import '../patient/domain/patient_state.dart';
import '../screening/domain/screening.dart';
import 'data/home_providers.dart';
import 'domain/home_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadCountControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientControllerProvider);
    final unread = ref.watch(unreadCountControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('HepaSense'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: unread is UnreadCountReady && unread.count > 0
                ? 'Notifikasi, ${unread.count} belum dibaca'
                : 'Notifikasi',
            icon: Badge(
              isLabelVisible: unread is UnreadCountReady && unread.count > 0,
              label: unread is UnreadCountReady
                  ? Text(unread.count > 99 ? '99+' : unread.count.toString())
                  : null,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Akun',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(AppRoutes.account),
          ),
        ],
      ),
      body: SafeArea(child: _patientGate(context, ref, patientState)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push(AppRoutes.screeningHistory);
          if (index == 2) context.push(AppRoutes.account);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _patientGate(BuildContext context, WidgetRef ref, PatientState state) {
    return switch (state) {
      PatientInitial() || PatientLoading() => const StateView(
        state: ViewState.loading,
        loadingMessage: 'Memeriksa data pasien...',
      ),
      PatientLinked(:final patient) => _LinkedHome(patient: patient),
      PatientUnlinked() => _UnlinkedPatient(
        onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      PatientFailure(:final message) => StateView(
        state: ViewState.error,
        errorMessage: 'Data pasien belum dapat dimuat. $message',
        onRetry: () => ref.read(patientControllerProvider.notifier).load(),
      ),
    };
  }
}

class _LinkedHome extends ConsumerWidget {
  const _LinkedHome({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeControllerProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(homeControllerProvider.notifier).load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Selamat datang,',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            patient.fullName.isEmpty ? 'Pengguna HepaSense' : patient.fullName,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pantau hasil skrining terbaru Anda.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kode pasien: ${patient.patientCode}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          _latest(context, ref, home),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'HepaSense merupakan alat bantu skrining awal dan bukan diagnosis medis.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _latest(BuildContext context, WidgetRef ref, HomeState state) {
    return switch (state) {
      HomeInitial() || HomeLoading() => const SizedBox(
        height: 220,
        child: StateView(
          state: ViewState.loading,
          loadingMessage: 'Memuat hasil skrining terbaru...',
        ),
      ),
      HomeNoScreening() => _LatestShell(
        child: Column(
          children: [
            const Icon(Icons.assignment_outlined, size: 48),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Belum ada hasil skrining',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Hasil pemeriksaan terbaru akan muncul di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      HomeLatest(:final screening) => _LatestCard(screening: screening),
      HomeFailure(:final message) => SizedBox(
        height: 240,
        child: StateView(
          state: ViewState.error,
          errorMessage: message,
          onRetry: () => ref.read(homeControllerProvider.notifier).load(),
        ),
      ),
    };
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.screening});
  final Screening screening;

  @override
  Widget build(BuildContext context) {
    final invalid = !screening.sampleValid;
    return _LatestShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Skrining Terbaru',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              StatusBadge(status: screening.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Icon(
            invalid ? Icons.refresh_outlined : Icons.monitor_heart_outlined,
            size: 56,
            color: invalid
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            invalid
                ? 'Sampel pemeriksaan belum dapat digunakan.'
                : StatusMapping.descriptionFor(screening.status),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            JakartaDateTime.display(screening.measuredAt),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Lihat Detail',
            onPressed: () => context.push(
              AppRoutes.screeningDetailPath(screening.id.toString()),
            ),
            variant: AppButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}

class _LatestShell extends StatelessWidget {
  const _LatestShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
  );
}

class _UnlinkedPatient extends StatelessWidget {
  const _UnlinkedPatient({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      const SizedBox(height: AppSpacing.xl),
      Icon(
        Icons.person_off_outlined,
        size: 72,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Akun belum terhubung',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Akun Anda belum terhubung dengan data pasien HepaSense. Hubungi petugas layanan HepaSense untuk menghubungkan akun.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton(
        text: 'Keluar',
        onPressed: onLogout,
        variant: AppButtonVariant.secondary,
      ),
    ],
  );
}
