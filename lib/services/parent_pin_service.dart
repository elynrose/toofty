import 'package:shared_preferences/shared_preferences.dart';

import 'tenant_storage.dart';

/// Stores a hashed parent PIN per Firebase user (tenant).
class ParentPinService {
  static String _hashPin(String pin) {
    var hash = 0;
    for (final unit in pin.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

  Future<bool> hasPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = TenantStorage(userId).prefKey('parent_pin_hash');
    return prefs.getString(key) != null;
  }

  Future<bool> verifyPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final key = TenantStorage(userId).prefKey('parent_pin_hash');
    final stored = prefs.getString(key);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<void> setPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final key = TenantStorage(userId).prefKey('parent_pin_hash');
    await prefs.setString(key, _hashPin(pin));
  }

  Future<void> clearPin(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = TenantStorage(userId).prefKey('parent_pin_hash');
    await prefs.remove(key);
  }
}
