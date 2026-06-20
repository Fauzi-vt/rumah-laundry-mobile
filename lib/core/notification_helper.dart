import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/order_notification.dart';
import '../ui/widgets/order_notification_banner.dart';

/// Helper untuk menampilkan overlay notifikasi di atas semua widget.
class NotificationHelper {
  static final List<OverlayEntry> _activeEntries = [];

  /// Tampilkan banner notifikasi. Jika sudah ada banner aktif,
  /// banner baru akan muncul sedikit di bawah banner sebelumnya.
  static void showOrderNotification(
    BuildContext context,
    OrderNotification notification, {
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);

    // Haptic feedback — getaran saat notifikasi muncul
    HapticFeedback.mediumImpact();

    // Hitung offset berdasarkan jumlah banner aktif
    final bannerIndex = _activeEntries.length;
    final topOffset = MediaQuery.of(context).padding.top + 16.0 + (bannerIndex * 82.0);

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: OrderNotificationBanner(
            notification: notification,
            onTap: onTap,
            onDismiss: () {
              _activeEntries.remove(entry);
              entry.remove();
            },
          ),
        ),
      ),
    );

    _activeEntries.add(entry);
    overlay.insert(entry);
  }

  /// Tampilkan beberapa notifikasi secara berurutan dengan delay
  static void showMultipleNotifications(
    BuildContext context,
    List<OrderNotification> notifications, {
    void Function(OrderNotification)? onTap,
  }) {
    for (int i = 0; i < notifications.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (context.mounted) {
          showOrderNotification(
            context,
            notifications[i],
            onTap: onTap != null ? () => onTap(notifications[i]) : null,
          );
        }
      });
    }
  }
}
