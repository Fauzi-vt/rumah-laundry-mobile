import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';

class LaundryService {
  final _supabase = Supabase.instance.client;

  // ── Services ──────────────────────────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    try {
      final response = await _supabase
          .from('services')
          .select();
      
      final list = response as List? ?? [];
      return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gagal memuat layanan: ${e.toString()}');
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final userAuth = _supabase.auth.currentUser;
      if (userAuth == null) throw Exception('UNAUTHORIZED');

      // 1. Ambil ID (int) dari tabel public.users berdasarkan email auth
      final profile = await _supabase
          .from('users')
          .select('id')
          .eq('email', userAuth.email as String)
          .maybeSingle();
      
      if (profile == null) return [];
      final int userIdInt = profile['id'];

      // 2. Gunakan ID int untuk mengambil transaksi
      final response = await _supabase
          .from('transactions')
          .select('*, details:transaction_details(*, service:services(*))')
          .eq('user_id', userIdInt)
          .order('created_at', ascending: false);
      
      final list = response as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
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
      final userAuth = _supabase.auth.currentUser;
      if (userAuth == null) throw Exception('UNAUTHORIZED');

      // Ambil ID int dari profil
      final profile = await _supabase
          .from('users')
          .select('id')
          .eq('email', userAuth.email as String)
          .single();
      
      final int userIdInt = profile['id'];

      // 1. Create the transaction record
      final transactionData = {
        'user_id': userIdInt,
        'address': address,
        'phone': phone,
        'payment_method': paymentMethod,
        'delivery_type': deliveryType,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final transaction = await _supabase
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      final transactionId = transaction['id'];

      // 2. Insert items (transaction details)
      final details = items.map((item) => {
        'transaction_id': transactionId,
        'service_id': item['service_id'],
        'quantity': item['quantity'],
      }).toList();

      await _supabase.from('transaction_details').insert(details);

      // 3. Return full transaction model
      // We might want to re-fetch it with details or just construct it.
      return TransactionModel.fromJson(transaction);
    } catch (e) {
      throw Exception('Gagal membuat pesanan: ${e.toString()}');
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
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('UNAUTHORIZED');

      final updateData = {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };

      final updated = await _supabase
          .from('users')
          .update(updateData)
          .eq('email', email) // or use id if synced
          .select()
          .single();

      return UserModel.fromJson(updated);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: ${e.toString()}');
    }
  }
}
