class Patient {
  const Patient({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.status,
    required this.userLinked,
    required this.createdAt,
    required this.updatedAt,
    this.dateOfBirth,
    required this.sex,
    required this.phone,
    required this.address,
  });

  final int id;
  final String patientCode;
  final String fullName;
  final String? dateOfBirth;
  final String sex;
  final String phone;
  final String address;
  final String status;
  final bool userLinked;
  final String createdAt;
  final String updatedAt;

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['id'] as int,
    patientCode: json['patient_code'] as String,
    fullName: json['full_name'] as String,
    dateOfBirth: json['date_of_birth'] as String?,
    sex: json['sex'] as String,
    phone: json['phone'] as String,
    address: json['address'] as String,
    status: json['status'] as String,
    userLinked: json['user_linked'] as bool,
    createdAt: json['created_at'] as String,
    updatedAt: json['updated_at'] as String,
  );
}
