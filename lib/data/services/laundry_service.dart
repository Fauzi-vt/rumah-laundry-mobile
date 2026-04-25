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
    throw Exception('Gagal memuat pesanan.');
  }

  // ── Create Order ──────────────────────────────────────────────────────────
  /// items = [{ 'service_id': int, 'quantity': double }]
  Future<TransactionModel> createOrder(List<Map<String, dynamic>> items) async {
    final res = await http.post(
      Uri.parse(ApiConstants.orders),
      headers: _headers,
      body: jsonEncode({'items': items}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      return TransactionModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      final errors = body['errors'] as Map<String, dynamic>;
      throw Exception((errors.values.first as List).first as String);
    }
    throw Exception(body['message'] ?? 'Gagal membuat pesanan.');
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
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return UserModel.fromJson(body['user'] as Map<String, dynamic>);
    }
    if (body['errors'] != null) {
      final errors = body['errors'] as Map<String, dynamic>;
      throw Exception((errors.values.first as List).first as String);
    }
    throw Exception(body['message'] ?? 'Gagal memperbarui profil.');
  }
}
