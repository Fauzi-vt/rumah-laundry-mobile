import 'package:flutter/foundation.dart';
import '../data/models/order_notification.dart';
import '../data/models/transaction_model.dart';

class NotificationProvider extends ChangeNotifier {
  final List<OrderNotification> _notifications = [];

  List<OrderNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// Dipanggil setiap kali data pesanan diperbarui.
  /// Membandingkan status lama vs baru dan menghasilkan notifikasi.
  /// Mengembalikan list notifikasi baru yang baru saja ditambahkan.
  List<OrderNotification> checkForStatusChanges({
    required List<TransactionModel> oldTransactions,
    required List<TransactionModel> newTransactions,
  }) {
    final List<OrderNotification> newNotifications = [];

    for (final newTrx in newTransactions) {
      final oldTrx = oldTransactions.cast<TransactionModel?>().firstWhere(
        (t) => t?.id == newTrx.id,
        orElse: () => null,
      );

      // Lewati jika pesanan baru (belum ada di data lama)
      if (oldTrx == null) continue;

      // Cek apakah status berubah
      if (oldTrx.status.toLowerCase() != newTrx.status.toLowerCase()) {
        final notification = OrderNotification(
          id: '${newTrx.id}_${DateTime.now().millisecondsSinceEpoch}',
          transactionId: newTrx.id,
          invoiceCode: newTrx.invoiceCode,
          oldStatus: oldTrx.status,
          newStatus: newTrx.status,
          timestamp: DateTime.now(),
        );
        _notifications.insert(0, notification); // Terbaru di atas
        newNotifications.add(notification);
      }
    }

    if (newNotifications.isNotEmpty) {
      notifyListeners();
    }

    return newNotifications;
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String notificationId) {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void addNotification(OrderNotification notification) {
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
