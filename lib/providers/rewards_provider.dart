import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/default_rewards_catalog.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import '../services/admin_service.dart';
import '../services/tenant_storage.dart';

class RewardsProvider with ChangeNotifier {
  List<Reward> _rewards = [];
  List<RewardClaim> _claims = [];
  bool _isInitialized = false;
  String? _tenantId;

  List<Reward> get rewards => List.unmodifiable(_rewards);
  List<RewardClaim> get claims => List.unmodifiable(_claims);
  bool get isInitialized => _isInitialized;
  String? get tenantId => _tenantId;

  Future<void> bindTenant(String? userId) async {
    if (_tenantId == userId && _isInitialized) return;

    _tenantId = userId;
    _rewards = [];
    _claims = [];
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
        legacyKey: 'rewards',
        tenantKeyName: 'rewards',
      );
      await TenantStorage.migrateLegacyString(
        userId: _tenantId!,
        legacyKey: 'reward_claims',
        tenantKeyName: 'reward_claims',
      );

      final rewardsJson = prefs.getString(storage.prefKey('rewards'));
      if (rewardsJson != null) {
        final decoded = jsonDecode(rewardsJson) as List<dynamic>;
        _rewards = decoded
            .map((json) => Reward.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final claimsJson = prefs.getString(storage.prefKey('reward_claims'));
      if (claimsJson != null) {
        final decoded = jsonDecode(claimsJson) as List<dynamic>;
        _claims = decoded
            .map((json) => RewardClaim.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      if (_rewards.isEmpty) {
        await _seedDefaultRewards();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rewards: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _seedDefaultRewards() async {
    try {
      final remote = await AdminService().fetchDefaultRewards();
      _rewards =
          remote.isNotEmpty ? remote : DefaultRewardsCatalog.rewards();
    } catch (e) {
      debugPrint('Using bundled default rewards: $e');
      _rewards = DefaultRewardsCatalog.rewards();
    }
    await _saveRewards();
    debugPrint('Seeded ${_rewards.length} default rewards');
  }

  Future<void> _saveRewards() async {
    final storage = _storage;
    if (storage == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storage.prefKey('rewards'),
      jsonEncode(_rewards.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _saveClaims() async {
    final storage = _storage;
    if (storage == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storage.prefKey('reward_claims'),
      jsonEncode(_claims.map((c) => c.toJson()).toList()),
    );
  }

  Future<String?> _persistPhoto(String sourcePath) async {
    final storage = _storage;
    if (storage == null) return null;

    try {
      final rewardsDirPath = await storage.directory('reward_photos');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '$rewardsDirPath/$fileName';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Error saving reward photo: $e');
      return null;
    }
  }

  Future<void> addReward({
    required String name,
    String? photoPath,
    required int pointsRequired,
    required double price,
  }) async {
    String? storedPhotoPath;
    if (photoPath != null) {
      storedPhotoPath = await _persistPhoto(photoPath);
    }

    final reward = Reward(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      photoPath: storedPhotoPath,
      pointsRequired: pointsRequired,
      price: price,
    );
    _rewards.add(reward);
    await _saveRewards();
    notifyListeners();
  }

  Future<void> updateReward(Reward reward, {String? newPhotoPath}) async {
    final index = _rewards.indexWhere((r) => r.id == reward.id);
    if (index == -1) return;

    String? photoPath = reward.photoPath;
    if (newPhotoPath != null) {
      photoPath = await _persistPhoto(newPhotoPath);
    }

    _rewards[index] = reward.copyWith(photoPath: photoPath);
    await _saveRewards();
    notifyListeners();
  }

  Future<void> deleteReward(String rewardId) async {
    final reward = _rewards.firstWhere((r) => r.id == rewardId);
    if (reward.photoPath != null) {
      try {
        final file = File(reward.photoPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting reward photo: $e');
      }
    }
    _rewards.removeWhere((r) => r.id == rewardId);
    await _saveRewards();
    notifyListeners();
  }

  Future<RewardClaim?> recordClaim({
    required String childId,
    required String childName,
    required Reward reward,
  }) async {
    final claim = RewardClaim(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: childId,
      childName: childName,
      rewardId: reward.id,
      rewardName: reward.name,
      pointsSpent: reward.pointsRequired,
      price: reward.price,
      claimedAt: DateTime.now(),
    );
    _claims.insert(0, claim);
    await _saveClaims();
    notifyListeners();
    return claim;
  }

  List<RewardClaim> claimsForChild(String childId) {
    return _claims.where((c) => c.childId == childId).toList();
  }
}
