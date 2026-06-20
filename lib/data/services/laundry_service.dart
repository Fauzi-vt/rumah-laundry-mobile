import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_constants.dart';
import 'auth_service.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/payment_account_model.dart';

class LaundryService {
  final _authService = AuthService();

  // ── Payment Accounts ──────────────────────────────────────────────────────
  Future<List<PaymentAccountModel>> getPaymentAccounts() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.paymentAccounts),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat metode pembayaran: Server mengembalikan status ${response.statusCode}');
      }

      final Map<String, dynamic> body = jsonDecode(response.body);
      final List list = body['data'] as List? ?? [];
      return list.map((e) => PaymentAccountModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gagal memuat metode pembayaran: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

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
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali untuk memperbarui profil.');
      }

      final uri = Uri.parse(ApiConstants.profile);
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Laravel workaround: PUT requests with multipart files must be sent as POST with _method = PUT
      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['address'] = address;

      if (avatarBytes != null && avatarFileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'avatar',
            avatarBytes,
            filename: avatarFileName,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

  // ── Upload Payment Proof ──────────────────────────────────────────────────
  Future<TransactionModel> uploadPaymentProof({
    required int transactionId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/transactions/$transactionId/payment-proof');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'payment_proof',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body);
        throw Exception(json['message'] ?? 'Gagal mengunggah bukti pembayaran');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return TransactionModel.fromJson(data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal mengunggah bukti pembayaran: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse(ApiConstants.updateFcmToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode != 200) {
        final json = jsonDecode(response.body);
        throw Exception(json['message'] ?? 'Gagal memperbarui token notifikasi');
      }
    } catch (e) {
      throw Exception('Gagal memperbarui token notifikasi: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}
