import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/monster_catalog.dart';
import '../models/reward.dart';

class AppUserRecord {
  const AppUserRecord({
    required this.uid,
    required this.email,
    required this.admin,
    required this.disabled,
    this.createdAt,
    this.lastSeenAt,
  });

  final String uid;
  final String email;
  final bool admin;
  final bool disabled;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  factory AppUserRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUserRecord(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      admin: data['admin'] as bool? ?? false,
      disabled: data['disabled'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSeenAt: (data['lastSeenAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Firestore-backed admin operations and global app configuration.
class AdminService {
  AdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _configCollection = 'config';
  static const _defaultsDoc = 'defaults';

  DocumentReference<Map<String, dynamic>> get _defaultsRef =>
      _firestore.collection(_configCollection).doc(_defaultsDoc);

  Future<bool> isUserAdmin(String uid) async {
    final doc =
        await _firestore.collection(_usersCollection).doc(uid).get();
    return doc.data()?['admin'] as bool? ?? false;
  }

  Future<void> registerCurrentUser(User user) async {
    final ref = _firestore.collection(_usersCollection).doc(user.uid);
    final snapshot = await ref.get();
    final now = FieldValue.serverTimestamp();

    if (snapshot.exists) {
      await ref.update({
        'email': user.email ?? '',
        'lastSeenAt': now,
      });
      return;
    }

    await ref.set({
      'email': user.email ?? '',
      'admin': false,
      'disabled': false,
      'createdAt': now,
      'lastSeenAt': now,
    });
  }

  Future<bool> isUserDisabled(String uid) async {
    final doc =
        await _firestore.collection(_usersCollection).doc(uid).get();
    return doc.data()?['disabled'] as bool? ?? false;
  }

  Stream<List<AppUserRecord>> watchUsers() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('email')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(AppUserRecord.fromDoc).toList(growable: false),
        );
  }

  Future<void> _requireAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !await isUserAdmin(uid)) {
      throw StateError('Admin access required');
    }
  }

  Future<void> setUserDisabled(String uid, bool disabled) async {
    await _requireAdmin();
    await _firestore.collection(_usersCollection).doc(uid).update({
      'disabled': disabled,
    });
  }

  Future<void> setUserAdmin(String uid, bool admin) async {
    await _requireAdmin();
    await _firestore.collection(_usersCollection).doc(uid).update({
      'admin': admin,
    });
  }

  Future<List<Reward>> fetchDefaultRewards() async {
    final doc = await _defaultsRef.get();
    final rewards = doc.data()?['defaultRewards'];
    if (rewards is! List) return [];

    return rewards
        .whereType<Map<String, dynamic>>()
        .map(Reward.fromJson)
        .toList();
  }

  Future<void> saveDefaultRewards(List<Reward> rewards) async {
    await _requireAdmin();
    await _defaultsRef.set(
      {'defaultRewards': rewards.map((r) => r.toJson()).toList()},
      SetOptions(merge: true),
    );
  }

  Future<List<MonsterInfo>> fetchMonsters() async {
    final all = await _fetchAllMonstersRaw();
    return all.where((m) => m.enabled).toList();
  }

  Future<List<MonsterInfo>> fetchAllMonstersConfig() async {
    final all = await _fetchAllMonstersRaw();
    if (all.isNotEmpty) return all;
    return MonsterCatalog.builtInMonsters;
  }

  Future<List<MonsterInfo>> _fetchAllMonstersRaw() async {
    final doc = await _defaultsRef.get();
    final monsters = doc.data()?['monsters'];
    if (monsters is! List) return [];

    return monsters
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => MonsterInfo(
            id: json['id'] as String,
            name: json['name'] as String,
            enabled: json['enabled'] as bool? ?? true,
          ),
        )
        .toList();
  }

  Future<void> saveMonsters(List<MonsterInfo> monsters) async {
    await _requireAdmin();
    await _defaultsRef.set(
      {
        'monsters': monsters
            .map(
              (m) => {
                'id': m.id,
                'name': m.name,
                'enabled': m.enabled,
              },
            )
            .toList(),
      },
      SetOptions(merge: true),
    );
  }
}
