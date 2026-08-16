import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 12 Android release configuration', () {
    test('main manifest has final label and minimum justified permissions', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:label="HepaSense"'));
      expect(manifest, contains('android.permission.INTERNET'));
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, isNot(contains('android.permission.CAMERA')));
      expect(manifest, isNot(contains('android.permission.RECORD_AUDIO')));
      expect(
        manifest,
        isNot(contains('android.permission.ACCESS_FINE_LOCATION')),
      );
      expect(manifest, isNot(contains('android.permission.READ_CONTACTS')));
    });

    test('production manifest explicitly rejects cleartext traffic', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:usesCleartextTraffic="false"'));
    });

    test('cleartext emulator backend is isolated to debug builds', () {
      final manifest = File(
        'android/app/src/debug/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:usesCleartextTraffic="true"'));
      expect(
        manifest,
        contains('tools:replace="android:usesCleartextTraffic"'),
      );
    });

    test('Android namespace and application ID are final', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('namespace = "com.yogaananda.hepasense"'));
      expect(gradle, contains('applicationId = "com.yogaananda.hepasense"'));
      expect(gradle, isNot(contains('com.example.hepasense_mobile')));
    });

    test('Google Services Android client matches the final package', () {
      final config =
          jsonDecode(
                File('android/app/google-services.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final clients = config['client'] as List<dynamic>;
      final packages = clients
          .map(
            (client) =>
                ((client as Map<String, dynamic>)['client_info']
                        as Map<String, dynamic>)['android_client_info']
                    as Map<String, dynamic>,
          )
          .map((android) => android['package_name'])
          .toSet();
      expect(packages, contains('com.yogaananda.hepasense'));
    });
  });
}
