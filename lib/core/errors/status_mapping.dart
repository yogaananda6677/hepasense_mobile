enum ScreenStatus { healthy, warning, highRisk, invalid }

class StatusMapping {
  StatusMapping._();

  static const Map<ScreenStatus, String> labels = {
    ScreenStatus.healthy: 'Hasil Skrining Baik',
    ScreenStatus.warning: 'Waspada',
    ScreenStatus.highRisk: 'Risiko Tinggi',
    ScreenStatus.invalid: 'Pemeriksaan Tidak Valid',
  };

  static const Map<ScreenStatus, String> descriptions = {
    ScreenStatus.healthy:
        'Hasil skrining menunjukkan kondisi dalam batas normal.',
    ScreenStatus.warning:
        'Hasil pemeriksaan awal menunjukkan indikasi yang perlu diperhatikan.',
    ScreenStatus.highRisk:
        'Hasil ini menunjukkan risiko yang perlu diperhatikan lebih lanjut. '
        'Ini bukan diagnosis medis.',
    ScreenStatus.invalid:
        'Pemeriksaan tidak valid. Sampel tidak dapat dianalisis.',
  };

  static const Map<ScreenStatus, String> icons = {
    ScreenStatus.healthy: 'check_circle',
    ScreenStatus.warning: 'warning',
    ScreenStatus.highRisk: 'error',
    ScreenStatus.invalid: 'help_outline',
  };

  static ScreenStatus? fromBackend(String? status) {
    switch (status) {
      case 'healthy':
        return ScreenStatus.healthy;
      case 'warning':
        return ScreenStatus.warning;
      case 'high_risk':
        return ScreenStatus.highRisk;
      case 'invalid':
        return ScreenStatus.invalid;
      default:
        return null;
    }
  }

  static String labelFor(ScreenStatus status) => labels[status] ?? 'Unknown';

  static String descriptionFor(ScreenStatus status) =>
      descriptions[status] ?? '';

  static String iconFor(ScreenStatus status) => icons[status] ?? 'help_outline';

  /// Guard: invalid status must never return a classification label.
  static String safeLabelFor(ScreenStatus status) {
    if (status == ScreenStatus.invalid) {
      return 'Pemeriksaan Tidak Valid';
    }
    return labels[status] ?? 'Unknown';
  }
}
