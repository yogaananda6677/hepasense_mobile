import 'dart:async';

import '../data/push_device_repository.dart';
import '../data/push_service.dart';
import '../domain/push_signal.dart';

class PushCoordinator {
  PushCoordinator({
    required PushService service,
    required PushDeviceRepository repository,
    required Future<void> Function() refreshNotifications,
    required void Function(PushSignal signal) onOpen,
  }) : this._(service, repository, refreshNotifications, onOpen);

  PushCoordinator._(
    this._service,
    this._repository,
    this._refreshNotifications,
    this._onOpen,
  );

  final PushService _service;
  final PushDeviceRepository _repository;
  final Future<void> Function() _refreshNotifications;
  final void Function(PushSignal signal) _onOpen;

  StreamSubscription<PushSignal>? _foregroundSubscription;
  StreamSubscription<PushSignal>? _openedSubscription;
  bool _initialized = false;
  bool _authenticated = false;
  bool _syncInFlight = false;
  bool _permissionRequested = false;
  String? _registeredFid;
  int? _pushDeviceId;
  PushSignal? _pendingInitial;

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      if (!await _service.initialize()) return false;
      _initialized = true;
      _foregroundSubscription = _service.foregroundSignals.listen((_) {
        _refreshNotifications();
      });
      _openedSubscription = _service.openedSignals.listen(_handleOpen);
      _pendingInitial = await _service.getInitialSignal();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> onAuthenticated() async {
    _authenticated = true;
    if (!await initialize()) return;
    if (!_permissionRequested) {
      _permissionRequested = true;
      await _service.requestPermission();
    }
    await syncInstallation();
    final pending = _pendingInitial;
    _pendingInitial = null;
    if (pending != null && _authenticated) _onOpen(pending);
  }

  Future<void> syncInstallation() async {
    if (!_authenticated || !_initialized || _syncInFlight) return;
    _syncInFlight = true;
    try {
      final fid = await _service.getInstallationId();
      if (fid == null || fid.isEmpty || fid == _registeredFid) return;
      final registration = await _repository.register(fid);
      _registeredFid = fid;
      _pushDeviceId = registration.id;
    } catch (_) {
      // Push is optional. Core authenticated flows must remain available.
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> onLogout() async {
    _authenticated = false;
    _pendingInitial = null;
    final deviceId = _pushDeviceId;
    _pushDeviceId = null;
    _registeredFid = null;
    if (deviceId == null) return;
    try {
      await _repository.revoke(deviceId);
    } catch (_) {
      // Backend reassignment on the next login remains the safety backstop.
    }
  }

  void _handleOpen(PushSignal signal) {
    if (_authenticated) {
      _onOpen(signal);
    } else {
      _pendingInitial = signal;
    }
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
