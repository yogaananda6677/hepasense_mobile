import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/report_platform_service.dart';
import '../../data/screening_providers.dart';
import '../../domain/report_state.dart';

class ReportController extends Notifier<ReportState> {
  @override
  ReportState build() {
    ref.watch(authControllerProvider);
    return const ReportState();
  }

  Future<void> open(int screeningId) =>
      _withPdf(screeningId, ReportAction.open);

  Future<void> share(int screeningId) =>
      _withPdf(screeningId, ReportAction.share);

  Future<void> _withPdf(int id, ReportAction action) async {
    if (state.isBusy) return;
    state = ReportState(activeAction: action);
    try {
      final report = await ref
          .read(screeningRepositoryProvider)
          .downloadReport(id);
      if (report.bytes.isEmpty) throw const FormatException();
      final platform = ref.read(reportPlatformServiceProvider);
      final path = await platform.writeTemporaryPdf(
        report.bytes,
        report.filename,
      );
      if (action == ReportAction.open) {
        await platform.openPdf(path);
      } else {
        await platform.sharePdf(path);
      }
      state = ReportState(
        message: action == ReportAction.open
            ? 'PDF hasil skrining siap dibuka.'
            : 'Pilih aplikasi untuk membagikan PDF.',
      );
    } on ApiError catch (error) {
      state = ReportState(message: error.message, isError: true);
    } on ReportPlatformException catch (error) {
      state = ReportState(message: error.message, isError: true);
    } catch (_) {
      state = const ReportState(
        message: 'Laporan PDF belum dapat diproses. Silakan coba lagi.',
        isError: true,
      );
    }
  }

  Future<void> email(int screeningId) async {
    if (state.isBusy) return;
    state = const ReportState(activeAction: ReportAction.email);
    try {
      final message = await ref
          .read(screeningRepositoryProvider)
          .emailReport(screeningId);
      state = ReportState(message: message);
    } on ApiError catch (error) {
      state = ReportState(message: error.message, isError: true);
    } catch (_) {
      state = const ReportState(
        message: 'Laporan belum dapat dikirim ke email Anda. Coba lagi.',
        isError: true,
      );
    }
  }
}
