import '../../../core/errors/status_mapping.dart';

class ScreeningMeasurement {
  const ScreeningMeasurement({
    required this.nh3Corrected,
    required this.nh3Unit,
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.flowQuality,
    required this.expirationDurationSeconds,
  });

  final String? nh3Corrected;
  final String? nh3Unit;
  final String? temperatureCelsius;
  final String? humidityPercent;
  final String? flowQuality;
  final String? expirationDurationSeconds;

  double? get nh3Value => double.tryParse(nh3Corrected ?? '');

  factory ScreeningMeasurement.fromJson(Map<String, dynamic> json) =>
      ScreeningMeasurement(
        nh3Corrected: json['nh3_corrected'] as String?,
        nh3Unit: json['nh3_unit'] as String?,
        temperatureCelsius: json['temperature_celsius'] as String?,
        humidityPercent: json['humidity_percent'] as String?,
        flowQuality: json['flow_quality'] as String?,
        expirationDurationSeconds:
            json['expiration_duration_seconds'] as String?,
      );
}

class ScreeningResult {
  const ScreeningResult({this.classification, this.confidenceScore});
  final String? classification;
  final String? confidenceScore;

  double? get confidenceValue =>
      confidenceScore == null ? null : double.tryParse(confidenceScore!);

  factory ScreeningResult.fromJson(Map<String, dynamic> json) =>
      ScreeningResult(
        classification: json['classification'] as String?,
        confidenceScore: json['confidence_score'] as String?,
      );
}

class Screening {
  const Screening({
    required this.id,
    required this.screeningUid,
    required this.measuredAt,
    required this.status,
    required this.sampleValid,
    required this.measurement,
    required this.result,
  });

  final int id;
  final String screeningUid;
  final String measuredAt;
  final ScreenStatus status;
  final bool sampleValid;
  final ScreeningMeasurement measurement;
  final ScreeningResult result;

  factory Screening.fromJson(Map<String, dynamic> json) {
    final sampleValid = json['sample_valid'] as bool;
    final parsed = StatusMapping.fromBackend(json['status'] as String?);
    if (parsed == null || (!sampleValid && parsed != ScreenStatus.invalid)) {
      throw const FormatException('Status skrining tidak valid.');
    }
    return Screening(
      id: json['id'] as int,
      screeningUid: json['screening_uid'] as String,
      measuredAt: json['measured_at'] as String,
      status: sampleValid ? parsed : ScreenStatus.invalid,
      sampleValid: sampleValid,
      measurement: ScreeningMeasurement.fromJson(
        json['measurement'] as Map<String, dynamic>,
      ),
      result: ScreeningResult.fromJson(json['result'] as Map<String, dynamic>),
    );
  }
}

class ScreeningSummary {
  const ScreeningSummary({
    required this.id,
    required this.screeningUid,
    required this.measuredAt,
    required this.status,
    required this.sampleValid,
    required this.nh3Corrected,
    required this.nh3Unit,
  });

  final int id;
  final String screeningUid;
  final String measuredAt;
  final ScreenStatus status;
  final bool sampleValid;
  final String nh3Corrected;
  final String nh3Unit;

  double? get nh3Value => double.tryParse(nh3Corrected);

  factory ScreeningSummary.fromJson(Map<String, dynamic> json) {
    final sampleValid = json['sample_valid'] as bool;
    final parsed = StatusMapping.fromBackend(json['status'] as String?);
    if (parsed == null || (!sampleValid && parsed != ScreenStatus.invalid)) {
      throw const FormatException('Status skrining tidak valid.');
    }
    return ScreeningSummary(
      id: json['id'] as int,
      screeningUid: json['screening_uid'] as String,
      measuredAt: json['measured_at'] as String,
      status: sampleValid ? parsed : ScreenStatus.invalid,
      sampleValid: sampleValid,
      nh3Corrected: json['nh3_corrected'] as String,
      nh3Unit: json['nh3_unit'] as String,
    );
  }
}

class ScreeningPage {
  const ScreeningPage({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<ScreeningSummary> results;

  bool get hasNext => next != null;

  factory ScreeningPage.fromJson(Map<String, dynamic> json) => ScreeningPage(
    count: json['count'] as int,
    next: json['next'] as String?,
    previous: json['previous'] as String?,
    results: (json['results'] as List<dynamic>)
        .map((item) => ScreeningSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}
