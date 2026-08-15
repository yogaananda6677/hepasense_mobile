import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../domain/patient.dart';

sealed class PatientResolution {
  const PatientResolution();
}

class LinkedPatient extends PatientResolution {
  const LinkedPatient(this.patient);
  final Patient patient;
}

class UnlinkedPatient extends PatientResolution {
  const UnlinkedPatient();
}

class PatientRepository {
  PatientRepository(this._api);
  final ApiClient _api;

  Future<PatientResolution> getMe() async {
    try {
      final response = await _api.dio.get('/api/v1/patients/me/');
      return LinkedPatient(
        Patient.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const UnlinkedPatient();
      throw ApiError.fromDioException(error);
    }
  }
}
