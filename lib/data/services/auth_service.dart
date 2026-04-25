import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/api_constants.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey  = 'auth_user';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveSession(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      final token = body['token'] as String;
      final user  = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return user;
    }
    throw Exception(body['message'] ?? 'Login gagal.');
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name, 'email': email,
        'password': password, 'password_confirmation': passwordConfirmation,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      final token = body['token'] as String;
      final user  = UserModel.fromJson(body['user'] as Map<String, dynamic>);
      await _saveSession(token, user);
      return user;
    }
    if (body['errors'] != null) {
      final errors  = body['errors'] as Map<String, dynamic>;
      final firstMsg = (errors.values.first as List).first as String;
      throw Exception(firstMsg);
    }
    throw Exception(body['message'] ?? 'Registrasi gagal.');
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(Uri.parse(ApiConstants.logout), headers: {
          'Content-Type': 'application/json', 'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });
      }
    } finally {
      await clearSession();
    }
  }
}
