import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/status_mapping.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_view.dart';
import '../../../../core/widgets/status_badge.dart';
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
    final patient = ref.watch(patientControllerProvider);
    final history = ref.watch(historyControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pemeriksaan'),
        centerTitle: false,
      ),
      body: SafeArea(child: _body(patient, history)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go(AppRoutes.home);
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
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            children: [
              _chip('Semua', null, state.filter),
              _chip('Baik', ScreenStatus.healthy, state.filter),
              _chip('Waspada', ScreenStatus.warning, state.filter),
              _chip('Risiko Tinggi', ScreenStatus.highRisk, state.filter),
              _chip('Tidak Valid', ScreenStatus.invalid, state.filter),
            ],
          ),
        ),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: state.items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
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

  Widget _chip(String label, ScreenStatus? value, ScreenStatus? selected) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected == value,
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
    return Semantics(
      button: true,
      label:
          'Buka detail pemeriksaan ${StatusMapping.safeLabelFor(item.status)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(AppRoutes.screeningDetailPath(item.id.toString())),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.sampleValid
                    ? Icons.monitor_heart_outlined
                    : Icons.refresh_outlined,
                color: item.sampleValid
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemeriksaan HepaSense',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      JakartaDateTime.display(item.measuredAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: StatusBadge(status: item.status)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
