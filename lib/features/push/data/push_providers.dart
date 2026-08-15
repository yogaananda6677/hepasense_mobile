import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_router.dart';
import '../../../core/routing/routes.dart';
import '../../auth/data/auth_providers.dart';
import '../../notifications/data/notification_providers.dart';
import 'push_device_repository.dart';
import 'push_service.dart';
import '../presentation/push_coordinator.dart';

final pushServiceProvider = Provider<PushService>((ref) {
  return FirebasePushService.production();
});

final pushDeviceRepositoryProvider = Provider<PushDeviceRepository>((ref) {
  return PushDeviceRepository(ref.watch(apiClientProvider));
});

final pushCoordinatorProvider = Provider<PushCoordinator>((ref) {
  final coordinator = PushCoordinator(
    service: ref.watch(pushServiceProvider),
    repository: ref.watch(pushDeviceRepositoryProvider),
    refreshNotifications: () async {
      ref.invalidate(notificationControllerProvider);
      await ref.read(unreadCountControllerProvider.notifier).load();
    },
    onOpen: (_) => ref.read(appRouterProvider).go(AppRoutes.notifications),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});
