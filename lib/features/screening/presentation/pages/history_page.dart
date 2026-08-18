import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/status_mapping.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../notifications/data/notification_providers.dart';
import '../../../notifications/domain/notification_state.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/patient_state.dart';
import '../../data/screening_providers.dart';
import '../../domain/history_state.dart';
import '../../domain/screening.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(patientControllerProvider) is PatientLinked) {
        ref.read(historyControllerProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 160) {
      ref.read(historyControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientControllerProvider);
    final history = ref.watch(historyControllerProvider);
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
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
              ),
              child: Text(
                patient?.fullName.trim().isNotEmpty == true
                    ? patient!.fullName.trim()[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Riwayat Pemeriksaan',
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
      body: SafeArea(child: _body(patientState, history)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
    );
  }

  Widget _body(PatientState patient, HistoryState history) {
    if (patient is! PatientLinked) {
      return const StateView(
        state: ViewState.empty,
        emptyTitle: 'Data pasien belum tersedia',
        emptyMessage:
            'Riwayat hanya tersedia untuk akun yang terhubung dengan data pasien.',
      );
    }
    return switch (history) {
      HistoryInitial() || HistoryLoading() => const StateView(
        state: ViewState.loading,
        loadingMessage: 'Memuat riwayat pemeriksaan...',
      ),
      HistoryFailure(:final message) => StateView(
        state: ViewState.error,
        errorMessage: message,
        onRetry: () =>
            ref.read(historyControllerProvider.notifier).loadInitial(),
      ),
      HistoryLoaded() => _loaded(history),
    };
  }

  Widget _loaded(HistoryLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _chip('Semua', null, state.filter, icon: Icons.calendar_today_outlined),
              _chip('Baik', ScreenStatus.healthy, state.filter),
              _chip('Waspada', ScreenStatus.warning, state.filter),
              _chip('Risiko Tinggi', ScreenStatus.highRisk, state.filter),
              _chip('Tidak Valid', ScreenStatus.invalid, state.filter),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: state.isEmpty
              ? const StateView(
                  state: ViewState.empty,
                  emptyTitle: 'Belum ada riwayat pemeriksaan',
                  emptyMessage:
                      'Hasil akan muncul setelah pemeriksaan HepaSense selesai.',
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(historyControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                    itemCount: state.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      if (index < state.items.length) {
                        return _HistoryRow(item: state.items[index]);
                      }
                      return _footer(state);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(
    String label,
    ScreenStatus? value,
    ScreenStatus? selected, {
    IconData? icon,
  }) {
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        avatar: icon != null
            ? Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.primary)
            : null,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        onSelected: (_) =>
            ref.read(historyControllerProvider.notifier).setFilter(value),
      ),
    );
  }

  Widget _footer(HistoryLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.nextPageError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Text(state.nextPageError!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Coba Lagi',
              variant: AppButtonVariant.outline,
              onPressed: () =>
                  ref.read(historyControllerProvider.notifier).loadMore(),
            ),
          ],
        ),
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final ScreeningSummary item;

  @override
  Widget build(BuildContext context) {
    final parsedNh3 = double.tryParse(item.nh3Corrected);
    final nh3Text = parsedNh3 == null
        ? '—'
        : '${parsedNh3.toStringAsFixed(parsedNh3.truncateToDouble() == parsedNh3 ? 0 : 1)} ${item.nh3Unit.isNotEmpty ? item.nh3Unit : 'ppm'}'.trim();

    return Semantics(
      button: true,
      label:
          'Buka detail pemeriksaan ${StatusMapping.safeLabelFor(item.status)}',
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () =>
            context.push(AppRoutes.screeningDetailPath(item.id.toString())),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        JakartaDateTime.display(item.measuredAt).toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Pemeriksaan HepaSense',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 8),
            // Metric grid
            Row(
              children: [
                Expanded(
                  child: _metricBox(
                    context,
                    Icons.science_outlined,
                    'NH3',
                    nh3Text,
                    isHigh: item.status == ScreenStatus.warning || item.status == ScreenStatus.highRisk,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricBox(
                    context,
                    Icons.thermostat_outlined,
                    'Suhu',
                    '24°C',
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _metricBox(
                    context,
                    Icons.water_drop_outlined,
                    'Lembap',
                    '55',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 34,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () => context.push(
                  AppRoutes.screeningDetailPath(item.id.toString()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lihat Detail',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHigh = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHigh
              ? AppColors.error.withOpacity(0.3)
              : AppColors.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isHigh ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHigh ? AppColors.error : AppColors.onSurface,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
