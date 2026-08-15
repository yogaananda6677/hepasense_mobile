import 'account_profile.dart';

sealed class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, {this.isSaving = false, this.message});
  final AccountProfile profile;
  final bool isSaving;
  final String? message;
}

class ProfileFailure extends ProfileState {
  const ProfileFailure(this.message);
  final String message;
}
