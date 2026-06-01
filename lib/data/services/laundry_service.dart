import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import 'auth_service.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class LaundryService {
  final _authService = AuthService();

  // ── Services ──────────────────────────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.services),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat layanan: Server mengembalikan status ${response.statusCode}');
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List list = body['data'] as List? ?? [];
      return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gagal memuat layanan: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali untuk melihat pesanan.');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.transactions),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat pesanan: Server mengembalikan status ${response.statusCode}');
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List list = body['data'] as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gagal memuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Create Order ──────────────────────────────────────────────────────────
  Future<TransactionModel> createOrder({
    required List<Map<String, dynamic>> items,
    required String address,
    required String phone,
    required String paymentMethod,
    required String deliveryType,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali untuk membuat pesanan.');
      }

      final body = {
        'items': items.map((item) => {
          'service_id': item['service_id'],
          'quantity': item['quantity'],
        }).toList(),
        'address': address,
        'phone': phone,
        'payment_method': paymentMethod,
        'delivery_type': deliveryType,
      };

      final response = await http.post(
        Uri.parse(ApiConstants.orders),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal membuat pesanan');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali untuk memperbarui profil.');
      }

      final body = {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };

      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal memperbarui profil');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
