import 'screening.dart';

sealed class DetailState {
  const DetailState();
}

class DetailInitial extends DetailState {
  const DetailInitial();
}

class DetailLoading extends DetailState {
  const DetailLoading();
}

class DetailLoaded extends DetailState {
  const DetailLoaded(this.screening, {this.isRefreshing = false});
  final Screening screening;
  final bool isRefreshing;
}

class DetailNotFound extends DetailState {
  const DetailNotFound();
}

class DetailFailure extends DetailState {
  const DetailFailure(this.message);
  final String message;
}
