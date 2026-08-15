import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../domain/push_signal.dart';

abstract interface class PushService {
  Future<bool> initialize();
  Future<String?> getInstallationId();
  Future<PushPermission> requestPermission();
  Stream<PushSignal> get foregroundSignals;
  Stream<PushSignal> get openedSignals;
  Future<PushSignal?> getInitialSignal();
}

/// Safe adapter used until genuine Firebase Android configuration is supplied.
/// It never prompts, contacts Firebase, or claims push availability.
class UnconfiguredPushService implements PushService {
  const UnconfiguredPushService();

  @override
  Future<bool> initialize() async => false;

  @override
  Future<String?> getInstallationId() async => null;

  @override
  Future<PushPermission> requestPermission() async =>
      PushPermission.unavailable;

  @override
  Stream<PushSignal> get foregroundSignals => const Stream.empty();

  @override
  Stream<PushSignal> get openedSignals => const Stream.empty();

  @override
  Future<PushSignal?> getInitialSignal() async => null;
}

class FirebasePushService implements PushService {
  FirebasePushService({
    required Future<void> Function() initializeFirebase,
    required Future<String> Function() obtainInstallationId,
    required Future<PushPermission> Function() obtainPermission,
    required Stream<Map<String, dynamic>> Function() foregroundData,
    required Stream<Map<String, dynamic>> Function() openedData,
    required Future<Map<String, dynamic>?> Function() obtainInitialData,
  }) : this._(
         initializeFirebase,
         obtainInstallationId,
         obtainPermission,
         foregroundData,
         openedData,
         obtainInitialData,
       );

  FirebasePushService._(
    this._initializeFirebase,
    this._obtainInstallationId,
    this._obtainPermission,
    this._foregroundData,
    this._openedData,
    this._obtainInitialData,
  );

  factory FirebasePushService.production() => FirebasePushService(
    initializeFirebase: () async {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    },
    obtainInstallationId: () => FirebaseInstallations.instance.getId(),
    obtainPermission: () async {
      final settings = await FirebaseMessaging.instance.requestPermission();
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.authorized,
        AuthorizationStatus.denied => PushPermission.denied,
        _ => PushPermission.unavailable,
      };
    },
    foregroundData: () =>
        FirebaseMessaging.onMessage.map((message) => message.data),
    openedData: () =>
        FirebaseMessaging.onMessageOpenedApp.map((message) => message.data),
    obtainInitialData: () async =>
        (await FirebaseMessaging.instance.getInitialMessage())?.data,
  );

  final Future<void> Function() _initializeFirebase;
  final Future<String> Function() _obtainInstallationId;
  final Future<PushPermission> Function() _obtainPermission;
  final Stream<Map<String, dynamic>> Function() _foregroundData;
  final Stream<Map<String, dynamic>> Function() _openedData;
  final Future<Map<String, dynamic>?> Function() _obtainInitialData;
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      await _initializeFirebase();
      _initialized = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getInstallationId() async {
    if (!_initialized) return null;
    try {
      return await _obtainInstallationId();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PushPermission> requestPermission() async {
    if (!_initialized) return PushPermission.unavailable;
    try {
      return await _obtainPermission();
    } catch (_) {
      return PushPermission.unavailable;
    }
  }

  @override
  Stream<PushSignal> get foregroundSignals =>
      _initialized ? _validSignals(_foregroundData()) : const Stream.empty();

  @override
  Stream<PushSignal> get openedSignals =>
      _initialized ? _validSignals(_openedData()) : const Stream.empty();

  @override
  Future<PushSignal?> getInitialSignal() async {
    if (!_initialized) return null;
    try {
      final data = await _obtainInitialData();
      return data == null ? null : PushSignal.fromData(data);
    } catch (_) {
      return null;
    }
  }

  Stream<PushSignal> _validSignals(Stream<Map<String, dynamic>> source) =>
      source
          .map(PushSignal.fromData)
          .where((signal) => signal != null)
          .cast<PushSignal>();
}
