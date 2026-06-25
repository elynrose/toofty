import 'package:flutter/foundation.dart';

import '../services/parent_pin_service.dart';

/// Parent PIN state and short-lived unlock session after verification.
class ParentPinProvider extends ChangeNotifier {
  ParentPinProvider({ParentPinService? service})
      : _service = service ?? ParentPinService();

  final ParentPinService _service;

  String? _tenantId;
  bool _hasPin = false;
  bool _loaded = false;
  DateTime? _unlockedUntil;

  static const _unlockDuration = Duration(minutes: 5);

  bool get isLoaded => _loaded;
  bool get hasPin => _hasPin;
  bool get isUnlocked =>
      _unlockedUntil != null && DateTime.now().isBefore(_unlockedUntil!);

  Future<void> bindTenant(String? userId) async {
    _tenantId = userId;
    _hasPin = false;
    _loaded = false;
    _unlockedUntil = null;
    notifyListeners();

    if (userId == null) {
      _loaded = true;
      notifyListeners();
      return;
    }

    _hasPin = await _service.hasPin(userId);
    _loaded = true;
    notifyListeners();
  }

  void lock() {
    _unlockedUntil = null;
    notifyListeners();
  }

  void unlock() {
    _unlockedUntil = DateTime.now().add(_unlockDuration);
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final userId = _tenantId;
    if (userId == null) return false;

    final ok = await _service.verifyPin(userId, pin);
    if (ok) unlock();
    return ok;
  }

  Future<bool> setPin(String pin) async {
    final userId = _tenantId;
    if (userId == null) return false;

    await _service.setPin(userId, pin);
    _hasPin = true;
    unlock();
    notifyListeners();
    return true;
  }

  Future<bool> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final userId = _tenantId;
    if (userId == null) return false;

    if (!await _service.verifyPin(userId, currentPin)) return false;
    await _service.setPin(userId, newPin);
    unlock();
    return true;
  }
}
