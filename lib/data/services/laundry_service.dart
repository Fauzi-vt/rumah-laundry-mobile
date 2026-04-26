import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../../core/api_constants.dart';

class LaundryService {
  final String token;
  LaundryService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type':  'application/json',
        'Accept':        'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Services ──────────────────────────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    final res = await http.get(Uri.parse(ApiConstants.services), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['data'] as List? ?? [];
      return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    _handleError(res);
    throw Exception('Gagal memuat layanan.');
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions() async {
    final res = await http.get(Uri.parse(ApiConstants.transactions), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final list = body['data'] as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    _handleError(res);
    throw Exception('Gagal memuat pesanan.');
  }

  // ── Create Order ──────────────────────────────────────────────────────────
  /// items = [{ 'service_id': int, 'quantity': double }]
  Future<TransactionModel> createOrder({
    required List<Map<String, dynamic>> items,
    required String address,
    required String phone,
    required String paymentMethod,
    required String deliveryType,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConstants.orders),
      headers: _headers,
      body: jsonEncode({
        'items': items,
        'address': address,
        'phone': phone,
        'payment_method': paymentMethod,
        'delivery_type': deliveryType,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return TransactionModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    _handleError(res);
    throw Exception('Gagal membuat pesanan.');
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<UserModel> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final res = await http.put(
      Uri.parse(ApiConstants.profile),
      headers: _headers,
      body: jsonEncode({
        'name': name, 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return UserModel.fromJson(body['user'] as Map<String, dynamic>);
    }
    _handleError(res);
    throw Exception('Gagal memperbarui profil.');
  }

  void _handleError(http.Response res) {
    if (res.statusCode == 401) {
      throw Exception('UNAUTHORIZED');
    }
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['errors'] != null) {
        final errors = body['errors'] as Map<String, dynamic>;
        throw Exception((errors.values.first as List).first as String);
      }
      if (body['message'] != null) {
        throw Exception(body['message']);
      }
    } catch (_) {
      rethrow;
    }
  }
}
