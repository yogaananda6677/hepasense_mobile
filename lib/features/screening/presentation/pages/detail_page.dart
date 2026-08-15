import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/status_mapping.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../data/screening_providers.dart';
import '../../domain/detail_state.dart';
import '../../domain/screening.dart';

class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.screeningId});
  final int? screeningId;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(detailControllerProvider.notifier)
          .load(widget.screeningId ?? -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final patient = ref.watch(patientControllerProvider);
    final detail = ref.watch(detailControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pemeriksaan')),
      body: SafeArea(child: _body(patient, detail)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go(AppRoutes.home);
          if (index == 1) context.go(AppRoutes.screeningHistory);
          if (index == 2) context.push(AppRoutes.account);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _body(PatientState patient, DetailState detail) {
    if (patient is! PatientLinked) {
      return const StateView(
        state: ViewState.empty,
        emptyTitle: 'Data pasien belum tersedia',
        emptyMessage:
            'Detail hanya tersedia untuk akun yang terhubung dengan data pasien.',
      );
    }
    return switch (detail) {
      DetailInitial() || DetailLoading() => const StateView(
        state: ViewState.loading,
        loadingMessage: 'Memuat detail pemeriksaan...',
      ),
      DetailNotFound() => const StateView(
        state: ViewState.empty,
        emptyTitle: 'Detail tidak tersedia',
        emptyMessage:
            'Data pemeriksaan tidak ditemukan atau sudah tidak tersedia.',
      ),
      DetailFailure(:final message) => StateView(
        state: ViewState.error,
        errorMessage: message,
        onRetry: () => ref
            .read(detailControllerProvider.notifier)
            .load(widget.screeningId ?? -1),
      ),
      DetailLoaded(:final screening) => _loaded(screening),
    };
  }

  Widget _loaded(Screening screening) {
    final invalid = !screening.sampleValid;
    return RefreshIndicator(
      onRefresh: () => ref
          .read(detailControllerProvider.notifier)
          .load(screening.id, refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: StatusBadge(status: screening.status)),
                  const SizedBox(height: AppSpacing.md),
                  Icon(
                    invalid
                        ? Icons.refresh_outlined
                        : Icons.monitor_heart_outlined,
                    size: 56,
                    color: invalid
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    invalid
                        ? 'Sampel pemeriksaan tidak valid'
                        : StatusMapping.safeLabelFor(screening.status),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    invalid
                        ? 'Sampel belum dapat dianalisis. Ulangi pemeriksaan sesuai prosedur perangkat.'
                        : StatusMapping.descriptionFor(screening.status),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Waktu pengukuran',
                    value: JakartaDateTime.display(screening.measuredAt),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    icon: invalid ? Icons.cancel_outlined : Icons.check_circle,
                    label: 'Validitas sampel',
                    value: invalid ? 'Tidak valid' : 'Valid',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hasil Pengukuran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 400
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : constraints.maxWidth;
              final measurement = screening.measurement;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MeasurementTile(
                    width: tileWidth,
                    icon: Icons.science_outlined,
                    label: 'NH3 terkoreksi',
                    value: _decimal(
                      measurement.nh3Corrected,
                      unit: measurement.nh3Unit,
                    ),
                  ),
                  _MeasurementTile(
                    width: tileWidth,
                    icon: Icons.thermostat_outlined,
                    label: 'Suhu',
                    value: _decimal(measurement.temperatureCelsius, unit: '°C'),
                  ),
                  _MeasurementTile(
                    width: tileWidth,
                    icon: Icons.water_drop_outlined,
                    label: 'Kelembapan',
                    value: _decimal(measurement.humidityPercent, unit: '%'),
                  ),
                  _MeasurementTile(
                    width: tileWidth,
                    icon: Icons.air,
                    label: 'Kualitas aliran',
                    value: _decimal(measurement.flowQuality),
                  ),
                  _MeasurementTile(
                    width: tileWidth,
                    icon: Icons.timer_outlined,
                    label: 'Durasi ekspirasi',
                    value: _decimal(
                      measurement.expirationDurationSeconds,
                      unit: 'detik',
                    ),
                  ),
                ],
              );
            },
          ),
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
                      'Hasil ini merupakan skrining awal, bukan diagnosis medis. Konsultasikan dengan tenaga kesehatan bila Anda memiliki keluhan atau kekhawatiran.',
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

  String _decimal(String? raw, {String? unit}) {
    if (raw == null || double.tryParse(raw) == null) return 'Tidak tersedia';
    var value = raw;
    if (value.contains('.')) {
      value = value.replaceFirst(RegExp(r'0+$'), '');
      value = value.replaceFirst(RegExp(r'\.$'), '');
    }
    final safeUnit = unit?.trim();
    return safeUnit == null || safeUnit.isEmpty ? value : '$value $safeUnit';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text(label)),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ],
  );
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    ),
  );
}
