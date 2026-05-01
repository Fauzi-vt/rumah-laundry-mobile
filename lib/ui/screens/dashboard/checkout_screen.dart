import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import 'transaction_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double totalEstimasi;
  final int cartItemCount;
  final VoidCallback? onCheckoutSuccess;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalEstimasi,
    required this.cartItemCount,
    this.onCheckoutSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;

  String _paymentMethod = 'cash';
  String _deliveryType = 'antar_jemput';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Konfirmasi Pesanan',
      text: 'Apakah Anda yakin ingin membuat pesanan ini?',
      confirmBtnText: 'Ya, Pesan',
      cancelBtnText: 'Batal',
      confirmBtnColor: AppColors.primaryGreen,
      onConfirmBtnTap: () async {
        Navigator.of(context).pop(); // Tutup alert confirm
        
        // Tampilkan loading alert
        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Memproses...',
          text: 'Mohon tunggu sebentar',
          barrierDismissible: false,
        );

        final dash = context.read<DashboardProvider>();
        final err = await dash.createOrder(
          items: widget.items,
          address: _addressCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          paymentMethod: _paymentMethod,
          deliveryType: _deliveryType,
        );

        if (!context.mounted) return;
        Navigator.of(context).pop(); // Tutup loading alert

        if (err == null) {
          // Refresh data dari server supaya transaction list up-to-date
          await dash.refresh();

          if (!context.mounted) return;

          final TransactionModel? newTrx =
              dash.transactions.isNotEmpty ? dash.transactions.first : null;
          
          if (newTrx != null) {
            widget.onCheckoutSuccess?.call();
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    TransactionDetailScreen(transaction: newTrx),
                transitionsBuilder: (_, anim, __, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOutCubic));
                  return SlideTransition(position: slide, child: child);
                },
                transitionDuration: const Duration(milliseconds: 380),
              ),
            );
          } else {
            Navigator.of(context).pop(true); // Signal success
          }
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Gagal',
            text: err,
            confirmBtnText: 'Tutup',
            confirmBtnColor: Colors.red.shade700,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final isLoading = dash.orderLoading;
    final formattedTotal = widget.totalEstimasi.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informasi Pembelian'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Alamat & Nomor HP ──────────────────────────────────
            Text('Informasi Pengiriman', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Alamat Lengkap',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (v) => v!.trim().isEmpty ? 'Alamat harus diisi' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Nomor HP/WhatsApp',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Nomor HP harus diisi' : null,
            ),
            const SizedBox(height: 24),

            // ── Metode Pengiriman ──────────────────────────────────
            Text('Metode Pengiriman', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Antar Jemput',
                    icon: Icons.local_shipping_outlined,
                    isSelected: _deliveryType == 'antar_jemput',
                    onTap: () => setState(() => _deliveryType = 'antar_jemput'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Bawa Sendiri',
                    icon: Icons.storefront_outlined,
                    isSelected: _deliveryType == 'bawa_sendiri',
                    onTap: () => setState(() => _deliveryType = 'bawa_sendiri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Metode Pembayaran ──────────────────────────────────
            Text('Metode Pembayaran', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Tunai (Cash)',
                    icon: Icons.money_rounded,
                    isSelected: _paymentMethod == 'cash',
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Transfer Bank',
                    icon: Icons.account_balance_outlined,
                    isSelected: _paymentMethod == 'transfer',
                    onTap: () => setState(() => _paymentMethod = 'transfer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Total Estimasi', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                    Text('Rp $formattedTotal', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                  ]),
                  Text('${widget.cartItemCount} layanan', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Selesaikan Pesanan', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
