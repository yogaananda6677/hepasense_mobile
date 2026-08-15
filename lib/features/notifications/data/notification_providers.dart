import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/notification_state.dart';
import '../presentation/controllers/notification_controller.dart';
import 'notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

final notificationControllerProvider =
    NotifierProvider<NotificationController, NotificationState>(
      NotificationController.new,
    );

final unreadCountControllerProvider =
    NotifierProvider<UnreadCountController, UnreadCountState>(
      UnreadCountController.new,
    );
