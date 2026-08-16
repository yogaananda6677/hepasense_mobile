import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/status_mapping.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../data/screening_providers.dart';
import '../../domain/detail_state.dart';
import '../../domain/report_state.dart';
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
    ref.listen(reportControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.message!),
          backgroundColor: next.isError
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
    });
    final patient = ref.watch(patientControllerProvider);
    final detail = ref.watch(detailControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pemeriksaan')),
      body: SafeArea(child: _body(patient, detail)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
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
          AppCard(
            emphasized: true,
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
          AppCard(
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
          const SizedBox(height: AppSpacing.lg),
          _reportActions(screening),
        ],
      ),
    );
  }

  Widget _reportActions(Screening screening) {
    final state = ref.watch(reportControllerProvider);
    final controller = ref.read(reportControllerProvider.notifier);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Laporan Hasil Skrining',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'PDF dibuat dari data pemeriksaan resmi HepaSense.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('report-open-pdf'),
            onPressed: state.isBusy
                ? null
                : () => controller.open(screening.id),
            icon: state.activeAction == ReportAction.open
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Lihat / Unduh PDF'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('report-share-pdf'),
            onPressed: state.isBusy
                ? null
                : () => controller.share(screening.id),
            icon: state.activeAction == ReportAction.share
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: const Text('Bagikan'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('report-email'),
            onPressed: state.isBusy ? null : () => _confirmEmail(screening.id),
            icon: state.activeAction == ReportAction.email
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.email_outlined),
            label: const Text('Kirim ke Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEmail(int screeningId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim laporan?'),
        content: const Text(
          'Kirim hasil skrining ke email yang terdaftar pada akun Anda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(reportControllerProvider.notifier).email(screeningId);
    }
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
    child: AppCard(
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
  );
}
