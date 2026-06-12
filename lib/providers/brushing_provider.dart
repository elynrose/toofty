import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/brushing_settings.dart';

/// Provider to manage brushing settings and state
class BrushingProvider with ChangeNotifier {
  BrushingSettings _settings = BrushingSettings();
  bool _isInitialized = false;

  BrushingSettings get settings => _settings;
  bool get isInitialized => _isInitialized;

  /// Load settings from shared preferences
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('brushing_settings');
      
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
    try {
      _settings = newSettings;
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(
        'brushing_settings',
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
