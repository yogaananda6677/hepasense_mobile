import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/jakarta_datetime.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_bottom_navigation.dart';
import '../../../../core/widgets/state_view.dart';
import '../../data/notification_providers.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_state.dart';

class NotificationPageView extends ConsumerStatefulWidget {
  const NotificationPageView({super.key});

  @override
  ConsumerState<NotificationPageView> createState() =>
      _NotificationPageViewState();
}

class _NotificationPageViewState extends ConsumerState<NotificationPageView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationControllerProvider.notifier).loadInitial();
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
      ref.read(notificationControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (state case NotificationLoaded(:final visibleUnread))
            IconButton(
              tooltip: 'Tandai semua sudah dibaca',
              onPressed: visibleUnread == 0 || state.isMarkingAll
                  ? null
                  : () => ref
                        .read(notificationControllerProvider.notifier)
                        .markAllRead(),
              icon: state.isMarkingAll
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all),
            ),
        ],
      ),
      body: SafeArea(child: _body(state)),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
    );
  }

  Widget _body(NotificationState state) => switch (state) {
    NotificationInitial() || NotificationLoading() => const StateView(
      state: ViewState.loading,
      loadingMessage: 'Memuat notifikasi...',
    ),
    NotificationFailure(:final message) => StateView(
      state: ViewState.error,
      errorMessage: message,
      onRetry: () =>
          ref.read(notificationControllerProvider.notifier).loadInitial(),
    ),
    NotificationLoaded() => _loaded(state),
  };

  Widget _loaded(NotificationLoaded state) {
    if (state.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 480,
              child: StateView(
                state: ViewState.empty,
                emptyTitle: 'Belum ada notifikasi',
                emptyMessage:
                    'Pembaruan terkait pemeriksaan HepaSense akan muncul di sini.',
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.mutationError != null)
          MaterialBanner(
            content: Text(state.mutationError!),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(notificationControllerProvider.notifier)
                    .dismissMutationError(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationControllerProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: state.items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index < state.items.length) {
                  final item = state.items[index];
                  return _NotificationRow(
                    item: item,
                    isMarkingRead: state.markingReadIds.contains(item.id),
                    onTap: () => _open(item),
                  );
                }
                return _footer(state);
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _open(AppNotification item) async {
    if (!item.isRead) {
      await ref.read(notificationControllerProvider.notifier).markRead(item.id);
    }
    if (!mounted || item.screeningId == null) return;
    await context.push(
      AppRoutes.screeningDetailPath(item.screeningId.toString()),
    );
  }

  Widget _footer(NotificationLoaded state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.nextPageError != null) {
      return Column(
        children: [
          Text(state.nextPageError!, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            text: 'Coba Lagi',
            variant: AppButtonVariant.outline,
            onPressed: () =>
                ref.read(notificationControllerProvider.notifier).loadMore(),
          ),
        ],
      );
    }
    return const SizedBox(height: AppSpacing.sm);
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.isMarkingRead,
    required this.onTap,
  });
  final AppNotification item;
  final bool isMarkingRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    return Semantics(
      button: true,
      label: '${unread ? 'Belum dibaca. ' : 'Sudah dibaca. '}${item.title}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isMarkingRead ? null : onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.25)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: unread ? 1.5 : 1,
              color: unread
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_icon(item.type), size: 26),
                  if (unread)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Semantics(
                        label: 'Belum dibaca',
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.message),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      JakartaDateTime.display(item.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (item.screeningId != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Buka detail pemeriksaan',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isMarkingRead)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (item.screeningId != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(Icons.chevron_right, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'screening_ready' => Icons.assignment_turned_in_outlined,
    'warning_result' => Icons.warning_amber_outlined,
    'high_risk_result' => Icons.error_outline,
    'invalid_measurement' => Icons.refresh_outlined,
    _ => Icons.notifications_outlined,
  };
}
