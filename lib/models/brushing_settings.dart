import 'brushing_activity.dart';

/// Model for custom activity name and instruction (kept for backward compatibility during migration)
class ActivityCustomization {
  final String positionName; // e.g., "Front", "Left Side"
  final String instruction; // e.g., "Brush the Front"

  ActivityCustomization({
    required this.positionName,
    required this.instruction,
  });

  Map<String, dynamic> toJson() {
    return {
      'positionName': positionName,
      'instruction': instruction,
    };
  }

  factory ActivityCustomization.fromJson(Map<String, dynamic> json) {
    return ActivityCustomization(
      positionName: json['positionName'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
    );
  }

  ActivityCustomization copyWith({
    String? positionName,
    String? instruction,
  }) {
    return ActivityCustomization(
      positionName: positionName ?? this.positionName,
      instruction: instruction ?? this.instruction,
    );
  }
}

/// Model class to store brushing time settings for each area
class BrushingSettings {
  // Dynamic list of activities (replaces fixed enum)
  final List<BrushingActivityModel> activities;

  BrushingSettings({
    List<BrushingActivityModel>? activities,
  }) : activities = activities ?? BrushingActivityModel.defaultActivities();
  
  // Legacy getters for backward compatibility (deprecated, use activities list)
  int get frontTime => _getActivityDuration('front') ?? 120;
  int get leftSideTime => _getActivityDuration('leftSide') ?? 60;
  int get rightSideTime => _getActivityDuration('rightSide') ?? 60;
  int get insideTime => _getActivityDuration('inside') ?? 60;
  int get topBottomTime => _getActivityDuration('topBottom') ?? 60;
  int get tongueTime => _getActivityDuration('tongue') ?? 30;
  
  int? _getActivityDuration(String id) {
    try {
      return activities.firstWhere((a) => a.id == id).duration;
    } catch (e) {
      return null;
    }
  }

  /// Default settings factory
  factory BrushingSettings.defaultSettings() {
    return BrushingSettings();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'activities': activities.map((a) => a.toJson()).toList(),
      // Legacy fields for backward compatibility
      'frontTime': frontTime,
      'leftSideTime': leftSideTime,
      'rightSideTime': rightSideTime,
      'insideTime': insideTime,
      'topBottomTime': topBottomTime,
      'tongueTime': tongueTime,
    };
  }

  /// Create from JSON
  factory BrushingSettings.fromJson(Map<String, dynamic> json) {
    List<BrushingActivityModel> activities;
    
    if (json['activities'] != null) {
      // New format: use activities list
      final activitiesJson = json['activities'] as List<dynamic>;
      activities = activitiesJson
          .map((a) => BrushingActivityModel.fromJson(a as Map<String, dynamic>))
          .toList();
    } else {
      // Legacy format: migrate from old enum-based structure
      activities = BrushingActivityModel.defaultActivities();
      // Update durations from legacy fields if available
      if (json['frontTime'] != null) {
        final frontIndex = activities.indexWhere((a) => a.id == 'front');
        if (frontIndex != -1) {
          activities[frontIndex] = activities[frontIndex].copyWith(duration: json['frontTime'] as int);
        }
      }
      if (json['leftSideTime'] != null) {
        final index = activities.indexWhere((a) => a.id == 'leftSide');
        if (index != -1) {
          activities[index] = activities[index].copyWith(duration: json['leftSideTime'] as int);
        }
      }
      if (json['rightSideTime'] != null) {
        final index = activities.indexWhere((a) => a.id == 'rightSide');
        if (index != -1) {
          activities[index] = activities[index].copyWith(duration: json['rightSideTime'] as int);
        }
      }
      if (json['insideTime'] != null) {
        final index = activities.indexWhere((a) => a.id == 'inside');
        if (index != -1) {
          activities[index] = activities[index].copyWith(duration: json['insideTime'] as int);
        }
      }
      if (json['topBottomTime'] != null) {
        final index = activities.indexWhere((a) => a.id == 'topBottom');
        if (index != -1) {
          activities[index] = activities[index].copyWith(duration: json['topBottomTime'] as int);
        }
      }
      if (json['tongueTime'] != null) {
        final index = activities.indexWhere((a) => a.id == 'tongue');
        if (index != -1) {
          activities[index] = activities[index].copyWith(duration: json['tongueTime'] as int);
        }
      }
      
      // Migrate customizations if they exist
      if (json['customizations'] != null) {
        final customizationsJson = json['customizations'] as Map<String, dynamic>;
        for (var i = 0; i < activities.length; i++) {
          final activity = activities[i];
          if (customizationsJson[activity.id] != null) {
            final customization = ActivityCustomization.fromJson(
              customizationsJson[activity.id] as Map<String, dynamic>,
            );
            activities[i] = activity.copyWith(
              positionName: customization.positionName,
              instruction: customization.instruction,
            );
          }
        }
      }
    }
    
    return BrushingSettings(activities: activities);
  }

  /// Create a copy with updated values
  BrushingSettings copyWith({
    List<BrushingActivityModel>? activities,
  }) {
    return BrushingSettings(
      activities: activities ?? List.from(this.activities),
    );
  }

  /// Update an activity in the list
  BrushingSettings updateActivity(int index, BrushingActivityModel activity) {
    final updatedActivities = List<BrushingActivityModel>.from(activities);
    updatedActivities[index] = activity;
    return copyWith(activities: updatedActivities);
  }

  /// Add a new activity
  BrushingSettings addActivity(BrushingActivityModel activity) {
    final updatedActivities = List<BrushingActivityModel>.from(activities);
    updatedActivities.add(activity);
    return copyWith(activities: updatedActivities);
  }

  /// Remove an activity by index
  BrushingSettings removeActivity(int index) {
    final updatedActivities = List<BrushingActivityModel>.from(activities);
    updatedActivities.removeAt(index);
    return copyWith(activities: updatedActivities);
  }

  /// Reorder activities
  BrushingSettings reorderActivities(int oldIndex, int newIndex) {
    final updatedActivities = List<BrushingActivityModel>.from(activities);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedActivities.removeAt(oldIndex);
    updatedActivities.insert(newIndex, item);
    return copyWith(activities: updatedActivities);
  }

  /// Get duration for a specific activity by ID (legacy support)
  int getDurationForActivityId(String activityId) {
    try {
      return activities.firstWhere((a) => a.id == activityId).duration;
    } catch (e) {
      return 60; // Default
    }
  }
}

/// Enum for different brushing activities
enum BrushingActivity {
  front('Brush the Front', 'front'),
  leftSide('Brush the Left Side', 'left'),
  rightSide('Brush the Right Side', 'right'),
  inside('Brush the Inside', 'inside'),
  topBottom('Brush the Top and Bottom', 'top_bottom'),
  tongue('Brush the Tongue', 'tongue');

  final String displayName;
  final String videoFileName;

  const BrushingActivity(this.displayName, this.videoFileName);
}
