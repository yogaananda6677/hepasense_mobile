class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.dateOfBirth,
    this.gender,
  });

  final String email;
  final String password;
  final String passwordConfirm;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? gender;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    };
    if (dateOfBirth != null) json['date_of_birth'] = dateOfBirth;
    if (gender != null) json['gender'] = gender;
    return json;
  }
}
