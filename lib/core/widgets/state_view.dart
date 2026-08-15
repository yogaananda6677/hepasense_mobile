import 'package:flutter/material.dart';

import 'app_button.dart';

enum ViewState { initial, loading, success, empty, error }

class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.state,
    this.loadingMessage,
    this.emptyTitle,
    this.emptyMessage,
    this.errorMessage,
    this.onRetry,
    this.child,
  });

  final ViewState state;
  final String? loadingMessage;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ViewState.initial:
      case ViewState.loading:
        return _LoadingView(message: loadingMessage);
      case ViewState.empty:
        return _EmptyView(
          title: emptyTitle ?? 'Tidak ada data',
          message: emptyMessage ?? 'Belum ada data yang tersedia.',
        );
      case ViewState.error:
        return _ErrorView(
          message: errorMessage ?? 'Terjadi kesalahan.',
          onRetry: onRetry,
        );
      case ViewState.success:
        return child ?? const SizedBox.shrink();
    }
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                onPressed: onRetry,
                text: 'Coba Lagi',
                variant: AppButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
