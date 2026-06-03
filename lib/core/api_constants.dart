import 'package:flutter/foundation.dart';

class ApiConstants {
  // Laravel API Configuration
  // 10.0.2.2 is the special IP address to access localhost of host machine from Android Emulator.
  // Use '127.0.0.1' or 'localhost' if running on a web/desktop client or iOS Simulator.
  // Use machine's local IP (e.g. 192.168.1.x) if testing on physical devices on the same Wi-Fi.
  static const String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://10.0.2.2:8000/api';

  // Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  static const String user = '$baseUrl/user';
  static const String profile = '$baseUrl/profile';
  static const String services = '$baseUrl/services';
  static const String transactions = '$baseUrl/transactions';
  static const String orders = '$baseUrl/orders';

  // Tracking (Public)
  static String track(String invoiceCode) => '$baseUrl/track/$invoiceCode';

  /// Helper to map localhost/127.0.0.1 to 10.0.2.2 when running on Android Emulator
  static String? normalizeUrl(String? url) {
    if (url == null) return null;
    if (kIsWeb) return url;
    return url
        .replaceAll('http://localhost:8000', 'http://10.0.2.2:8000')
        .replaceAll('http://127.0.0.1:8000', 'http://10.0.2.2:8000');
  }
}
