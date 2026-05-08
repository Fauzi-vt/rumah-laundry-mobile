import 'package:flutter/foundation.dart';

class ApiConstants {
  // ── Toggle ini sesuai dengan perangkat yang digunakan ────────────────────
  //
  // false → Android Emulator  (gunakan 10.0.2.2 yang mengarah ke host PC)
  // true  → HP fisik / device nyata (gunakan IP Wi-Fi PC kamu)
  //
  static const String supabaseUrl = 'https://ingxtyqcqdiidhievrox.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluZ3h0eXFjcWRpaWRoaWV2cm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc3Mzg1NjAsImV4cCI6MjA5MzMxNDU2MH0.AeIPS280yVvnsp0C3dF8XesxVEpQdNWd3faKnOFfP5k';

  // Auth (Legacy, but keeping for reference if needed, though we will use Supabase SDK)
  static String get baseUrl => supabaseUrl;

  // Auth
  static String get login => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get logout => '$baseUrl/logout';

  // User
  static String get user => '$baseUrl/user';
  static String get profile => '$baseUrl/profile';

  // Laundry
  static String get services => '$baseUrl/services';
  static String get transactions => '$baseUrl/transactions';
  static String get orders => '$baseUrl/orders';

  // Tracking (public)
  static String track(String invoiceCode) => '$baseUrl/track/$invoiceCode';
}
