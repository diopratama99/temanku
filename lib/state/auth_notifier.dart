import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _auth;
  AuthNotifier(this._auth);

  bool get isLoggedIn => _auth.currentUserId != null;
  Map<String, dynamic>? get user => _auth.currentUser;

  Future<String?> login(String email, String password) async {
    final res = await _auth.login(email: email, password: password);
    notifyListeners();
    return res;
  }

  Future<String?> loginGoogle() async {
    final res = await _auth.loginWithGoogle();
    notifyListeners();
    return res;
  }

  Future<String?> register(String name, String email, String password) async {
    final res = await _auth.register(
      name: name,
      email: email,
      password: password,
    );
    notifyListeners();
    return res;
  }

  Future<void> logout() async {
    await _auth.logout();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await _auth.refreshCurrentUser();
    notifyListeners();
  }
}
