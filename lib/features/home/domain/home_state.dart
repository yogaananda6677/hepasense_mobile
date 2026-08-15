import '../../screening/domain/screening.dart';

sealed class HomeState {
  const HomeState();
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLatest extends HomeState {
  const HomeLatest(this.screening);
  final Screening screening;
}

class HomeNoScreening extends HomeState {
  const HomeNoScreening();
}

class HomeFailure extends HomeState {
  const HomeFailure(this.message);
  final String message;
}
