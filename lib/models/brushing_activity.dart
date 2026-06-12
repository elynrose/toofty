/// Model representing a brushing activity (replaces enum for dynamic management)
class BrushingActivityModel {
  final String id;
  final String positionName;
  final String instruction;
  final String videoFileName;
  final int duration;

  BrushingActivityModel({
    required this.id,
    required this.positionName,
    required this.instruction,
    required this.videoFileName,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'positionName': positionName,
      'instruction': instruction,
      'videoFileName': videoFileName,
      'duration': duration,
    };
  }

  factory BrushingActivityModel.fromJson(Map<String, dynamic> json) {
    return BrushingActivityModel(
      id: json['id'] as String,
      positionName: json['positionName'] as String,
      instruction: json['instruction'] as String,
      videoFileName: json['videoFileName'] as String,
      duration: json['duration'] as int,
    );
  }

  BrushingActivityModel copyWith({
    String? id,
    String? positionName,
    String? instruction,
    String? videoFileName,
    int? duration,
  }) {
    return BrushingActivityModel(
      id: id ?? this.id,
      positionName: positionName ?? this.positionName,
      instruction: instruction ?? this.instruction,
      videoFileName: videoFileName ?? this.videoFileName,
      duration: duration ?? this.duration,
    );
  }

  static List<BrushingActivityModel> defaultActivities() {
    return [
      BrushingActivityModel(
        id: 'front',
        positionName: 'Front',
        instruction: 'Brush the Front',
        videoFileName: 'front',
        duration: 120,
      ),
      BrushingActivityModel(
        id: 'leftSide',
        positionName: 'Left Side',
        instruction: 'Brush the Left Side',
        videoFileName: 'left',
        duration: 60,
      ),
      BrushingActivityModel(
        id: 'rightSide',
        positionName: 'Right Side',
        instruction: 'Brush the Right Side',
        videoFileName: 'right',
        duration: 60,
      ),
      BrushingActivityModel(
        id: 'inside',
        positionName: 'Inside',
        instruction: 'Brush the Inside',
        videoFileName: 'inside',
        duration: 60,
      ),
      BrushingActivityModel(
        id: 'topBottom',
        positionName: 'Top and Bottom',
        instruction: 'Brush the Top and Bottom',
        videoFileName: 'top_bottom',
        duration: 60,
      ),
      BrushingActivityModel(
        id: 'tongue',
        positionName: 'Tongue',
        instruction: 'Brush the Tongue',
        videoFileName: 'tongue',
        duration: 30,
      ),
    ];
  }
}
