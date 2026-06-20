class OrderNotification {
  final String id;
  final int transactionId;
  final String invoiceCode;
  final String oldStatus;
  final String newStatus;
  final DateTime timestamp;
  bool isRead;

  OrderNotification({
    required this.id,
    required this.transactionId,
    required this.invoiceCode,
    required this.oldStatus,
    required this.newStatus,
    required this.timestamp,
    this.isRead = false,
  });

  /// Pesan notifikasi dalam Bahasa Indonesia
  String get message {
    final label = _statusLabel(newStatus);
    switch (newStatus.toLowerCase()) {
      case 'cuci':
        return '🧺 Pesanan $invoiceCode sedang dicuci';
      case 'kering':
        return '💨 Pesanan $invoiceCode sedang dikeringkan';
      case 'setrika':
        return '👔 Pesanan $invoiceCode sedang disetrika';
      case 'selesai':
        return '✅ Pesanan $invoiceCode selesai & siap diambil!';
      case 'diambil':
        return '🎉 Pesanan $invoiceCode telah diambil. Terima kasih!';
      default:
        return '📦 Status pesanan $invoiceCode diperbarui: $label';
    }
  }

  /// Judul singkat untuk banner
  String get title {
    switch (newStatus.toLowerCase()) {
      case 'cuci':    return 'Sedang Dicuci';
      case 'kering':  return 'Sedang Dikeringkan';
      case 'setrika': return 'Sedang Disetrika';
      case 'selesai': return 'Siap Diambil! 🎉';
      case 'diambil': return 'Pesanan Diambil';
      default:        return 'Status Diperbarui';
    }
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

  /// Waktu relatif, misal "2 menit lalu"
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
