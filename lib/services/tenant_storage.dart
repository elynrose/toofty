import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Namespaces local storage and files under a Firebase user id.
class TenantStorage {
  TenantStorage(this.userId);

  final String userId;

  String prefKey(String name) => 'tenant:$userId:$name';

  Future<String> directory(String subdir) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/users/$userId/$subdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Copies legacy global prefs into this tenant once per device, if unused.
  static Future<void> migrateLegacyString({
    required String userId,
    required String legacyKey,
    required String tenantKeyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final tenantKey = TenantStorage(userId).prefKey(tenantKeyName);
    final migrationFlag = 'legacy_migrated:$legacyKey';

    if (prefs.containsKey(tenantKey)) return;
    if (prefs.getBool(migrationFlag) == true) return;

    final legacy = prefs.getString(legacyKey);
    if (legacy != null) {
      await prefs.setString(tenantKey, legacy);
      await prefs.remove(legacyKey);
    }

    await prefs.setBool(migrationFlag, true);
  }
}
