import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String?    _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────
  AuthStatus get status       => _status;
  UserModel? get user         => _user;
  String?    get errorMessage => _errorMessage;
  bool       get isLoading    => _status == AuthStatus.loading;

  // ── Session restore on cold start ─────────────────────────────────────────
  Future<void> restoreSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final loggedIn = await _service.isLoggedIn();
    if (loggedIn) {
      _user   = await _service.getSavedUser();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _setLoading();
    try {
      _user   = await _service.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    _setLoading();
    try {
      _user = await _service.register(
        name:                 name,
        email:                email,
        password:             password,
        passwordConfirmation: passwordConfirmation,
        phone:                phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading();
    await _service.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Update local user after profile edit ──────────────────────────────────
  Future<void> updateUser(UserModel updatedUser) async {
    _user = updatedUser;
    // Persist updated user to SharedPreferences
    await _service.saveUser(updatedUser);
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _setLoading() {
    _status       = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    // Strip Dart's default "Exception:" prefix for cleaner UI display
    _errorMessage = message.replaceFirst('Exception: ', '');
    _status       = AuthStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
