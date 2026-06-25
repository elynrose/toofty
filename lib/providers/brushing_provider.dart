import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/brushing_settings.dart';
import '../services/tenant_storage.dart';

/// Provider to manage brushing settings and state
class BrushingProvider with ChangeNotifier {
  BrushingSettings _settings = BrushingSettings();
  bool _isInitialized = false;
  String? _tenantId;

  BrushingSettings get settings => _settings;
  bool get isInitialized => _isInitialized;
  String? get tenantId => _tenantId;

  Future<void> bindTenant(String? userId) async {
    if (_tenantId == userId && _isInitialized) return;

    _tenantId = userId;
    _settings = BrushingSettings();
    _isInitialized = false;
    notifyListeners();

    if (userId == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    await loadSettings();
  }

  TenantStorage? get _storage =>
      _tenantId == null ? null : TenantStorage(_tenantId!);

  /// Load settings from shared preferences
  Future<void> loadSettings() async {
    final storage = _storage;
    if (storage == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await TenantStorage.migrateLegacyString(
        userId: _tenantId!,
        legacyKey: 'brushing_settings',
        tenantKeyName: 'brushing_settings',
      );

      final settingsJson = prefs.getString(storage.prefKey('brushing_settings'));
      
      if (settingsJson != null) {
        _settings = BrushingSettings.fromJson(
          json.decode(settingsJson) as Map<String, dynamic>,
        );
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Save settings to shared preferences (persists to phone storage)
  Future<bool> saveSettings(BrushingSettings newSettings) async {
    final storage = _storage;
    if (storage == null) return false;

    try {
      _settings = newSettings;
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(
        storage.prefKey('brushing_settings'),
        json.encode(_settings.toJson()),
      );
      
      if (success) {
        debugPrint('Settings saved successfully to phone storage');
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to save settings');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving settings: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get time for a specific activity
  int getTimeForActivity(BrushingActivity activity) {
    switch (activity) {
      case BrushingActivity.front:
        return _settings.frontTime;
      case BrushingActivity.leftSide:
        return _settings.leftSideTime;
      case BrushingActivity.rightSide:
        return _settings.rightSideTime;
      case BrushingActivity.inside:
        return _settings.insideTime;
      case BrushingActivity.topBottom:
        return _settings.topBottomTime;
      case BrushingActivity.tongue:
        return _settings.tongueTime;
    }
  }
}
