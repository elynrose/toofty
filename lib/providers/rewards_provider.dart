import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reward.dart';
import '../models/reward_claim.dart';

class RewardsProvider with ChangeNotifier {
  List<Reward> _rewards = [];
  List<RewardClaim> _claims = [];
  bool _isInitialized = false;

  List<Reward> get rewards => List.unmodifiable(_rewards);
  List<RewardClaim> get claims => List.unmodifiable(_claims);
  bool get isInitialized => _isInitialized;

  Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final rewardsJson = prefs.getString('rewards');
      if (rewardsJson != null) {
        final decoded = jsonDecode(rewardsJson) as List<dynamic>;
        _rewards = decoded
            .map((json) => Reward.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final claimsJson = prefs.getString('reward_claims');
      if (claimsJson != null) {
        final decoded = jsonDecode(claimsJson) as List<dynamic>;
        _claims = decoded
            .map((json) => RewardClaim.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading rewards: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveRewards() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rewards',
      jsonEncode(_rewards.map((r) => r.toJson()).toList()),
    );
  }

  Future<void> _saveClaims() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reward_claims',
      jsonEncode(_claims.map((c) => c.toJson()).toList()),
    );
  }

  Future<String?> _persistPhoto(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final rewardsDir = Directory('${dir.path}/reward_photos');
      if (!await rewardsDir.exists()) {
        await rewardsDir.create(recursive: true);
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '${rewardsDir.path}/$fileName';
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
