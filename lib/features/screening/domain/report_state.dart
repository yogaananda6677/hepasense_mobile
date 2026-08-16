enum ReportAction { open, share, email }

class ReportState {
  const ReportState({this.activeAction, this.message, this.isError = false});

  final ReportAction? activeAction;
  final String? message;
  final bool isError;

  bool get isBusy => activeAction != null;
}
