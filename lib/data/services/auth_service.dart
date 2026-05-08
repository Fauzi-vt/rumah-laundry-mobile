import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const _userKey  = 'auth_user';
  final _supabase = Supabase.instance.client;

  Future<String?> getToken() async {
    return _supabase.auth.currentSession?.accessToken;
  }

  Future<void> _saveUserToLocal(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveUser(UserModel user) async {
    await _saveUserToLocal(user);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    return _supabase.auth.currentSession != null;
  }

  Future<void> restoreSession() async {
    // Supabase handles session restoration automatically via persistence.
    // We just need to make sure our local user model is synced if needed.
  }

  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) throw Exception('Login gagal: User tidak ditemukan.');

      // Fetch additional profile data from public.users table
      // Assuming the table 'users' has the profile info and links to auth.uid()
      final profile = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (profile == null) throw Exception('Profil user tidak ditemukan di database.');

      final user = UserModel.fromJson(profile);
      await _saveUserToLocal(user);
      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login gagal: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    try {
      if (password != passwordConfirmation) {
        throw Exception('Konfirmasi password tidak cocok.');
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
        },
      );

      if (response.user == null) throw Exception('Registrasi gagal.');

      // Create profile in public.users table if it doesn't exist (if not handled by trigger)
      // Note: Usually a Postgres trigger handles this, but we can do it manually if needed.
      // For now, let's assume we need to insert it.
      final newProfile = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
        // 'id' might be auto-incrementing if it's int, or we use auth uuid if changed.
      };

      final inserted = await _supabase
          .from('users')
          .insert(newProfile)
          .select()
          .single();

      final user = UserModel.fromJson(inserted);
      await _saveUserToLocal(user);
      return user;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Registrasi gagal: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await clearSession();
  }
}
