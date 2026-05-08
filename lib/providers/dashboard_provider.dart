import 'package:flutter/foundation.dart';
import '../data/models/service_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/laundry_service.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardStatus        _status       = DashboardStatus.initial;
  String?                _error;
  List<ServiceModel>     _services     = [];
  List<TransactionModel> _transactions = [];
  bool                   _orderLoading = false;
  bool                   _profileLoading = false;

  DashboardStatus        get status          => _status;
  String?                get error           => _error;
  List<ServiceModel>     get services        => _services;
  List<TransactionModel> get transactions    => _transactions;
  bool                   get isLoading       => _status == DashboardStatus.loading;
  bool                   get orderLoading    => _orderLoading;
  bool                   get profileLoading  => _profileLoading;

  // ── Derived lists matching Laravel UserDashboardController ────────────────
  List<TransactionModel> get activeOrders => _transactions
      .where((t) => ['baru', 'cuci', 'kering', 'setrika'].contains(t.status))
      .toList();

  List<TransactionModel> get pendingPayments => _transactions
      .where((t) => t.status == 'baru')
      .toList();

  List<TransactionModel> get inProgressOrders => _transactions
      .where((t) => ['cuci', 'kering', 'setrika'].contains(t.status))
      .toList();

  List<TransactionModel> get completedOrders => _transactions
      .where((t) => ['selesai', 'diambil'].contains(t.status))
      .toList();

  double get totalSpent => completedOrders.fold(0, (s, t) => s + t.totalPrice);

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> load() async {
    _status = DashboardStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      final svc = LaundryService();
      final results = await Future.wait([svc.getServices(), svc.getTransactions()]);
      _services     = results[0] as List<ServiceModel>;
      _transactions = (results[1] as List<TransactionModel>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _status = DashboardStatus.loaded;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'UNAUTHORIZED') {
        _error = 'Sesi telah berakhir. Silakan login kembali.';
      } else {
        _error = msg;
      }
      _status = DashboardStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  // ── Create Order ──────────────────────────────────────────────────────────
  /// Returns error message or null on success
  Future<String?> createOrder({
    required List<Map<String, dynamic>> items,
    required String address,
    required String phone,
    required String paymentMethod,
    required String deliveryType,
  }) async {
    _orderLoading = true;
    notifyListeners();
    try {
      final trx = await LaundryService().createOrder(
        items: items,
        address: address,
        phone: phone,
        paymentMethod: paymentMethod,
        deliveryType: deliveryType,
      );
      _transactions = [trx, ..._transactions];
      _orderLoading = false;
      notifyListeners();
      return null; // success
    } catch (e) {
      _orderLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  /// Returns (user, errorMessage)
  Future<(UserModel?, String?)> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    _profileLoading = true;
    notifyListeners();
    try {
      final user = await LaundryService().updateProfile(
        name: name, email: email, phone: phone, address: address);
      _profileLoading = false;
      notifyListeners();
      return (user, null);
    } catch (e) {
      _profileLoading = false;
      notifyListeners();
      return (null, e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
