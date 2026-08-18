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
    final patient = patientState is PatientLinked ? patientState.patient : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: patient != null
            ? _WelcomeHeader(patient: patient)
            : const Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, size: 22, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Beranda Kesehatan',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                tooltip: unread is UnreadCountReady && unread.count > 0
                    ? 'Notifikasi, ${unread.count} belum dibaca'
                    : 'Notifikasi',
                icon: Badge(
                  isLabelVisible: unread is UnreadCountReady && unread.count > 0,
                  label: unread is UnreadCountReady
                      ? Text(unread.count > 99 ? '99+' : unread.count.toString())
                      : null,
                  child: const Icon(Icons.notifications_outlined, size: 22, color: AppColors.primary),
                ),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
            ),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HealthSummary(state: home),
          const SizedBox(height: 20),
          Text(
            'Hasil Pemeriksaan Terakhir',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _latest(context, ref, home),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tips Kesehatan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.education),
                child: Text(
                  'Lihat Semua',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TipsSection(state: education),
        ],
      ),
    );
  }

  Widget _latest(BuildContext context, WidgetRef ref, HomeState state) {
    return switch (state) {
      HomeInitial() || HomeLoading() => const SizedBox(
        height: 140,
        child: StateView(
          state: ViewState.loading,
          loadingMessage: 'Memuat hasil skrining terbaru...',
        ),
      ),
      HomeNoScreening() => _LatestShell(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, size: 32, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada hasil skrining',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hasil pemeriksaan terbaru akan muncul secara otomatis di sini.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: screening.status),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    JakartaDateTime.display(screening.measuredAt),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MeasurementSummary(measurement: screening.measurement),
          const SizedBox(height: 16),
          // Conclusion Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kesimpulan',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invalid
                            ? 'Sampel pemeriksaan belum dapat digunakan.'
                            : StatusMapping.descriptionFor(screening.status),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
    final name = patient.fullName.isEmpty ? 'User Halo' : patient.fullName;
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            initial,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Halo, Selamat Datang',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (patient.patientCode.isNotEmpty)
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
      HomeNoScreening() => 'Pantau terus kondisi lingkungan Anda.',
      HomeFailure() => 'Ringkasan belum dapat dimuat.',
      _ => 'Menyiapkan ringkasan hasil skrining Anda...',
    };

    return Container(
      key: const Key('home-health-summary'),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3300695C),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kesehatan Anda Hari Ini',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 16, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Status: Terpantau',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
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
      const SizedBox(height: 10),
      _item(
        context,
        Icons.thermostat_outlined,
        'Suhu',
        measurement.temperatureCelsius,
        '°C',
      ),
      const SizedBox(height: 10),
      _item(
        context,
        Icons.water_drop_outlined,
        'Kelembapan',
        measurement.humidityPercent,
        '%RH',
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
        : '${parsed.toStringAsFixed(parsed.truncateToDouble() == parsed ? 0 : 1)} ${unit ?? ''}'.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.metricCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.metricBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shown,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
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
        category: 'Paru-Paru',
        title: article.title,
        summary: article.summary.isEmpty
            ? 'Kebersihan udara di rumah berpengaruh besar pada kesehatan jangka panjang keluarga Anda...'
            : article.summary,
        onTap: article.slug.isEmpty
            ? () => context.push(AppRoutes.education)
            : () => context.push(AppRoutes.educationDetailPath(article.slug)),
      );
    }
    return _TipCard(
      category: 'Paru-Paru',
      title: 'Pentingnya Udara Bersih',
      summary:
          'Udara yang bersih membantu sirkulasi oksigen lebih lancar dan menjaga paru-paru tetap sehat.',
      onTap: () => context.push(AppRoutes.education),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.category,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final String category;
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
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                color: AppColors.primarySoft,
                alignment: Alignment.center,
                child: const Icon(Icons.nature_people, size: 48, color: AppColors.primary),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.outline),
                  const SizedBox(width: 4),
                  Text(
                    '4 menit baca',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.outline,
                    ),
                  ),
                ],
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
