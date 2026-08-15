class AccountProfile {
  const AccountProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    required this.isPatient,
    required this.isDoctor,
    required this.twoFactorEnabled,
    this.dateOfBirth,
    this.gender,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? gender;
  final bool isPatient;
  final bool isDoctor;
  final bool twoFactorEnabled;

  factory AccountProfile.fromJson(Map<String, dynamic> json) => AccountProfile(
    id: json['id'] as int,
    email: json['email'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    fullName: json['full_name'] as String,
    phoneNumber: json['phone_number'] as String,
    dateOfBirth: json['date_of_birth'] as String?,
    gender: json['gender'] as String?,
    isPatient: json['is_patient'] as bool,
    isDoctor: json['is_doctor'] as bool,
    twoFactorEnabled: json['two_factor_enabled'] as bool,
  );
}

class AccountProfileUpdate {
  const AccountProfileUpdate({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.dateOfBirth,
    this.gender,
  });

  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? gender;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'phone_number': phoneNumber,
    'date_of_birth': dateOfBirth,
    'gender': gender,
  };
}
