class AuthUser {
  const AuthUser({required this.id, required this.email});

  final int id;
  final String email;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(id: json['id'] as int, email: json['email'] as String);
  }
}
