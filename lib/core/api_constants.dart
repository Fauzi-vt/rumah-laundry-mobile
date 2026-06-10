import 'package:flutter/foundation.dart';

class ApiConstants {
  // Laravel API Configuration
  // IP 192.168.100.102 adalah IP lokal komputer Anda pada jaringan Wi-Fi.
  // Pastikan HP dan Laptop terhubung ke Wi-Fi yang sama.
  static const String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : 'http://192.168.100.102:8000/api';

  // Endpoints
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';
  static const String logout = '$baseUrl/logout';
  static const String user = '$baseUrl/user';
  static const String profile = '$baseUrl/profile';
  static const String services = '$baseUrl/services';
  static const String transactions = '$baseUrl/transactions';
  static const String orders = '$baseUrl/orders';
  static const String paymentAccounts = '$baseUrl/payment-accounts';


  // Tracking (Public)
  static String track(String invoiceCode) => '$baseUrl/track/$invoiceCode';

  /// Helper to map localhost/127.0.0.1/10.0.2.2 to IP lokal PC (192.168.100.102) ketika diakses dari HP
  static String? normalizeUrl(String? url) {
    if (url == null) return null;
    if (kIsWeb) return url;
    return url
        .replaceAll('http://localhost:8000', 'http://192.168.100.102:8000')
        .replaceAll('http://127.0.0.1:8000', 'http://192.168.100.102:8000')
        .replaceAll('http://10.0.2.2:8000', 'http://192.168.100.102:8000');
  }
}
