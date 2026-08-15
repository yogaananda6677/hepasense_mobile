import 'patient.dart';

sealed class PatientState {
  const PatientState();
}

class PatientInitial extends PatientState {
  const PatientInitial();
}

class PatientLoading extends PatientState {
  const PatientLoading();
}

class PatientLinked extends PatientState {
  const PatientLinked(this.patient);
  final Patient patient;
}

class PatientUnlinked extends PatientState {
  const PatientUnlinked();
}

class PatientFailure extends PatientState {
  const PatientFailure(this.message);
  final String message;
}
