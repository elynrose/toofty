import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child.dart';
import '../models/child_gender.dart';
import '../models/monster_catalog.dart';
import '../models/brushing_history.dart';
import '../models/brushing_settings.dart';
import '../services/tenant_storage.dart';

/// Provider to manage children and their brushing history
class ChildProvider with ChangeNotifier {
  List<Child> _children = [];
  Child? _currentChild;
  Map<String, BrushingHistory> _history = {};
  bool _isInitialized = false;
  String? _tenantId;

  List<Child> get children => _children;
  Child? get currentChild => _currentChild;
  bool get isInitialized => _isInitialized;
  String? get tenantId => _tenantId;

  /// Switch to a user's isolated data set (or clear when signing out).
  Future<void> bindTenant(String? userId) async {
    if (_tenantId == userId && _isInitialized) return;

    _tenantId = userId;
    _children = [];
    _currentChild = null;
    _history = {};
    _isInitialized = false;
    notifyListeners();

    if (userId == null) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    await loadData();
  }

  TenantStorage? get _storage =>
      _tenantId == null ? null : TenantStorage(_tenantId!);

  /// Load children and history from storage
  Future<void> loadData() async {
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
        legacyKey: 'children',
        tenantKeyName: 'children',
      );
      await TenantStorage.migrateLegacyString(
        userId: _tenantId!,
        legacyKey: 'brushing_history',
        tenantKeyName: 'brushing_history',
      );
      await TenantStorage.migrateLegacyString(
        userId: _tenantId!,
        legacyKey: 'current_child_id',
        tenantKeyName: 'current_child_id',
      );

      final childrenJson = prefs.getString(storage.prefKey('children'));
      if (childrenJson != null) {
        final List<dynamic> decoded = jsonDecode(childrenJson);
        _children = decoded.map((json) => Child.fromJson(json)).toList();
      }

      // Load brushing history
      final historyJson = prefs.getString(storage.prefKey('brushing_history'));
      if (historyJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(historyJson);
        _history = decoded.map(
          (key, value) => MapEntry(key, BrushingHistory.fromJson(value)),
        );
      }

      // Set current child if available
      final currentChildId = prefs.getString(storage.prefKey('current_child_id'));
      if (currentChildId != null && _children.isNotEmpty) {
        try {
          _currentChild = _children.firstWhere(
            (child) => child.id == currentChildId,
          );
        } catch (e) {
          // Child not found, default to first
          _currentChild = _children.first;
        }
      } else if (_children.isNotEmpty) {
        _currentChild = _children.first;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading child data: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Save children to storage
  Future<void> _saveChildren() async {
    final storage = _storage;
    if (storage == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final childrenJson = jsonEncode(_children.map((c) => c.toJson()).toList());
      await prefs.setString(storage.prefKey('children'), childrenJson);
    } catch (e) {
      debugPrint('Error saving children: $e');
    }
  }

  /// Save brushing history to storage
  Future<void> _saveHistory() async {
    final storage = _storage;
    if (storage == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _history.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString(storage.prefKey('brushing_history'), historyJson);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Add a new child
  Future<void> addChild(
    String name,
    DateTime dateOfBirth, {
    ChildGender gender = ChildGender.none,
    String monsterId = MonsterCatalog.defaultId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final child = Child(
      id: id,
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      monsterId: monsterId,
      points: 0,
    );
    _children.add(child);
    
    // Set as current child if it's the first one
    if (_children.length == 1) {
      _currentChild = child;
      await _setCurrentChild(child.id);
    }
    
    await _saveChildren();
    notifyListeners();
  }

  /// Update a child's profile fields.
  Future<void> updateChildProfile({
    required String childId,
    String? name,
    DateTime? dateOfBirth,
    ChildGender? gender,
    String? monsterId,
  }) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index == -1) return;

    _children[index] = _children[index].copyWith(
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      monsterId: monsterId,
    );

    if (_currentChild?.id == childId) {
      _currentChild = _children[index];
    }

    await _saveChildren();
    notifyListeners();
  }

  /// Set the current active child
  Future<void> setCurrentChild(Child child) async {
    _currentChild = child;
    await _setCurrentChild(child.id);
    notifyListeners();
  }

  Future<void> _setCurrentChild(String childId) async {
    final storage = _storage;
    if (storage == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storage.prefKey('current_child_id'), childId);
    } catch (e) {
      debugPrint('Error setting current child: $e');
    }
  }

  /// Spend points when a child claims a reward. Returns false if insufficient.
  Future<bool> spendPoints(String childId, int points) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index == -1 || _children[index].points < points) {
      return false;
    }

    _children[index] = _children[index].copyWith(
      points: _children[index].points - points,
    );

    if (_currentChild?.id == childId) {
      _currentChild = _children[index];
    }

    await _saveChildren();
    notifyListeners();
    return true;
  }

  /// Award points to a child for completing a session
  Future<void> awardPoints(String childId, int points) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _children[index] = _children[index].copyWith(
        points: _children[index].points + points,
      );
      
      // Update current child if it's the same
      if (_currentChild?.id == childId) {
        _currentChild = _children[index];
      }
      
      await _saveChildren();
      notifyListeners();
    }
  }

  /// Set a child's points directly (parent adjustment).
  Future<void> setPoints(String childId, int points) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index == -1) return;

    _children[index] = _children[index].copyWith(
      points: points.clamp(0, 999999),
    );

    if (_currentChild?.id == childId) {
      _currentChild = _children[index];
    }

    await _saveChildren();
    notifyListeners();
  }

  /// Get count of brushing sessions today for a child
  int getTodaySessionCount(String childId) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    int count = 0;
    for (var entry in _history.values) {
      if (entry.childId == childId && 
          entry.date.year == normalizedToday.year &&
          entry.date.month == normalizedToday.month &&
          entry.date.day == normalizedToday.day &&
          entry.completed) {
        count++;
      }
    }
    return count;
  }

  /// Check if child can brush today (max 2 sessions per day)
  bool canBrushToday(String childId) {
    return getTodaySessionCount(childId) < 2;
  }

  /// Record a completed brushing session (max 2 per day)
  Future<bool> recordBrushingSession(String childId, {DateTime? date}) async {
    // Check if child has already brushed twice today
    if (!canBrushToday(childId)) {
      debugPrint('Child $childId has already brushed twice today');
      return false;
    }

    final sessionDate = date ?? DateTime.now();
    // Normalize to start of day for consistency
    final normalizedDate = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );

    // Create a unique key for multiple sessions per day
    final sessionKey = '$childId-${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}-${DateTime.now().millisecondsSinceEpoch}';

    final history = BrushingHistory(
      childId: childId,
      date: sessionDate, // Use actual session time for uniqueness
      completed: true,
    );

    _history[sessionKey] = history;
    await _saveHistory();
    
    // Award points
    await awardPoints(childId, 10);
    
    return true;
  }

  /// Get brushing history for a specific child and date
  bool isBrushingCompleted(String childId, DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final history = BrushingHistory(
      childId: childId,
      date: normalizedDate,
      completed: false,
    );
    return _history[history.key]?.completed ?? false;
  }

  /// Get brushing history for a child for the current week
  List<BrushingHistory> getWeeklyHistory(String childId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    final weekDates = List.generate(7, (index) {
      return DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      );
    });

    return weekDates.map((date) {
      // Check if any sessions exist for this day
      final hasSession = _history.values.any((entry) {
        return entry.childId == childId &&
            entry.date.year == date.year &&
            entry.date.month == date.month &&
            entry.date.day == date.day &&
            entry.completed;
      });

      return BrushingHistory(
        childId: childId,
        date: date,
        completed: hasSession,
      );
    }).toList();
  }

  /// Clear all sessions for a specific child on a specific date
  Future<void> clearSessionsForDate(String childId, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    // Find and remove all sessions for this child on this date
    final keysToRemove = <String>[];
    _history.forEach((key, value) {
      if (value.childId == childId &&
          value.date.year == normalizedDate.year &&
          value.date.month == normalizedDate.month &&
          value.date.day == normalizedDate.day) {
        keysToRemove.add(key);
      }
    });

    // Remove the sessions
    for (var key in keysToRemove) {
      _history.remove(key);
    }

    // Deduct points (10 points per session removed)
    if (keysToRemove.isNotEmpty) {
      final pointsToDeduct = keysToRemove.length * 10;
      final childIndex = _children.indexWhere((c) => c.id == childId);
      if (childIndex != -1) {
        _children[childIndex] = _children[childIndex].copyWith(
          points: (_children[childIndex].points - pointsToDeduct).clamp(0, double.infinity).toInt(),
        );
        
        // Update current child if it's the same
        if (_currentChild?.id == childId) {
          _currentChild = _children[childIndex];
        }
      }
    }

    await _saveHistory();
    await _saveChildren();
    notifyListeners();
    
    debugPrint('Cleared ${keysToRemove.length} session(s) for child $childId on ${normalizedDate.toIso8601String()}');
  }

  /// Update brushing settings for a specific child
  Future<void> updateChildSettings(String childId, BrushingSettings settings) async {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _children[index] = _children[index].copyWith(
        brushingSettings: settings,
      );
      
      // Update current child if it's the same
      if (_currentChild?.id == childId) {
        _currentChild = _children[index];
      }
      
      await _saveChildren();
      notifyListeners();
    }
  }

  /// Get brushing settings for a specific child
  BrushingSettings getChildSettings(String childId) {
    final child = _children.firstWhere(
      (c) => c.id == childId,
      orElse: () => _children.isNotEmpty
          ? _children.first
          : Child(id: '', name: '', dateOfBirth: DateTime(2020, 1, 1)),
    );
    return child.brushingSettings;
  }

  /// Delete a child
  Future<void> deleteChild(String childId) async {
    _children.removeWhere((c) => c.id == childId);
    
    // Remove history for this child
    _history.removeWhere((key, value) => value.childId == childId);
    
    // Update current child if needed
    if (_currentChild?.id == childId) {
      _currentChild = _children.isNotEmpty ? _children.first : null;
      if (_currentChild != null) {
        await _setCurrentChild(_currentChild!.id);
      }
    }
    
    await _saveChildren();
    await _saveHistory();
    notifyListeners();
  }
}
