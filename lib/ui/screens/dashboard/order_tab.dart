import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../providers/dashboard_provider.dart';

class OrderTab extends StatefulWidget {
  const OrderTab({super.key});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {
  // cart: serviceId -> quantity
  final Map<int, double> _cart = {};

  double totalPrice(List<ServiceModel> services) {
    double total = 0;
    for (final s in services) {
      final qty = _cart[s.id] ?? 0;
      total += s.price * qty;
    }
    return total;
  }

  int get cartItemCount => _cart.values.where((q) => q > 0).length;

  Future<void> _submit(BuildContext context) async {
    final items = _cart.entries
        .where((e) => e.value > 0)
        .map((e) => {'service_id': e.key, 'quantity': e.value})
        .toList();

    if (items.isEmpty) {
      _showSnack(context, 'Pilih minimal satu layanan terlebih dahulu.', isError: true);
      return;
    }

    final dash = context.read<DashboardProvider>();
    final err  = await dash.createOrder(items);

    if (!context.mounted) return;
    if (err == null) {
      setState(() => _cart.clear());
      _showSnack(context, '✅ Pesanan berhasil dibuat! Silakan lakukan pembayaran di kasir.');
    } else {
      _showSnack(context, err, isError: true);
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dash     = context.watch<DashboardProvider>();
    final services = dash.services;
    final isLoading = dash.orderLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Laundry'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (cartItemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('$cartItemCount item',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      body: dash.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : Column(
              children: [
                Expanded(child: _buildServiceList(services)),
                if (cartItemCount > 0)
                  _buildOrderSummary(context, services, isLoading),
              ],
            ),
    );
  }

  Widget _buildServiceList(List<ServiceModel> services) {
    if (services.isEmpty) {
      return Center(
        child: Text('Belum ada layanan tersedia.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary)),
      );
    }

    // Group by category
    final Map<String, List<ServiceModel>> grouped = {};
    for (final s in services) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.primaryGreen, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pilih layanan dan tentukan jumlah (kg/pcs), lalu tekan Order.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.primaryGreen),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        ...grouped.entries.expand((entry) => [
          _categoryHeader(entry.key),
          const SizedBox(height: 8),
          ...entry.value.map((s) => _ServiceOrderRow(
                service: s,
                quantity: _cart[s.id] ?? 0,
                onChanged: (q) => setState(() => _cart[s.id] = q),
              )),
          const SizedBox(height: 12),
        ]),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _categoryHeader(String cat) {
    return Row(children: [
      Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(cat,
          style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildOrderSummary(
      BuildContext context, List<ServiceModel> services, bool isLoading) {
    final total = totalPrice(services);
    final formatted = total.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total Estimasi',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text('Rp $formatted',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen)),
                ]),
                Text('$cartItemCount layanan dipilih',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _submit(context),
                child: isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text('Buat Pesanan Sekarang',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service row with quantity stepper ─────────────────────────────────────────
class _ServiceOrderRow extends StatelessWidget {
  final ServiceModel service;
  final double       quantity;
  final void Function(double) onChanged;

  const _ServiceOrderRow({
    required this.service,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: quantity > 0 ? AppColors.primaryLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quantity > 0 ? AppColors.primaryGreen : AppColors.cardBorder,
          width: quantity > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(service.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(service.formattedPrice,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _QuantityStepper(
              quantity: quantity, unit: service.unit, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final double quantity;
  final String unit;
  final void Function(double) onChanged;
  const _QuantityStepper(
      {required this.quantity, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final step = unit == 'kg' ? 0.5 : 1.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quantity > 0) ...[
          _Btn(
            icon: Icons.remove,
            onTap: () => onChanged((quantity - step).clamp(0, 999)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              unit == 'kg'
                  ? '${quantity.toStringAsFixed(1)} $unit'
                  : '${quantity.toInt()} $unit',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
        _Btn(
          icon: quantity > 0 ? Icons.add : Icons.add,
          onTap: () => onChanged(quantity + step),
          filled: quantity == 0,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _Btn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryGreen : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: filled ? Colors.white : AppColors.primaryGreen),
      ),
    );
  }
}
