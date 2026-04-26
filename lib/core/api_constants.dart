import 'package:flutter/foundation.dart';

class ApiConstants {
  // ── Toggle ini sesuai dengan perangkat yang digunakan ────────────────────
  //
  // false → Android Emulator  (gunakan 10.0.2.2 yang mengarah ke host PC)
  // true  → HP fisik / device nyata (gunakan IP Wi-Fi PC kamu)
  //
  static const bool _usePhysicalDevice = false;

  // IP Wi-Fi PC kamu (jalankan: ipconfig, lihat Wi-Fi → IPv4 Address)
  static const String _pcWifiIp = '192.168.100.102';

  // Laragon berjalan di port 80 dengan path /laundry-api/public/api
  static const String _laragonPath = '/laundry-api/public/api';

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost$_laragonPath';
    if (_usePhysicalDevice) return 'http://$_pcWifiIp$_laragonPath';
    return 'http://10.0.2.2$_laragonPath'; // Android Emulator → Laragon port 80
  }

  // Auth
  static String get login    => '$baseUrl/login';
  static String get register => '$baseUrl/register';
  static String get logout   => '$baseUrl/logout';

  // User
  static String get user    => '$baseUrl/user';
  static String get profile => '$baseUrl/profile';

  // Laundry
  static String get services     => '$baseUrl/services';
  static String get transactions => '$baseUrl/transactions';
  static String get orders       => '$baseUrl/orders';

  // Tracking (public)
  static String track(String invoiceCode) => '$baseUrl/track/$invoiceCode';
}
