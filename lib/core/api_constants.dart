import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return 'http://10.0.2.2:8000/api';
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
