import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/order_notification.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/dashboard_provider.dart';
import 'transaction_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, np, child) => np.notifications.isEmpty
                ? const SizedBox()
                : TextButton(
                    onPressed: () {
                      np.clearAll();
                    },
                    child: Text(
                      'Hapus Semua',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, np, _) {
          np.markAllRead();

          if (np.notifications.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: np.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _NotifCard(notification: np.notifications[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi akan muncul di sini saat\nstatus pesanan Anda berubah.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final OrderNotification notification;
  const _NotifCard({required this.notification});

  Color get _accentColor {
    switch (notification.newStatus.toLowerCase()) {
      case 'cuci':    return const Color(0xFF3B82F6);
      case 'kering':  return const Color(0xFF06B6D4);
      case 'setrika': return const Color(0xFFF59E0B);
      case 'selesai': return const Color(0xFF10B981);
      case 'diambil': return const Color(0xFF8B5CF6);
      default:        return AppColors.primaryGreen;
    }
  }

  String get _statusEmoji {
    const map = {
      'cuci':    '🧺',
      'kering':  '💨',
      'setrika': '👔',
      'selesai': '✅',
      'diambil': '🎉',
    };
    return map[notification.newStatus.toLowerCase()] ?? '🔔';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return GestureDetector(
      onTap: () {
        // Cari transaksi dan buka detail
        final dash = context.read<DashboardProvider>();
        TransactionModel? trx;
        try {
          trx = dash.transactions.firstWhere(
            (t) => t.id == notification.transactionId,
          );
        } catch (_) {
          trx = null;
        }
        if (trx != null && context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: trx!),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? AppColors.cardBorder
                : accent.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji ikon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Text(_statusEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        notification.timeAgo,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Dari: ${_statusLabel(notification.oldStatus)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel(notification.newStatus),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    const labels = {
      'baru':    'Baru',
      'cuci':    'Sedang Dicuci',
      'kering':  'Sedang Dikeringkan',
      'setrika': 'Sedang Disetrika',
      'selesai': 'Selesai',
      'diambil': 'Diambil',
    };
    return labels[status.toLowerCase()] ?? status;
  }
}
