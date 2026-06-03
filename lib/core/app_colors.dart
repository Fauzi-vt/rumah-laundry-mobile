import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color primaryGreen  = Color(0xFF0C3B8B); // Deep Navy Blue
  static const Color primaryMid    = Color(0xFF1A56DB); // Mid Blue
  static const Color primaryLight  = Color(0xFFEBF2FF); // Soft Blue (chip bg)
  static const Color accent        = Color(0xFFF97316); // Orange (logo accent)

  // ── Neutrals ─────────────────────────────────────────────────────────────
  static const Color background    = Color(0xFFF4F6F8);
  static const Color surface       = Colors.white;
  static const Color cardBorder    = Color(0xFFE9ECEF);
  static const Color textPrimary   = Color(0xFF1A1C1E);
  static const Color textSecondary = Color(0xFF6C757D);

  // ── Transaction Status ────────────────────────────────────────────────────
  static const Color statusBaru     = Color(0xFF6366F1); // indigo  — baru
  static const Color statusCuci     = Color(0xFF3B82F6); // blue    — cuci
  static const Color statusKering   = Color(0xFFF59E0B); // amber   — kering
  static const Color statusSetrika  = Color(0xFFF97316); // orange  — setrika
  static const Color statusSelesai  = Color(0xFF10B981); // emerald — selesai
  static const Color statusDiambil  = Color(0xFF059669); // deep emerald — diambil

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':    return statusBaru;
      case 'cuci':    return statusCuci;
      case 'kering':  return statusKering;
      case 'setrika': return statusSetrika;
      case 'selesai': return statusSelesai;
      case 'diambil': return statusDiambil;
      default:        return textSecondary;
    }
  }

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'baru':    return 'Baru Masuk';
      case 'cuci':    return 'Sedang Dicuci';
      case 'kering':  return 'Pengeringan';
      case 'setrika': return 'Penyetrikaan';
      case 'selesai': return 'Selesai';
      case 'diambil': return 'Sudah Diambil';
      default:        return status;
    }
  }
}
