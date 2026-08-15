import '../data/models/auth_user.dart';

sealed class AuthStatus {
  const AuthStatus();
}

class AuthInitial extends AuthStatus {
  const AuthInitial();

  @override
  bool operator ==(Object other) => other is AuthInitial;

  @override
  int get hashCode => identityHashCode(this);
}

class AuthLoading extends AuthStatus {
  const AuthLoading();

  @override
  bool operator ==(Object other) => other is AuthLoading;

  @override
  int get hashCode => identityHashCode(this);
}

class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();

  @override
  bool operator ==(Object other) => other is AuthUnauthenticated;

  @override
  int get hashCode => identityHashCode(this);
}

class AuthMfaRequired extends AuthStatus {
  const AuthMfaRequired({required this.challenge, this.errorMessage});
  final String challenge;
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      other is AuthMfaRequired &&
      other.challenge == challenge &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(AuthMfaRequired, challenge, errorMessage);
}

class Authenticated extends AuthStatus {
  const Authenticated({this.user});
  final AuthUser?
  user; // Nullable for session restore until Phase 3 loads user data.

  @override
  bool operator ==(Object other) =>
      other is Authenticated && other.user == user;

  @override
  int get hashCode => Object.hash(Authenticated, user);
}

class AuthFailure extends AuthStatus {
  const AuthFailure({required this.message});
  final String message;

  @override
  bool operator ==(Object other) =>
      other is AuthFailure && other.message == message;

  @override
  int get hashCode => Object.hash(AuthFailure, message);
}
