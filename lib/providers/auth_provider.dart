import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/admin_service.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, AdminService? adminService})
      : _authService = authService ?? AuthService(),
        _adminService = adminService ?? AdminService() {
    _user = _authService.currentUser;
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      refreshUserProfile();
    });
    if (_user != null) {
      refreshUserProfile();
    }
  }

  final AuthService _authService;
  final AdminService _adminService;
  StreamSubscription<User?>? _authSubscription;
  User? _user;
  bool _busy = false;
  bool _isAdmin = false;
  bool _profileLoaded = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;
  bool get profileLoaded => _profileLoaded;
  bool get isBusy => _busy;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refreshUserProfile() async {
    final user = _user;
    if (user == null) {
      _isAdmin = false;
      _profileLoaded = true;
      notifyListeners();
      return;
    }

    _profileLoaded = false;
    notifyListeners();

    try {
      await _adminService.registerCurrentUser(user);

      if (await _adminService.isUserDisabled(user.uid)) {
        _error = 'Your account has been disabled.';
        await _authService.signOut();
        return;
      }

      _isAdmin = await _adminService.isUserAdmin(user.uid);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _isAdmin = false;
    } finally {
      _profileLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _authService.signUpWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _run(() => _authService.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<bool> signInWithGoogle() {
    return _run(_authService.signInWithGoogle);
  }

  Future<bool> sendPasswordResetEmail(String email) {
    return _runVoid(() => _authService.sendPasswordResetEmail(email));
  }

  Future<void> signOut() async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signOut();
    } on FirebaseAuthException catch (e) {
      _error = _authService.friendlyError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<UserCredential> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await action();
      _user = credential.user ?? _authService.currentUser;
      if (_user == null) {
        _error = 'Signed in but no user session was created. Please try again.';
        return false;
      }
      await refreshUserProfile();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.friendlyError(e);
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return false;
    } catch (e, stack) {
      _error = 'Authentication failed: $e';
      debugPrint('Auth error: $e\n$stack');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _runVoid(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _authService.friendlyError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
