/// Asset paths and metadata for selectable brushing monsters.
/// Monsters live in color folders: assets/images/{id}/, assets/videos/{id}/.
class MonsterCatalog {
  MonsterCatalog._();

  static const String defaultId = 'blue';
  static const String pinkId = 'pink';

  static const List<MonsterInfo> monsters = [
    MonsterInfo(id: 'blue', name: 'Blue Buddy'),
    MonsterInfo(id: 'pink', name: 'Pink Buddy'),
  ];

  /// Maps legacy monster ids and validates stored values.
  static String normalizeMonsterId(String? id) {
    if (id == 'blue' || id == 'pink') return id!;
    return defaultId;
  }

  static bool isAvailable(String monsterId) {
    final id = normalizeMonsterId(monsterId);
    return monsters.any((m) => m.id == id);
  }

  static MonsterInfo infoFor(String id) {
    final normalized = normalizeMonsterId(id);
    return monsters.firstWhere(
      (m) => m.id == normalized,
      orElse: () => monsters.first,
    );
  }

  static String imageAsset(String monsterId) {
    final id = normalizeMonsterId(monsterId);
    return 'assets/images/$id/monster.png';
  }

  static String videoAsset(String monsterId, String fileName) {
    final id = normalizeMonsterId(monsterId);
    final base = fileName.endsWith('.mp4') ? fileName : '$fileName.mp4';
    return 'assets/videos/$id/$base';
  }

  static String intermissionVideo(String monsterId) {
    return videoAsset(monsterId, 'excited');
  }

  static String? celebrationVideo(String monsterId) {
    return videoAsset(monsterId, 'dancing');
  }

  static bool hasMusic(String monsterId) {
    final id = normalizeMonsterId(monsterId);
    return id == 'blue' || id == 'pink';
  }

  static List<String> musicTracks(String monsterId) {
    if (!hasMusic(monsterId)) return const [];
    final id = normalizeMonsterId(monsterId);
    return [
      'music/$id/1.mp3',
      'music/$id/2.mp3',
    ];
  }

  /// Suggested monster for a gender (pink used when assets are added).
  static String monsterForGender(String? genderName) {
    if (genderName == 'female') return pinkId;
    return defaultId;
  }
}

class MonsterInfo {
  final String id;
  final String name;

  const MonsterInfo({required this.id, required this.name});
}
