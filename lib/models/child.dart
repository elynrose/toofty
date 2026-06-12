import 'package:intl/intl.dart';

import 'brushing_settings.dart';
import 'child_gender.dart';
import 'monster_catalog.dart';

/// Model representing a child user in the app
class Child {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final ChildGender gender;
  final String monsterId;
  final int points;
  final BrushingSettings brushingSettings;

  Child({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.gender = ChildGender.none,
    this.monsterId = MonsterCatalog.defaultId,
    this.points = 0,
    BrushingSettings? brushingSettings,
  }) : brushingSettings = brushingSettings ?? BrushingSettings.defaultSettings();

  String get formattedDateOfBirth => DateFormat.yMMMd().format(dateOfBirth);

  String get monsterName => MonsterCatalog.infoFor(monsterId).name;

  /// Convert Child to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender.toJson(),
      'monsterId': monsterId,
      'points': points,
      'brushingSettings': brushingSettings.toJson(),
    };
  }

  /// Create Child from JSON
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: _parseDateOfBirth(json),
      gender: ChildGender.fromJson(json['gender'] as String?),
      monsterId: MonsterCatalog.normalizeMonsterId(json['monsterId'] as String?),
      points: json['points'] as int? ?? 0,
      brushingSettings: json['brushingSettings'] != null
          ? BrushingSettings.fromJson(json['brushingSettings'])
          : BrushingSettings.defaultSettings(),
    );
  }

  static DateTime _parseDateOfBirth(Map<String, dynamic> json) {
    final stored = json['dateOfBirth'];
    if (stored is String && stored.isNotEmpty) {
      return DateTime.parse(stored);
    }

    final now = DateTime.now();
    final legacyAge = json['age'];
    if (legacyAge is int) {
      return DateTime(now.year - legacyAge, now.month, now.day);
    }

    return DateTime(now.year - 5, now.month, now.day);
  }

  /// Create a copy of Child with modified fields
  Child copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    ChildGender? gender,
    String? monsterId,
    int? points,
    BrushingSettings? brushingSettings,
  }) {
    return Child(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      monsterId: monsterId ?? this.monsterId,
      points: points ?? this.points,
      brushingSettings: brushingSettings ?? this.brushingSettings,
    );
  }
}
