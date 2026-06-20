import 'package:flutter/foundation.dart';

class ApiConstants {
  // Laravel API Configuration dengan Ngrok
  // Ganti URL di bawah ini dengan URL ngrok yang aktif
  static const String ngrokUrl = 'https://spinner-ground-thursday.ngrok-free.dev';

  static const String baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : '$ngrokUrl/api';

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
  static const String updateFcmToken = '$baseUrl/user/fcm-token';

  // Tracking (Public)
  static String track(String invoiceCode) => '$baseUrl/track/$invoiceCode';

  /// Helper untuk mengubah URL gambar/file dari local server Laravel agar mengarah ke Ngrok saat diakses dari HP
  static String? normalizeUrl(String? url) {
    if (url == null) return null;
    if (kIsWeb) return url;
    return url
        .replaceAll('http://localhost:8000', ngrokUrl)
        .replaceAll('http://127.0.0.1:8000', ngrokUrl)
        .replaceAll('http://10.0.2.2:8000', ngrokUrl)
        .replaceAll('http://192.168.100.102:8000', ngrokUrl);
  }
}
