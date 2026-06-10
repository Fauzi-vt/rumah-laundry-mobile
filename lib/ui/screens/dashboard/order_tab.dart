import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/service_model.dart';
import '../../../providers/dashboard_provider.dart';
import 'checkout_screen.dart';

class OrderTab extends StatefulWidget {
  const OrderTab({super.key});

  @override
  State<OrderTab> createState() => _OrderTabState();
}

class _OrderTabState extends State<OrderTab> {

  void _goToCheckout(BuildContext context) async {
    final dash = context.read<DashboardProvider>();
    final items = dash.cart.entries
        .where((e) => e.value > 0)
        .map((e) => {'service_id': e.key, 'quantity': e.value})
        .toList();

    if (items.isEmpty) {
      _showSnack(context, 'Pilih minimal satu layanan terlebih dahulu.', isError: true);
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CheckoutScreen(
          items: items,
          totalEstimasi: dash.totalCartPrice,
          onCheckoutSuccess: () {
            dash.clearCart();
          },
          cartItemCount: dash.cartItemCount,
        ),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
      ),
    );
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
    final dash = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Laundry'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (dash.cartItemCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('${dash.cartItemCount} item',
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
          : dash.error != null
              ? _buildErrorState(context, dash.error!)
              : Column(
                  children: [
                    Expanded(child: _buildServiceList(dash)),
                    if (dash.cartItemCount > 0)
                      _buildOrderSummary(context, dash),
                  ],
                ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
          const SizedBox(height: 12),
          Text('Gagal memuat data',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.red.shade600),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<DashboardProvider>().refresh(),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Coba Lagi',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList(DashboardProvider dash) {
    final services = dash.services;
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
                quantity: dash.cart[s.id] ?? 0,
                onChanged: (q) => dash.updateCart(s.id, q),
              )),
          const SizedBox(height: 24),
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

  Widget _buildOrderSummary(BuildContext context, DashboardProvider dash) {
    final total = dash.totalCartPrice;
    final formatted = total.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.1), width: 0.8),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rp $formatted',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    '${dash.cartItemCount} Layanan dipilih',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: dash.orderLoading ? null : () => _goToCheckout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Checkout',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                ? Image.network(
                    service.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          service.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      service.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
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
    final String formattedQty = unit == 'kg'
        ? quantity.toStringAsFixed(1).replaceAll('.0', '')
        : quantity.toInt().toString();

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
              formattedQty,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
        ],
        _Btn(
          icon: Icons.add,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryGreen : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(icon,
            size: 16,
            color: filled ? Colors.white : AppColors.primaryGreen),
      ),
    );
  }
}
