import 'package:flutter/foundation.dart';
import '../data/models/service_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/user_model.dart';
import '../data/services/laundry_service.dart';
import 'notification_provider.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardStatus _status = DashboardStatus.initial;
  String? _error;
  List<ServiceModel> _services = [];
  List<TransactionModel> _transactions = [];
  bool _orderLoading = false;
  bool _profileLoading = false;

  /// Injected dari main.dart — digunakan untuk mendeteksi perubahan status
  NotificationProvider? notificationProvider;

  // Cart state: serviceId -> quantity
  final Map<int, double> _cart = {};

  DashboardStatus get status => _status;
  String? get error => _error;
  List<ServiceModel> get services => _services;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _status == DashboardStatus.loading;
  bool get orderLoading => _orderLoading;
  bool get profileLoading => _profileLoading;

  Map<int, double> get cart => _cart;
  int get cartItemCount => _cart.values.where((q) => q > 0).length;

  double get totalCartPrice {
    double total = 0;
    for (final s in _services) {
      final qty = _cart[s.id] ?? 0;
      total += s.price * qty;
    }
    return total;
  }

  void updateCart(int serviceId, double quantity) {
    if (quantity <= 0) {
      _cart.remove(serviceId);
    } else {
      _cart[serviceId] = quantity;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // ── Derived lists matching Laravel UserDashboardController ────────────────
  List<TransactionModel> get activeOrders => _transactions
      .where((t) => ['baru', 'cuci', 'kering', 'setrika'].contains(t.status))
      .toList();

  List<TransactionModel> get pendingPayments =>
      _transactions.where((t) => t.status == 'baru').toList();

  List<TransactionModel> get inProgressOrders => _transactions
      .where((t) => ['cuci', 'kering', 'setrika'].contains(t.status))
      .toList();

  List<TransactionModel> get completedOrders => _transactions
      .where((t) => ['selesai', 'diambil'].contains(t.status))
      .toList();

  double get totalSpent => completedOrders.fold(0, (s, t) => s + t.totalPrice);

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<List<dynamic>> load({bool detectChanges = false, bool silent = false}) async {
    if (!silent) {
      _status = DashboardStatus.loading;
      _error = null;
      notifyListeners();
    }

    // Simpan snapshot status lama sebelum fetch (untuk deteksi perubahan)
    final oldTransactions = List<TransactionModel>.from(_transactions);

    try {
      final svc = LaundryService();
      final results = await Future.wait([
        svc.getServices(),
        svc.getTransactions(),
      ]);
      _services = results[0] as List<ServiceModel>;
      _transactions = (results[1] as List<TransactionModel>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _status = DashboardStatus.loaded;

      // Deteksi perubahan status jika diminta dan ada data lama
      if (detectChanges && oldTransactions.isNotEmpty && notificationProvider != null) {
        final newNotifs = notificationProvider!.checkForStatusChanges(
          oldTransactions: oldTransactions,
          newTransactions: _transactions,
        );
        notifyListeners();
        return newNotifs; // Kembalikan notifikasi baru untuk ditampilkan banner
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg == 'UNAUTHORIZED') {
        _error = 'Sesi telah berakhir. Silakan login kembali.';
      } else {
        _error = msg;
      }
      if (!silent) {
        _status = DashboardStatus.error;
      }
    }
    notifyListeners();
    return [];
  }

  Future<List<dynamic>> refresh({bool silent = true}) => load(detectChanges: true, silent: silent);

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
    List<int>? avatarBytes,
    String? avatarFileName,
  }) async {
    _profileLoading = true;
    notifyListeners();
    try {
      final user = await LaundryService().updateProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
        avatarBytes: avatarBytes,
        avatarFileName: avatarFileName,
      );
      _profileLoading = false;
      notifyListeners();
      return (user, null);
    } catch (e) {
      _profileLoading = false;
      notifyListeners();
      return (null, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Upload Payment Proof ──────────────────────────────────────────────────
  Future<String?> uploadPaymentProof({
    required int transactionId,
    required List<int> bytes,
    required String filename,
  }) async {
    _orderLoading = true;
    notifyListeners();
    try {
      final updatedTrx = await LaundryService().uploadPaymentProof(
        transactionId: transactionId,
        imageBytes: bytes,
        fileName: filename,
      );
      
      final idx = _transactions.indexWhere((t) => t.id == transactionId);
      if (idx != -1) {
        _transactions[idx] = updatedTrx;
      }
      
      _orderLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _orderLoading = false;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
