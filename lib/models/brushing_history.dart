/// Model representing a brushing session history entry
class BrushingHistory {
  final String childId;
  final DateTime date;
  final bool completed;

  BrushingHistory({
    required this.childId,
    required this.date,
    required this.completed,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'date': date.toIso8601String(),
      'completed': completed,
    };
  }

  /// Create from JSON
  factory BrushingHistory.fromJson(Map<String, dynamic> json) {
    return BrushingHistory(
      childId: json['childId'] as String,
      date: DateTime.parse(json['date'] as String),
      completed: json['completed'] as bool,
    );
  }

  /// Get a key for this history entry (childId + date)
  String get key {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$childId-$dateStr';
  }
}
