import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/order_notification.dart';

/// Menampilkan banner notifikasi dari atas layar dengan animasi slide-down.
/// Gunakan via [NotificationHelper.showOrderNotification].
class OrderNotificationBanner extends StatefulWidget {
  final OrderNotification notification;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const OrderNotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<OrderNotificationBanner> createState() => _OrderNotificationBannerState();
}

class _OrderNotificationBannerState extends State<OrderNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    // Auto-dismiss setelah 4 detik
    Future.delayed(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.notification.newStatus.toLowerCase()) {
      case 'cuci':    return const Color(0xFF3B82F6); // blue
      case 'kering':  return const Color(0xFF06B6D4); // cyan
      case 'setrika': return const Color(0xFFF59E0B); // amber
      case 'selesai': return const Color(0xFF10B981); // emerald
      case 'diambil': return const Color(0xFF8B5CF6); // purple
      default:        return const Color(0xFF6B7280); // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onTap: () {
            _dismiss();
            widget.onTap?.call();
          },
          onVerticalDragUpdate: (details) {
            if (details.delta.dy < -4) _dismiss();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Ikon lonceng
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      _statusEmoji(widget.notification.newStatus),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Konten teks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Status Pesanan',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: accent,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Baru saja',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.notification.invoiceCode,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Swipe indicator
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _statusEmoji(String status) {
    const map = {
      'cuci':    '🧺',
      'kering':  '💨',
      'setrika': '👔',
      'selesai': '✅',
      'diambil': '🎉',
    };
    return map[status.toLowerCase()] ?? '🔔';
  }
}
