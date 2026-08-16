import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/status_mapping.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/jakarta_datetime.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/state_view.dart';
import '../../core/widgets/status_badge.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import '../education/data/education_providers.dart';
import '../education/domain/education_state.dart';
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
      if (ref.read(educationControllerProvider) is EducationInitial) {
        ref.read(educationControllerProvider.notifier).loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientControllerProvider);
    final unread = ref.watch(unreadCountControllerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_outlined, size: 20),
            SizedBox(width: 8),
            Text('Beranda Kesehatan'),
          ],
        ),
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
              child: const Icon(Icons.notifications_outlined, size: 20),
            ),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      body: SafeArea(child: _patientGate(context, ref, patientState)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
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
        onRetry: () => ref.read(patientControllerProvider.notifier).load(),
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
    final education = ref.watch(educationControllerProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeControllerProvider.notifier).load();
        await ref.read(educationControllerProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
        children: [
          _WelcomeHeader(patient: patient),
          const SizedBox(height: 12),
          _HealthSummary(state: home),
          const SizedBox(height: 16),
          Text(
            'Hasil Pemeriksaan Terakhir',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _latest(context, ref, home),
          const SizedBox(height: 20),
          Text('Tips Kesehatan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _TipsSection(state: education),
        ],
      ),
    );
  }

  Widget _latest(BuildContext context, WidgetRef ref, HomeState state) {
    return switch (state) {
      HomeInitial() || HomeLoading() => const SizedBox(
        height: 112,
        child: StateView(
          state: ViewState.loading,
          loadingMessage: 'Memuat hasil skrining terbaru...',
        ),
      ),
      HomeNoScreening() => _LatestShell(
        child: Row(
          children: [
            const Icon(Icons.assignment_outlined, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada hasil skrining',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  const Text('Hasil pemeriksaan terbaru akan muncul di sini.'),
                ],
              ),
            ),
          ],
        ),
      ),
      HomeLatest(:final screening) => _LatestCard(screening: screening),
      HomeFailure(:final message) => SizedBox(
        height: 224,
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
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Skrining Terbaru',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: screening.status),
              Text(
                JakartaDateTime.display(screening.measuredAt),
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MeasurementSummary(measurement: screening.measurement),
          const SizedBox(height: 18),
          Text('Kesimpulan', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            invalid
                ? 'Sampel pemeriksaan belum dapat digunakan.'
                : StatusMapping.descriptionFor(screening.status),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 14),
          AppButton(
            key: const Key('home-history-cta'),
            text: 'Lihat Riwayat Lengkap',
            onPressed: () => context.go(AppRoutes.screeningHistory),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final name = patient.fullName.isEmpty
        ? 'Pengguna HepaSense'
        : patient.fullName;
    final initial = name.trim().isEmpty ? 'H' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 1.5),
          ),
          child: Text(
            initial,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Selamat Datang',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              Text(
                patient.patientCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LatestShell extends StatelessWidget {
  const _LatestShell({required this.child, this.emphasized = false});
  final Widget child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => AppCard(
    emphasized: emphasized,
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary({required this.state});
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final message = switch (state) {
      HomeLatest(:final screening) when !screening.sampleValid =>
        'Sampel terakhir belum valid dan perlu diulang.',
      HomeLatest(:final screening) =>
        'Hasil terakhir: ${StatusMapping.safeLabelFor(screening.status)}. Ini bukan diagnosis medis.',
      HomeNoScreening() => 'Belum ada hasil skrining untuk dirangkum.',
      HomeFailure() => 'Ringkasan belum dapat dimuat.',
      _ => 'Menyiapkan ringkasan hasil skrining Anda...',
    };
    return Container(
      key: const Key('home-health-summary'),
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, AppColors.background],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kesehatan Anda Hari Ini',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MeasurementSummary extends StatelessWidget {
  const _MeasurementSummary({required this.measurement});
  final ScreeningMeasurement measurement;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _item(
        context,
        Icons.science_outlined,
        'NH3',
        measurement.nh3Corrected,
        measurement.nh3Unit,
      ),
      const SizedBox(height: 8),
      _item(
        context,
        Icons.thermostat_outlined,
        'Suhu',
        measurement.temperatureCelsius,
        '°C',
      ),
      const SizedBox(height: 8),
      _item(
        context,
        Icons.water_drop_outlined,
        'Kelembapan',
        measurement.humidityPercent,
        '%',
      ),
    ],
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
    String? unit,
  ) {
    final parsed = double.tryParse(value ?? '');
    final shown = parsed == null
        ? '—'
        : '${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 1)}${unit?.isNotEmpty == true ? ' $unit' : ''}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(shown, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipsSection extends StatelessWidget {
  const _TipsSection({required this.state});
  final EducationState state;

  @override
  Widget build(BuildContext context) {
    if (state case EducationLoaded(:final items) when items.isNotEmpty) {
      final article = items.first;
      return _TipCard(
        title: article.title,
        summary: article.summary.isEmpty
            ? 'Informasi kesehatan umum dari HepaSense.'
            : article.summary,
        onTap: article.slug.isEmpty
            ? () => context.push(AppRoutes.education)
            : () => context.push(AppRoutes.educationDetailPath(article.slug)),
      );
    }
    return _TipCard(
      title: 'Pentingnya Udara Bersih',
      summary:
          'Udara yang bersih membantu menjaga kenyamanan pernapasan dan kesehatan sehari-hari.',
      onTap: () => context.push(AppRoutes.education),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    semanticLabel: 'Buka artikel $title',
    padding: EdgeInsets.zero,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Image.asset(
            'assets/images/health_tips_banner.png',
            width: double.infinity,
            height: 112,
            fit: BoxFit.cover,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _UnlinkedPatient extends StatelessWidget {
  const _UnlinkedPatient({required this.onRetry, required this.onLogout});
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Icon(
          Icons.person_off_outlined,
          size: 72,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Akun belum terhubung',
        style: Theme.of(context).textTheme.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.sm),
      const Text(
        'Akun HepaSense Anda sudah berhasil dibuat, tetapi belum terhubung dengan data pasien. Minta tenaga kesehatan menghubungkan akun menggunakan email yang Anda gunakan saat mendaftar.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton(text: 'Coba Lagi', onPressed: onRetry),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        text: 'Keluar',
        onPressed: onLogout,
        variant: AppButtonVariant.secondary,
      ),
    ],
  );
}
