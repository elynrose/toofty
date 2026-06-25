import 'package:flutter/foundation.dart';

import '../models/default_rewards_catalog.dart';
import '../models/monster_catalog.dart';
import '../models/reward.dart';
import '../services/admin_service.dart';

/// Global app defaults loaded from Firestore (fallback to bundled catalog).
class AppConfigProvider with ChangeNotifier {
  AppConfigProvider({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  final AdminService _adminService;

  List<Reward> _defaultRewards = DefaultRewardsCatalog.rewards();
  List<MonsterInfo> _monsters = MonsterCatalog.builtInMonsters;
  bool _isLoaded = false;

  List<Reward> get defaultRewards => List.unmodifiable(_defaultRewards);
  List<MonsterInfo> get monsters => List.unmodifiable(_monsters);
  bool get isLoaded => _isLoaded;

  Future<void> loadRemoteConfig() async {
    try {
      final remoteRewards = await _adminService.fetchDefaultRewards();
      if (remoteRewards.isNotEmpty) {
        _defaultRewards = remoteRewards;
      }

      final remoteMonsters = await _adminService.fetchMonsters();
      if (remoteMonsters.isNotEmpty) {
        _monsters = remoteMonsters;
        MonsterCatalog.applyMonsters(_monsters);
      }
    } catch (e) {
      debugPrint('Error loading remote app config: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  void applyDefaultRewardsLocally(List<Reward> rewards) {
    _defaultRewards = rewards;
    notifyListeners();
  }

  void applyMonstersLocally(List<MonsterInfo> monsters) {
    _monsters = monsters.where((m) => m.enabled).toList();
    MonsterCatalog.applyMonsters(_monsters);
    notifyListeners();
  }
}
