import 'package:flutter_test/flutter_test.dart';
import 'package:hepasense_mobile/core/errors/status_mapping.dart';

void main() {
  group('StatusMapping', () {
    test('maps healthy backend string to ScreenStatus', () {
      expect(StatusMapping.fromBackend('healthy'), ScreenStatus.healthy);
    });

    test('maps warning backend string to ScreenStatus', () {
      expect(StatusMapping.fromBackend('warning'), ScreenStatus.warning);
    });

    test('maps high_risk backend string to ScreenStatus', () {
      expect(StatusMapping.fromBackend('high_risk'), ScreenStatus.highRisk);
    });

    test('maps invalid backend string to ScreenStatus', () {
      expect(StatusMapping.fromBackend('invalid'), ScreenStatus.invalid);
    });

    test('returns null for unknown backend string', () {
      expect(StatusMapping.fromBackend('unknown'), isNull);
      expect(StatusMapping.fromBackend(null), isNull);
    });

    test('labels are in Bahasa Indonesia', () {
      expect(StatusMapping.labels[ScreenStatus.healthy], contains('Baik'));
      expect(StatusMapping.labels[ScreenStatus.warning], contains('Waspada'));
      expect(StatusMapping.labels[ScreenStatus.highRisk], contains('Tinggi'));
      expect(
        StatusMapping.labels[ScreenStatus.invalid],
        contains('Tidak Valid'),
      );
    });

    test('descriptions do not contain diagnosis language', () {
      for (final desc in StatusMapping.descriptions.values) {
        expect(desc.toLowerCase(), isNot(contains('positif')));
        expect(desc.toLowerCase(), isNot(contains('menderita')));
        expect(desc.toLowerCase(), isNot(contains('pasti sehat')));
      }
    });

    test('invalid status always returns invalid label', () {
      expect(
        StatusMapping.safeLabelFor(ScreenStatus.invalid),
        'Pemeriksaan Tidak Valid',
      );
    });

    test('safeLabelFor returns same as labelFor for non-invalid', () {
      expect(
        StatusMapping.safeLabelFor(ScreenStatus.healthy),
        StatusMapping.labelFor(ScreenStatus.healthy),
      );
    });
  });
}
