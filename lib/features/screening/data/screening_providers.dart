import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/history_state.dart';
import '../domain/detail_state.dart';
import '../presentation/controllers/detail_controller.dart';
import '../presentation/controllers/history_controller.dart';
import 'screening_repository.dart';
import 'report_platform_service.dart';
import '../domain/report_state.dart';
import '../presentation/controllers/report_controller.dart';

final screeningRepositoryProvider = Provider<ScreeningRepository>((ref) {
  return ScreeningRepository(ref.watch(apiClientProvider));
});

final historyControllerProvider =
    NotifierProvider<HistoryController, HistoryState>(HistoryController.new);

final detailControllerProvider =
    NotifierProvider<DetailController, DetailState>(DetailController.new);

final reportPlatformServiceProvider = Provider<ReportPlatformService>((ref) {
  return SystemReportPlatformService();
});

final reportControllerProvider =
    NotifierProvider<ReportController, ReportState>(ReportController.new);
