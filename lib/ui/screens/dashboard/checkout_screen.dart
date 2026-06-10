import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import '../../../core/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/payment_account_model.dart';
import '../../../data/services/laundry_service.dart';
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
  final _laundryService = LaundryService();

  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _notesCtrl;

  String _paymentMethod = 'cash';
  bool _isDeliveryEnabled = true;
  final double _deliveryFee = 10000.0;

  // Payment accounts state
  List<PaymentAccountModel> _paymentAccounts = [];
  bool _loadingAccounts = true;
  String? _accountsError;

  // Selected account detail (for non-cash)
  PaymentAccountModel? _selectedAccount;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressCtrl = TextEditingController(text: user?.address ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _notesCtrl = TextEditingController();
    _fetchPaymentAccounts();
  }

  Future<void> _fetchPaymentAccounts() async {
    try {
      final accounts = await _laundryService.getPaymentAccounts();
      if (mounted) {
        setState(() {
          _paymentAccounts = accounts;
          _loadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _accountsError = e.toString().replaceFirst('Exception: ', '');
          _loadingAccounts = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalBill =>
      widget.totalEstimasi + (_isDeliveryEnabled ? _deliveryFee : 0.0);

  String _fmt(double val) => val
      .toInt()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Capture context-dependent objects BEFORE any await
    final nav = Navigator.of(context);
    final dash = context.read<DashboardProvider>();
    // ignore: use_build_context_synchronously
    final ctx = context;

    QuickAlert.show(
      context: ctx,
      type: QuickAlertType.confirm,
      title: 'Konfirmasi Pesanan',
      text: 'Apakah Anda yakin ingin membuat pesanan ini?',
      confirmBtnText: 'Ya, Pesan',
      cancelBtnText: 'Batal',
      confirmBtnColor: AppColors.primaryGreen,
      onConfirmBtnTap: () async {
        nav.pop();

        if (!ctx.mounted) return;
        QuickAlert.show(
          context: ctx,
          type: QuickAlertType.loading,
          title: 'Memproses...',
          text: 'Mohon tunggu sebentar',
          barrierDismissible: false,
        );

        final deliveryType = _isDeliveryEnabled ? 'antar_jemput' : 'bawa_sendiri';
        final address = _isDeliveryEnabled ? _addressCtrl.text.trim() : 'Ambil di Toko';

        final err = await dash.createOrder(
          items: widget.items,
          address: address,
          phone: _phoneCtrl.text.trim(),
          paymentMethod: _paymentMethod,
          deliveryType: deliveryType,
        );

        if (!ctx.mounted) return;
        nav.pop(); // tutup loading

        if (err == null) {
          await dash.refresh();
          if (!ctx.mounted) return;

          final TransactionModel? newTrx =
              dash.transactions.isNotEmpty ? dash.transactions.first : null;

          if (newTrx != null) {
            widget.onCheckoutSuccess?.call();
            nav.pushReplacement(
              PageRouteBuilder(
                pageBuilder: (c, a1, a2) =>
                    TransactionDetailScreen(transaction: newTrx),
                transitionsBuilder: (c, anim, a2, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
                  return SlideTransition(position: slide, child: child);
                },
                transitionDuration: const Duration(milliseconds: 380),
              ),
            );
          } else {
            nav.pop(true);
          }
        } else {
          if (!ctx.mounted) return;
          QuickAlert.show(
            context: ctx,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Konfirmasi Pembelian',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
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
            // ── RINGKASAN ORDER ──────────────────────────────────────
            _buildSectionHeader('Ringkasan Layanan'),
            const SizedBox(height: 10),
            _buildOrderItemsSummary(dash),
            const SizedBox(height: 20),

            // ── METODE PENGIRIMAN ─────────────────────────────────────
            _buildSectionHeader('Metode Pengiriman'),
            const SizedBox(height: 10),
            _buildDeliveryCard(),
            const SizedBox(height: 20),

            // ── KONTAK PENERIMA ───────────────────────────────────────
            _buildSectionHeader('Kontak Penerima'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Nomor HP/WhatsApp',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Nomor HP aktif harus diisi' : null,
            ),
            const SizedBox(height: 20),

            // ── CATATAN TAMBAHAN ──────────────────────────────────────
            _buildSectionHeader('Catatan Tambahan (Opsional)'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Contoh: Pakaian putih dipisah, jangan pakai parfum...',
              icon: Icons.edit_note_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // ── METODE PEMBAYARAN ─────────────────────────────────────
            _buildSectionHeader('Metode Pembayaran'),
            const SizedBox(height: 10),
            _buildPaymentSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isLoading),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT SECTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPaymentSection() {
    if (_loadingAccounts) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_accountsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 32),
            const SizedBox(height: 8),
            Text(
              'Tidak dapat memuat metode pembayaran',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Menggunakan opsi default',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.orange.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Fallback: hanya tunai
            _buildCashOption(),
          ],
        ),
      );
    }

    final banks = _paymentAccounts.where((a) => a.isBank).toList();
    final ewallets = _paymentAccounts.where((a) => a.isEwallet).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tunai ────────────────────────────────────────────────────
        _buildPaymentGroupLabel('💵  Tunai'),
        const SizedBox(height: 8),
        _buildCashOption(),

        // ── Transfer Bank ────────────────────────────────────────────
        if (banks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPaymentGroupLabel('🏦  Transfer Bank'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: banks.length,
            itemBuilder: (_, i) => _buildAccountCard(banks[i]),
          ),
        ],

        // ── E-Wallet ─────────────────────────────────────────────────
        if (ewallets.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPaymentGroupLabel('📱  Dompet Digital (E-Wallet)'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemCount: ewallets.length,
            itemBuilder: (_, i) => _buildAccountCard(ewallets[i]),
          ),
        ],

        // ── Info rekening yang dipilih ────────────────────────────────
        if (_selectedAccount != null) ...[
          const SizedBox(height: 16),
          _buildAccountInfoBox(_selectedAccount!),
        ],
      ],
    );
  }

  Widget _buildPaymentGroupLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCashOption() {
    final isSelected = _paymentMethod == 'cash';
    return GestureDetector(
      onTap: () => setState(() {
        _paymentMethod = 'cash';
        _selectedAccount = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : AppColors.cardBorder,
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.payments_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash / Tunai',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF059669)
                              : AppColors.textPrimary)),
                  Text('Bayar langsung di kasir saat ambil cucian',
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(PaymentAccountModel acc) {
    final isSelected = _paymentMethod == acc.providerCode;
    final bgColor = Color(acc.brandColorValue);
    final textColor = Color(acc.brandTextColorValue);

    return GestureDetector(
      onTap: () => setState(() {
        _paymentMethod = acc.providerCode;
        _selectedAccount = acc;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? bgColor : AppColors.cardBorder,
            width: isSelected ? 2.0 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? bgColor.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo bar
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10)),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  acc.providerName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: acc.providerCode == 'mandiri' ? 1 : 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Name label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(Icons.check_circle_rounded,
                        color: bgColor, size: 12),
                  if (isSelected) const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      acc.providerName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? bgColor : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoBox(PaymentAccountModel acc) {
    final bgColor = Color(acc.brandColorValue);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: bgColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'Info Rekening Tujuan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: bgColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Bank / Penyedia', acc.providerName),
          _buildInfoRow(
              acc.isBank ? 'Nomor Rekening' : 'Nomor HP / Akun',
              acc.accountNumber),
          _buildInfoRow('Atas Nama', acc.accountName),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Simpan bukti transfer. Upload di halaman detail pesanan setelah selesai.',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
          Text(': ',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DELIVERY CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                      ? AppColors.primaryGreen.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: _isDeliveryEnabled
                      ? AppColors.primaryGreen
                      : Colors.grey,
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
                          ? 'Kurir akan mengambil & mengantar pakaian Anda (+Rp ${_fmt(_deliveryFee)})'
                          : 'Anda mengantar & mengambil pakaian sendiri ke outlet',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isDeliveryEnabled,
                activeThumbColor: AppColors.primaryGreen,
                activeTrackColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                onChanged: (val) =>
                    setState(() => _isDeliveryEnabled = val),
              ),
            ],
          ),
          if (_isDeliveryEnabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Alamat Penjemputan & Pengantaran',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (v) => v!.trim().isEmpty
                  ? 'Alamat lengkap harus diisi untuk antar-jemput'
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal Layanan',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                Text('Rp ${_fmt(widget.totalEstimasi)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Biaya Antar-Jemput',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                Text(
                  _isDeliveryEnabled ? 'Rp ${_fmt(_deliveryFee)}' : 'Gratis',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isDeliveryEnabled
                        ? AppColors.accent
                        : AppColors.primaryGreen,
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
                    Text('Total Tagihan',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    Text('Rp ${_fmt(_totalBill)}',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen)),
                  ],
                ),
                Text('${widget.cartItemCount} Layanan',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Buat Pesanan',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (ctx, idx) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
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
          final qtyLabel = service.unit == 'kg'
              ? '${qty.toStringAsFixed(1)} kg'
              : '${qty.toInt()} pcs';

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(service.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('Rp ${_fmt(price)} x $qtyLabel',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text('Rp ${_fmt(subtotal)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
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
      style: GoogleFonts.poppins(
          fontSize: 12.5, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
            fontSize: 12.5, color: AppColors.textSecondary),
        alignLabelWithHint: true,
        prefixIcon:
            Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.primaryGreen, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 10),
      ),
    );
  }
}
