import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/service_model.dart';
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
  late TextEditingController _notesCtrl;

  String _paymentMethod = 'cash';
  bool _isDeliveryEnabled = true;
  final double _deliveryFee = 10000.0; // Biaya simulasi antar-jemput

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalBill {
    return widget.totalEstimasi + (_isDeliveryEnabled ? _deliveryFee : 0.0);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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

        final deliveryType = _isDeliveryEnabled ? 'antar_jemput' : 'bawa_sendiri';
        final address = _isDeliveryEnabled ? _addressCtrl.text.trim() : 'Ambil di Toko';


        final dash = context.read<DashboardProvider>();
        final err = await dash.createOrder(
          items: widget.items,
          address: address,
          phone: _phoneCtrl.text.trim(),
          paymentMethod: _paymentMethod,
          deliveryType: deliveryType,
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

    final formattedSubtotal = widget.totalEstimasi.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    
    final formattedDeliveryFee = _deliveryFee.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    final formattedTotal = _totalBill.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Konfirmasi Pembelian',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── RINGKASAN ORDER ──────────────────────────────────
            _buildSectionHeader('Ringkasan Layanan'),
            const SizedBox(height: 10),
            _buildOrderItemsSummary(dash),
            const SizedBox(height: 20),

            // ── METODE PENGIRIMAN (ANTAR-JEMPUT TOGGLE) ──────────
            _buildSectionHeader('Metode Pengiriman'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isDeliveryEnabled
                              ? AppColors.primaryGreen.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: _isDeliveryEnabled ? AppColors.primaryGreen : Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Layanan Antar-Jemput',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _isDeliveryEnabled
                                  ? 'Kurir akan mengambil & mengantar pakaian Anda (+Rp $formattedDeliveryFee)'
                                  : 'Anda mengantar & mengambil pakaian sendiri ke outlet',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isDeliveryEnabled,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            _isDeliveryEnabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  // Form Alamat jika Antar-Jemput Aktif
                  if (_isDeliveryEnabled) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressCtrl,
                      label: 'Alamat Penjemputan & Pengantaran',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (v) => v!.trim().isEmpty ? 'Alamat lengkap harus diisi untuk antar-jemput' : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── INFORMASI KONTAK ──────────────────────────────────
            _buildSectionHeader('Kontak Penerima'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Nomor HP/WhatsApp',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Nomor HP aktif harus diisi' : null,
            ),
            const SizedBox(height: 20),

            // ── CATATAN TAMBAHAN ─────────────────────────────────
            _buildSectionHeader('Catatan Tambahan (Opsional)'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Contoh: Pakaian putih dipisah, jangan pakai parfum...',
              icon: Icons.edit_note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // ── METODE PEMBAYARAN ────────────────────────────────
            _buildSectionHeader('Metode Pembayaran'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Tunai / COD',
                    icon: Icons.money_rounded,
                    description: 'Bayar saat serah pakaian',
                    isSelected: _paymentMethod == 'cash',
                    onTap: () => setState(() => _paymentMethod = 'cash'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildChoiceCard(
                    title: 'Transfer Bank',
                    icon: Icons.account_balance_outlined,
                    description: 'Upload bukti transfer',
                    isSelected: _paymentMethod == 'transfer',
                    onTap: () => setState(() => _paymentMethod = 'transfer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rincian Kalkulasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal Layanan', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Rp $formattedSubtotal', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Biaya Antar-Jemput', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    _isDeliveryEnabled ? 'Rp $formattedDeliveryFee' : 'Gratis',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDeliveryEnabled ? AppColors.accent : AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Tagihan', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                      Text('Rp $formattedTotal', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryGreen)),
                    ],
                  ),
                  Text('${widget.cartItemCount} Layanan', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Buat Pesanan',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemsSummary(DashboardProvider dash) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final service = dash.services.firstWhere(
            (s) => s.id == item['service_id'],
            orElse: () => ServiceModel(
              id: item['service_id'] as int,
              name: 'Layanan Tidak Dikenal',
              category: '',
              price: 0.0,
              unit: 'pcs',
            ),
          );
          
          final qty = item['quantity'] as double;
          final price = service.price;
          final subtotal = price * qty;
          
          final formattedPrice = price.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
          final formattedSubtotal = subtotal.toInt().toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

          final qtyLabel = service.unit == 'kg' 
              ? '${qty.toStringAsFixed(1)} kg' 
              : '${qty.toInt()} pcs';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    service.icon,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rp $formattedPrice x $qtyLabel',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp $formattedSubtotal',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
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
      style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary),
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        height: 110,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.cardBorder,
            width: isSelected ? 1.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? AppColors.primaryGreen : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
